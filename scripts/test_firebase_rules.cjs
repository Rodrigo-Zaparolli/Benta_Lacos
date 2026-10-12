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
 const stamp = '2026-10-12T12:00:00Z';
 const order = {pedidoId:'x',clienteId:'customer',nomeCliente:'Maria',cliente:{nome:'Maria',telefone:'54999999999'},enderecoExibicao:'',total:10,subtotal:10,valorFrete:0,freteACombinar:false,itens:[{id:'p',nome:'Laço',preco:10,quantidade:1,sobEncomenda:false,prazoDias:0}],metodoPagamento:'Pix',metodoEnvio:'Retirar na loja',status:'Pendente',canal:'WhatsApp',estoqueFluxo:'confirmacao',estoqueBaixado:false,fluxoPedido:'fabricacao',dataPedido:stamp,arquivado:false,produtoIds:['p'],buscaTokens:['maria']};
 for (const [name, patch, expected] of [['valid pickup order',{},'ALLOW'],['valid delivery order',{metodoEnvio:'Entrega a combinar',freteACombinar:true,valorFrete:null},'ALLOW'],['tampered price',{itens:[{...order.itens[0],preco:1}],total:1,subtotal:1},'DENY'],['tampered total',{total:1},'DENY'],['fake paid order',{status:'Pago'},'DENY'],['test bypass on production',{pedidoTeste:true},'DENY'], ['duplicate products', {itens:[order.itens[0],order.itens[0]],produtoIds:['p','p'],subtotal:20,total:20},'DENY'], ['nine valid lines',{itens:Array.from({length:9},(_,i)=>({...order.itens[0],id:'p'+i})),produtoIds:Array.from({length:9},(_,i)=>'p'+i),subtotal:90,total:90},'ALLOW']]) {
   add(name,'pedidos/x','create',null,{...order,...patch},expected);
   const c = cases[cases.length-1]; c.request.time = stamp;
   c.functionMocks[0].result.value.data = {tipo:'cliente',name:'Laço',price:10,quantity:5};
   for (const row of c.request.resource.data.itens) c.functionMocks.push({function:'getAfter',args:[{exactValue:`/databases/%28default%29/documents/pedidos/x/itens/${row.id}`}],result:{value:{data:{clienteId:'customer',item:order.itens[0].id===row.id?order.itens[0]:{...order.itens[0],id:row.id}}}}});
 }
 for (const [name, item, expected] of [['valid line',order.itens[0],'ALLOW'],['line with changed price',{...order.itens[0],preco:1},'DENY'],['line beyond stock',{...order.itens[0],quantidade:8},'DENY'],['line with negative quantity',{...order.itens[0],quantidade:-1},'DENY']]) {
   add(name,'pedidos/x/itens/p','create',null,{clienteId:'customer',item},expected);
   cases[cases.length-1].functionMocks[0].result.value.data={tipo:'cliente',name:'Laço',price:10,quantity:5};
 }
 const suite = await call(rulesBase+':test',{method:'POST',body:JSON.stringify({source,testSuite:{testCases:cases.map(({name,...c})=>c)}})});
 suite.sourceHash = require('crypto').createHash('sha256').update(source.files[0].content).digest('hex');
 fs.writeFileSync('artifacts/improvements-rules-tests.json',JSON.stringify(suite,null,2));
 console.log(JSON.stringify({issues:suite.issues,tests:suite.testResults?.map((r,i)=>({name:cases[i].name,state:r.state}))}));
 if (suite.issues?.some(i=>i.severity==='ERROR') || suite.testResults?.length!==cases.length || suite.testResults.some(r=>r.state!=='SUCCESS')) throw Error('Rules validation failed');

}
main().catch(e=>{console.error(e.message);process.exitCode=1;});
