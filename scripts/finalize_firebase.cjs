const fs=require('fs'),path=require('path'),crypto=require('crypto');
const cli=path.join(process.env.APPDATA,'npm/node_modules/firebase-tools/lib');
const {configstore}=require(path.join(cli,'configstore'));
const {getAccessToken}=require(path.join(cli,'auth'));
async function main(){
 fs.mkdirSync('artifacts',{recursive:true});
 const stored=configstore.get('tokens'),token=await getAccessToken(stored.refresh_token,stored.scopes);
 const headers={Authorization:`Bearer ${token.access_token}`,'Content-Type':'application/json'};
 async function call(url,options={}){const r=await fetch(url,{headers,...options}),d=await r.json();if(!r.ok)throw Error(`${r.status}: ${d.error?.message}`);return d;}
 const db='https://firestore.googleapis.com/v1/projects/benta-lacos/databases/(default)';
 async function documents(collection){let page,docs=[];do{const r=await call(db+'/documents/'+collection+'?pageSize=100'+(page?'&pageToken='+encodeURIComponent(page):''));docs.push(...(r.documents||[]));page=r.nextPageToken;}while(page);return docs;}
 if(process.argv.includes('--prepare')){
  for(const collection of ['produtos','institucional','configuracoes','depoimentos','usuarios']){
   for(const doc of await documents(collection)){
    let fields=structuredClone(doc.fields);
    if(collection==='usuarios'){if(fields.tipo?.stringValue!=='admin')continue;fields={tipo:{stringValue:'admin'},nome:{stringValue:'Administrador de testes'}};}
    delete fields.historico;
    const url=db+'/documents/teste_'+collection+'/'+doc.name.split('/').pop();
    const r=await fetch(url,{headers});if(r.status===404)await call(url,{method:'PATCH',body:JSON.stringify({fields})});else if(!r.ok)throw Error('Failed to inspect seed document');
   }
  }
  console.log('Public content and minimal admin roles seeded in isolated test collections.');
  for(const collection of ['pedidos','teste_pedidos']){
   for(const doc of await documents(collection)){
    doc.fields ||= {};
    const id=doc.name.split('/').pop(),normalize=s=>s.toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g,'').trim();
    const name=doc.fields.nomeCliente?.stringValue||doc.fields.cliente?.mapValue?.fields?.nome?.stringValue||'',tokens=new Set();
    for(const s of new Set([normalize(id),normalize(name),...normalize(name).split(' ')]))for(let i=1;i<=s.length&&i<=100;i++)tokens.add(s.slice(0,i));
    const fields={arquivado:{booleanValue:doc.fields.arquivado?.booleanValue===true||doc.fields.status?.stringValue==='Excluido'},buscaTokens:{arrayValue:{values:[...tokens].map(stringValue=>({stringValue}))}}},masks=['arquivado','buscaTokens'];
    if(!doc.fields.dataPedido){fields.dataPedido=doc.fields.data?.timestampValue?doc.fields.data:{timestampValue:doc.createTime};masks.push('dataPedido');}
    await call('https://firestore.googleapis.com/v1/'+doc.name+'?'+masks.map(s=>'updateMask.fieldPaths='+s).join('&'),{method:'PATCH',body:JSON.stringify({fields}),});
   }
  }
  const indexes=JSON.parse(fs.readFileSync('firestore.indexes.json','utf8')).indexes;
  for(const index of indexes){try{await call(db+'/collectionGroups/'+index.collectionGroup+'/indexes',{method:'POST',body:JSON.stringify({queryScope:index.queryScope,fields:index.fields})});}catch(e){if(!e.message.startsWith('409'))throw e;}}
  console.log('Search fields migrated and indexes requested.');
 }
 for(const collection of ['pedidos','teste_pedidos']){const r=await call(db+'/collectionGroups/'+collection+'/indexes');const indexes=(r.indexes||[]).filter(i=>i.name.includes('/collectionGroups/'+collection+'/'));console.log(JSON.stringify({collection,indexes:indexes.map(i=>({state:i.state,fields:i.fields.map(f=>f.fieldPath)}))}));if(process.argv.includes('--verify')&&indexes.some(i=>i.state!=='READY'))throw Error('Indexes are not ready yet');}
 if(process.argv.includes('--publish-rules')){
  const content=fs.readFileSync('firestore.rules','utf8'),validation=JSON.parse(fs.readFileSync('artifacts/improvements-rules-tests.json','utf8'));
  if(validation.sourceHash!==crypto.createHash('sha256').update(content).digest('hex')||validation.testResults?.length<32||validation.testResults.some(r=>r.state!=='SUCCESS'))throw Error('Current rules must pass all security tests');
  const base='https://firebaserules.googleapis.com/v1/projects/benta-lacos',release=base+'/releases/cloud.firestore';
  const prior=await call(release),oldSource=await call('https://firebaserules.googleapis.com/v1/'+prior.rulesetName);
  fs.writeFileSync('artifacts/rules-before-final-publication.json',JSON.stringify({release:prior,ruleset:oldSource},null,2));
  const ruleset=await call(base+'/rulesets',{method:'POST',body:JSON.stringify({source:{files:[{name:'firestore.rules',content}]}})});
  await call(release,{method:'PATCH',body:JSON.stringify({release:{name:'projects/benta-lacos/releases/cloud.firestore',rulesetName:ruleset.name},updateMask:'rulesetName'})});
  if((await call(release)).rulesetName!==ruleset.name)throw Error('Rules release verification failed');
  console.log('Security rules published and active release verified.');
 }
}
main().catch(e=>{console.error(e.message);process.exitCode=1;});
