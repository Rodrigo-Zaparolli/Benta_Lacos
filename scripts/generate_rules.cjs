const fs = require('fs');
const rows = Array.from({length: 9}, (_, i) => `(d.itens.size() <= ${i} || line(${i}))`).join(' &&\n');
const sum = Array.from({length: 9}, (_, i) => `amount(${i})`).join(' + ');
fs.writeFileSync('firestore.rules', `rules_version = '2';
service cloud.firestore {
 match /databases/{database}/documents {
  function signed() { return request.auth != null; }
  function admin() { return signed() && get(/databases/$(database)/documents/usuarios/$(request.auth.uid)).data.tipo == 'admin'; }
  function self(uid) { return signed() && request.auth.uid == uid; }
  function line(i) {
   let row = request.resource.data.itens[i];
   let saved = getAfter(/databases/$(database)/documents/pedidos/$(request.resource.data.pedidoId)/itens/$(row.id)).data;
   return row.id == request.resource.data.produtoIds[i] && saved.clienteId == request.auth.uid && saved.item == row;
  }
  function validItem(id) {
   let row = request.resource.data.item;
   let p = get(/databases/$(database)/documents/produtos/$(id)).data;
   return signed() && request.resource.data.clienteId == request.auth.uid && request.resource.data.keys().hasOnly(['clienteId','item']) &&
    row.keys().hasOnly(['id','nome','preco','quantidade','imageUrl','categoria','sobEncomenda','prazoDias']) &&
    row.id == id && row.quantidade is int && row.quantidade > 0 && row.quantidade <= 100 &&
    p.get('isArchived', false) == false && row.preco == p.price && row.nome == p.name &&
    row.sobEncomenda == p.get('madeToOrder', false) &&
    row.prazoDias == (row.sobEncomenda ? p.get('productionDays', 7) : 0) &&
    (database == 'benta-teste' || row.quantidade <= (row.sobEncomenda ? p.get('orderCapacity', 10) : p.get('quantity', 0)));
  }
  function amount(i) { let rows = request.resource.data.itens; return rows.size() > i ? rows[i].preco * rows[i].quantidade : 0; }
  function validOrder(id) {
   let d = request.resource.data;
   return signed() && d.clienteId == request.auth.uid && d.pedidoId == id &&
    d.status == 'Pendente' && d.estoqueBaixado == false && d.estoqueFluxo == 'confirmacao' &&
    d.fluxoPedido == 'fabricacao' && d.get('pedidoTeste', false) == (database == 'benta-teste') &&
    d.dataPedido == request.time && d.cliente is map && d.cliente.nome is string && d.cliente.telefone is string &&
    d.itens is list && d.itens.size() > 0 && d.itens.size() <= 9 &&
    d.produtoIds is list && d.produtoIds.size() == d.itens.size() && d.produtoIds.toSet().size() == d.itens.size() &&
    d.arquivado == false && d.buscaTokens is list && d.buscaTokens.size() <= 1000 &&
    d.keys().hasOnly(['pedidoId','clienteId','nomeCliente','cliente','enderecoExibicao','total','subtotal','valorFrete','freteACombinar','itens','metodoPagamento','metodoEnvio','status','canal','estoqueFluxo','estoqueBaixado','fluxoPedido','pedidoTeste','dataPedido','arquivado','produtoIds','buscaTokens']) &&
    d.metodoEnvio in ['Retirar na loja','Entrega a combinar'] &&
    d.metodoPagamento in ['Pix','Cartão — consultar atendimento'] &&
    d.freteACombinar == (d.metodoEnvio != 'Retirar na loja') &&
    ((d.metodoEnvio == 'Retirar na loja' && d.valorFrete == 0) || (d.metodoEnvio != 'Retirar na loja' && d.valorFrete == null)) &&
    d.subtotal == (${sum}) && d.total == d.subtotal && ${rows};
  }
  match /produtos/{id} {
   allow read: if true;
   allow create, delete: if admin();
   allow update: if admin() || (signed() && request.resource.data.diff(resource.data).affectedKeys().hasOnly(['views']) && request.resource.data.views == resource.data.get('views',0) + 1);
  }
  match /usuarios/{uid} {
   allow read: if self(uid) || admin();
   allow create: if admin() || (self(uid) && request.resource.data.tipo == 'cliente');
   allow update: if admin() || (self(uid) && !request.resource.data.diff(resource.data).affectedKeys().hasAny(['tipo']));
   allow delete: if admin();
   match /{subcollection}/{doc}/{sub=**} { allow read, write: if self(uid) || admin(); }
  }
  match /pedidos/{id} {
   allow get: if signed() && (!exists(/databases/$(database)/documents/pedidos/$(id)) || admin() || resource.data.clienteId == request.auth.uid);
   allow list: if signed() && (admin() || resource.data.clienteId == request.auth.uid);
   allow create: if validOrder(id);
   allow update, delete: if admin();
   match /itens/{productId} {
    allow read: if signed() && (resource.data.clienteId == request.auth.uid || admin());
    allow create: if validItem(productId);
    allow update, delete: if admin();
   }
  }
  match /configuracoes/{id} { allow read: if true; allow write: if admin(); }
  match /institucional/{id} { allow read: if true; allow write: if admin(); }
  match /depoimentos/{id} { allow read: if true; allow create: if signed() && request.resource.data.keys().size() <= 12; allow update, delete: if admin(); }
  match /clientes/{id} { allow read, write: if admin(); }
  match /acessos/{id} { allow read: if admin(); allow create: if request.resource.data.keys().size() <= 10; }
 }
}
`);
