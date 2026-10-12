// Explicit maintenance: zero product quantities and delete testimonials only.
// Backups stay in the ignored artifacts directory. Does not create databases.
const fs = require('fs');
const path = require('path');
const base = path.join(process.env.APPDATA, 'npm/node_modules/firebase-tools/lib');
const {configstore} = require(path.join(base, 'configstore'));
const {getAccessToken} = require(path.join(base, 'auth'));
async function main() {
 const stored = configstore.get('tokens');
 const token = await getAccessToken(stored.refresh_token, stored.scopes);
 const headers = {Authorization:`Bearer ${token.access_token}`,'Content-Type':'application/json'};
 async function call(url, options={}) { const response = await fetch(url,{headers,...options}); const data = await response.json(); if (!response.ok) throw Error(`${response.status}: ${data.error?.message || 'Firebase request failed'}`); return data; }
 const root = 'https://firestore.googleapis.com/v1/projects/benta-lacos/databases';
 const databases = (await call(root)).databases.filter(d=>['(default)','benta-teste'].includes(d.name.split('/').pop()));
 const snapshot = [];
 for (const database of databases) {
  const collections = {};
  for (const collection of ['produtos','depoimentos']) {
   const docs = []; let page;
   do { const result = await call('https://firestore.googleapis.com/v1/'+database.name+'/documents/'+collection+'?pageSize=100'+(page?'&pageToken='+encodeURIComponent(page):'')); docs.push(...(result.documents || [])); page=result.nextPageToken; } while(page);
   collections[collection] = docs;
  }
  snapshot.push({database:database.name,...collections});
 }
 fs.mkdirSync('artifacts',{recursive:true});
 const stamp = new Date().toISOString().replace(/[:.]/g,'-');
 const backup = `artifacts/before-stock-testimonials-reset-${stamp}.json`;
 fs.writeFileSync(backup,JSON.stringify(snapshot,null,2));
 const summary = snapshot.map(s=>({database:s.database.split('/').pop(),products:s.produtos.length,stockChanges:s.produtos.filter(d=>d.fields.quantity?.integerValue!=='0').length,testimonials:s.depoimentos.length}));
 console.log(JSON.stringify({backup,plan:summary}));
 if (!process.argv.includes('--apply')) return;
 for (const data of snapshot) {
  const prefix = data.database+'/documents/';
  const writes = [];
  for (const doc of data.produtos) {
   if (!doc.name.startsWith(prefix+'produtos/')) throw Error('Unexpected product path');
   if (doc.fields.quantity?.integerValue==='0') continue;
   writes.push({update:{name:doc.name,fields:{quantity:{integerValue:'0'}}},updateMask:{fieldPaths:['quantity']},currentDocument:{updateTime:doc.updateTime},updateTransforms:[{fieldPath:'updatedAt',setToServerValue:'REQUEST_TIME'},{fieldPath:'historico',appendMissingElements:{values:[{mapValue:{fields:{acao:{stringValue:'Estoque zerado por manutenção autorizada'},autor:{stringValue:'Manutenção da loja'},data:{timestampValue:new Date().toISOString()},detalhes:{mapValue:{fields:{quantidadeAnterior:doc.fields.quantity || {integerValue:'0'},quantidadeFinal:{integerValue:'0'}}}}}}}]}}]});
  }
  for (const doc of data.depoimentos) { if (!doc.name.startsWith(prefix+'depoimentos/')) throw Error('Unexpected testimonial path'); writes.push({delete:doc.name,currentDocument:{updateTime:doc.updateTime}}); }
  for (let i=0;i<writes.length;i+=400) await call('https://firestore.googleapis.com/v1/'+data.database+'/documents:commit',{method:'POST',body:JSON.stringify({writes:writes.slice(i,i+400)})});
  // Verify every product and ensure no testimonial remains.
  for (const doc of data.produtos) { const current = await call('https://firestore.googleapis.com/v1/'+doc.name); if (current.fields.quantity?.integerValue!=='0') throw Error('Stock reset verification failed'); }
  const remaining = await call('https://firestore.googleapis.com/v1/'+data.database+'/documents/depoimentos?pageSize=1');
  if (remaining.documents?.length) throw Error('Testimonial cleanup verification failed');
 }
 fs.writeFileSync(`artifacts/stock-testimonials-reset-result-${stamp}.json`,JSON.stringify({verified:true,backup,summary},null,2));
 console.log(JSON.stringify({verified:true,summary}));
}
main().catch(e=>{console.error(e.message);process.exitCode=1;});
