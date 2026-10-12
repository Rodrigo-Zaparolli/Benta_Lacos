// Uses the locally signed-in Firebase CLI account; never prints credentials.
const fs = require('fs');
fs.mkdirSync('artifacts', {recursive:true});
const base = require('path').join(process.env.APPDATA, 'npm/node_modules/firebase-tools/lib/') + require('path').sep;
const {configstore} = require(base + 'configstore');
const {getAccessToken} = require(base + 'auth');
async function main() {
 const stored = configstore.get('tokens');
 const token = await getAccessToken(stored.refresh_token, stored.scopes);
 const headers = {Authorization: `Bearer ${token.access_token}`, 'Content-Type':'application/json'};
 async function call(url, options={}) {
  const r = await fetch(url, {headers, ...options}); const data = await r.json();
  if (!r.ok) throw Error(`${r.status}: ${data.error?.message || 'Firebase request failed'}`);
  return data;
 }
 const rulesBase = 'https://firebaserules.googleapis.com/v1/projects/benta-lacos';
 const source = {files:[{name:'firestore.rules',content:fs.readFileSync('firestore.rules','utf8')}]};
 const cases = [];
 const add = (name, collection, method, existing, proposed, expected, uid='customer') => {
  cases.push({name, expectation:expected, request:{path:`/databases/(default)/documents/${collection}`,method,auth:uid ? {uid,token:{}}:null,...(proposed ? {resource:{data:proposed}}:{})}, ...(existing ? {resource:{data:existing}}:{}), functionMocks:[{function:'get',args:[{anyValue:{}}],result:{value:{data:{tipo:uid==='admin'?'admin':'cliente'}}}},{function:'exists',args:[{anyValue:{}}],result:{value:!!existing}}]});
 };
 add('customer cannot edit price','produtos/p','update',{price:10,views:0},{price:1,views:0},'DENY');
 add('customer can count view','produtos/p','update',{price:10,views:0},{price:10,views:1},'ALLOW');
 add('admin can edit product','produtos/p','update',{price:10},{price:12},'ALLOW','admin');
 add('customer cannot become admin','usuarios/customer','update',{tipo:'cliente',nome:'A'},{tipo:'admin',nome:'A'},'DENY');
 add('customer can update name','usuarios/customer','update',{tipo:'cliente',nome:'A'},{tipo:'cliente',nome:'B'},'ALLOW');
 add('cannot create own admin role','usuarios/customer','create',null,{tipo:'admin'},'DENY');
 add('can create own customer profile','usuarios/customer','create',null,{tipo:'cliente'},'ALLOW');
 add('cannot create another customer','usuarios/other','create',null,{tipo:'cliente'},'DENY');
 add('cannot read another order','pedidos/x','get',{clienteId:'other'},null,'DENY');
 add('can read own order','pedidos/x','get',{clienteId:'customer'},null,'ALLOW');
 add('cannot change order','pedidos/x','update',{clienteId:'customer',status:'Pendente'},{clienteId:'customer',status:'Pago'},'DENY');
 add('anonymous cannot create order','pedidos/x','create',null,{clienteId:'customer'},'DENY',null);
 add('spoofed owner cannot create order','pedidos/x','create',null,{clienteId:'other'},'DENY');
 const suite = await call(rulesBase+':test',{method:'POST',body:JSON.stringify({source,testSuite:{testCases:cases.map(({name,...c})=>c)}})});
 fs.writeFileSync('artifacts/improvements-rules-preflight.json',JSON.stringify(suite,null,2));
 console.log(JSON.stringify({issues:suite.issues,tests:suite.testResults?.map((r,i)=>({name:cases[i].name,state:r.state}))}));
 if (suite.issues?.some(i=>i.severity==='ERROR') || suite.testResults?.length!==cases.length || suite.testResults.some(r=>r.state!=='SUCCESS')) throw Error('Rules validation failed');
 const dbBase = 'https://firestore.googleapis.com/v1/projects/benta-lacos/databases';
 const dbs = await call(dbBase);
 console.log(JSON.stringify({databases:dbs.databases?.map(d=>({name:d.name,location:d.locationId}))}));
 if (!process.argv.includes('--prepare')) return;
 const validated = JSON.parse(fs.readFileSync('artifacts/improvements-rules-tests.json','utf8'));
 if (validated.sourceHash !== require('crypto').createHash('sha256').update(source.files[0].content).digest('hex') || validated.testResults?.length < 25 || validated.testResults.some(t=>t.state!=='SUCCESS')) throw Error('Current rules must pass all regression tests before publication');
 const original = dbs.databases.find(d=>d.name.endsWith('/(default)'));
 if (!dbs.databases.some(d=>d.name.endsWith('/benta-teste'))) {
  let created = await call(dbBase+'?databaseId=benta-teste',{method:'POST',body:JSON.stringify({locationId:original.locationId,type:'FIRESTORE_NATIVE',concurrencyMode:'PESSIMISTIC',deleteProtectionState:'DELETE_PROTECTION_ENABLED'})});
  for (let i=0;!created.done && i<30;i++) { await new Promise(r=>setTimeout(r,1500)); created = await call('https://firestore.googleapis.com/v1/'+created.name); }
  if (!created.done || created.error) throw Error('Database creation did not finish successfully');
 }
 for (const database of ['(default)','benta-teste']) {
  const releaseName = 'projects/benta-lacos/releases/cloud.firestore'+(database==='(default)'?'':'/benta-teste');
  let prior; try { prior = await call('https://firebaserules.googleapis.com/v1/'+releaseName); } catch(e) { if (!e.message.startsWith('404')) throw e; }
  if (prior) { const priorSource = await call('https://firebaserules.googleapis.com/v1/'+prior.rulesetName); fs.writeFileSync(`artifacts/rules-before-improvements-${database==="(default)"?'production':'test'}.json`,JSON.stringify({release:prior,ruleset:priorSource},null,2)); }
  const ruleset = await call(rulesBase+'/rulesets',{method:'POST',body:JSON.stringify({source})});
  await call(prior ? 'https://firebaserules.googleapis.com/v1/'+releaseName : rulesBase+'/releases',{method:prior?'PATCH':'POST',body:JSON.stringify(prior ? {release:{name:releaseName,rulesetName:ruleset.name},updateMask:'rulesetName'} : {name:releaseName,rulesetName:ruleset.name})});
  const verify = await call('https://firebaserules.googleapis.com/v1/'+releaseName);
  if (verify.rulesetName!==ruleset.name) throw Error('Rules release verification failed');
  console.log(`Verified rules for ${database}`);
 }
 // Copy only public content and minimal administrator roles. No real orders/customer data.
 const sourceRoot = dbBase+'/(default)/documents/';
 const testRoot = dbBase+'/benta-teste/documents/';
 for (const collection of ['produtos','institucional','configuracoes','depoimentos','usuarios']) {
  let pageToken;
  do {
   const result = await call(sourceRoot+collection+'?pageSize=100'+(pageToken?'&pageToken='+encodeURIComponent(pageToken):''));
   for (const doc of result.documents || []) {
    let fields = doc.fields;
    if (collection==='usuarios') { if (fields.tipo?.stringValue!=='admin') continue; fields = {tipo:{stringValue:'admin'},nome:{stringValue:'Administrador de testes'}}; }
    const target = testRoot+collection+'/'+doc.name.split('/').pop();
    const response = await fetch(target,{headers});
    if (response.status===404) await call(target,{method:'PATCH',body:JSON.stringify({fields})});
    else if (!response.ok) throw Error('Failed to check seed document');
   }
   pageToken = result.nextPageToken;
  } while(pageToken);
 }
 console.log('Isolated test database ready; public content and administrator roles seeded.');
 const indexes = JSON.parse(fs.readFileSync('firestore.indexes.json','utf8').replace(/^\uFEFF/, '')).indexes;
 for (const database of ['(default)','benta-teste']) {
  for (const index of indexes) {
   try { await call(dbBase+'/'+database+'/collectionGroups/pedidos/indexes',{method:'POST',body:JSON.stringify({queryScope:index.queryScope,fields:index.fields})}); }
   catch(e) { if (!e.message.startsWith('409')) throw e; }
  }
  let pageToken;
  let migrated = 0;
  do {
   const result = await call(dbBase+'/'+database+'/documents/pedidos?pageSize=100'+(pageToken?'&pageToken='+encodeURIComponent(pageToken):''));
   for (const doc of result.documents || []) {
    const id = doc.name.split('/').pop();
    const normalize = s => s.toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g,'').trim();
    const name = doc.fields.nomeCliente?.stringValue || doc.fields.cliente?.mapValue?.fields?.nome?.stringValue || '';
    const values = new Set([normalize(id), normalize(name), ...normalize(name).split(' ')]);
    const tokens = new Set();
    for (const v of values) for (let i=1;i<=v.length && i<=100;i++) tokens.add(v.slice(0,i));
    const fields = {arquivado:{booleanValue:doc.fields.arquivado?.booleanValue===true || doc.fields.status?.stringValue==='Excluido'},buscaTokens:{arrayValue:{values:[...tokens].map(stringValue=>({stringValue}))}}};
    const masks=['arquivado','buscaTokens'];
    if (!doc.fields.dataPedido) { const priorDate = doc.fields.data || doc.fields.dataHora; fields.dataPedido=priorDate?.timestampValue ? priorDate : {timestampValue:doc.createTime}; masks.push('dataPedido'); }
    await call('https://firestore.googleapis.com/v1/'+doc.name+'?'+masks.map(m=>'updateMask.fieldPaths='+m).join('&'),{method:'PATCH',body:JSON.stringify({fields})});
    migrated++;
   }
   pageToken=result.nextPageToken;
  } while(pageToken);
  console.log(`Search/archive migration complete in ${database}: ${migrated} orders. Index readiness must be checked before release.`);
 }
}
main().catch(e=>{console.error(e.message);process.exitCode=1;});
