# Benta Laços

Loja de acessórios infantis em Flutter Web, com catálogo no Firestore e conclusão de pedidos por atendimento no WhatsApp.

## Executar

```powershell
flutter pub get
flutter run -d chrome
```

## Verificar

```powershell
flutter test
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter build web --release --no-web-resources-cdn
```

Os testes cobrem preços em reais, busca sem distinção de acentos, números do WhatsApp, regras de estoque e layouts de 320, 375, 768 e 1440 pixels. Não criam pedidos no Firebase real.

## Fluxo de pedidos

O cliente seleciona produtos no carrinho, revisa contato e entrega e registra um pedido pendente. Preços e disponibilidade são relidos em uma transação. O mesmo identificador é reutilizado em tentativas de registro nessa tela; os itens enviados são removidos do carrinho e dos favoritos na mesma transação. A confirmação aparece antes de abrir o WhatsApp ou gerar PDF. Falhas nessas ações permitem tentar novamente sem registrar outro pedido.

Pedidos pendentes não reservam estoque. Para entrega, o cliente informa o CEP e recebe a cotação pelo atendimento. No painel administrativo, use **Informar frete combinado** e depois use **Confirmar pagamento**, selecionando o meio realmente recebido. Registre o envio apenas após a confirmação. A confirmação verifica o estoque e dá baixa atomicamente, uma única vez. Cancelar um pedido do novo fluxo repõe o estoque previamente baixado. Arquivar preserva o status, os valores e o estoque. Pedidos anteriores, sem `estoqueFluxo: confirmacao`, continuam com seu comportamento legado; não foi executada migração de dados.

Pagamento por cartão é uma preferência de atendimento: o site não coleta número, validade nem CVV e não executa cobranças. Não há integração automática de frete ou de pagamento. Os PDFs mostram o status real e distinguem subtotal de total quando o frete ainda não foi informado.

## Catálogo e contatos

O catálogo permite ordenar por destaque, novidades, preço e nome, filtrar por cor e disponibilidade e pesquisar nomes, descrições, categorias e cores. Produtos novos recebem `createdAt`; produtos antigos sem data ficam após os datados na ordenação por novidades.

Telefone e email do rodapé vêm de `institucional/contato`. O telefone cadastrado também é usado ao continuar um pedido no WhatsApp. A fonte Montserrat e sua licença estão em `assets/fonts`.

## Rotas e publicação

- `/colecao`
- `/categoria/La%C3%A7os`
- `/busca?q=laco`
- `/produto/ID_DO_PRODUTO`
- `/carrinho` e `/checkout`

O servidor de hospedagem precisa encaminhar rotas da aplicação a `index.html`, preservando arquivos estáticos. A compilação fica em `build/web`. O comando de compilação não publica o site.

Antes de publicar, valide o fluxo autenticado com uma conta de teste e confira as regras do Firestore: clientes só devem acessar seus próprios pedidos e carrinhos; confirmação de pagamento, preços e estoque devem ser protegidos para administradores. As regras implantadas no Firebase não estão neste projeto e não foram alteradas.

O HTML inclui título, descrição e imagem de compartilhamento. Ao definir o domínio definitivo, transforme os caminhos de `og:image` e `twitter:image` em URLs absolutas e adicione a URL canônica. Pré-visualizações individuais de produtos e indexação avançada precisam de metadados servidos pelo servidor; o HTML atual compartilha a apresentação geral da loja.
## Painel administrativo

A rota `/admin` verifica a sessão e `usuarios/{uid}.tipo == admin` antes de mostrar as telas de gestão. As rotas antigas de edição também passam pela mesma verificação. A navegação tem menu lateral no computador e menu retrátil no celular.

- **Visão geral:** pedidos pendentes, pagamentos aguardando envio, produtos com até cinco unidades, vendas confirmadas do mês e pedidos recentes.
- **Produtos:** busca, filtros, tabela no computador, cartões no celular, paginação, cadastro e edição. Fotos podem ser enviadas do dispositivo para Firebase Storage, organizadas por arraste e definidas como capa. São aceitos JPG, PNG e WebP de até 5 MB cada. Endereços de imagens existentes continuam compatíveis.
- **Estoque:** filtros, ajuste com motivo obrigatório e exportação do inventário da seleção completa. A quantidade é conferida novamente na transação para evitar sobrescrever outro ajuste ou uma venda ocorrida durante a edição.
- **Pedidos:** busca por cliente ou identificador, filtros de data e status, dados de contato, endereço, itens, frete, pagamento recebido, rastreio e histórico. A confirmação de pagamento verifica estoque. Envio exige pagamento; entrega exige envio. O botão de WhatsApp abre o atendimento, sem enviar mensagens automaticamente.
- **Clientes:** consulta dos contatos cadastrados e dos pedidos relacionados ao identificador do cliente.
- **Relatórios:** vendas contam somente pedidos pagos, enviados ou entregues. Unidades somam as quantidades dos itens. O período considera a data de criação do pedido e vale para os cartões, gráficos, listas e PDF. Pedidos sem data são incluídos somente em todo o período. Pedidos pendentes ficam separados. Cartão sem modalidade registrada não é classificado como débito. Taxas são somadas apenas quando registradas no pedido; a estimativa fixa de 4% foi removida.
- **Conteúdo e configurações:** páginas da marca, informações de atendimento, depoimentos e contato comercial. Os formulários mostram falhas e permitem nova tentativa, preservando os campos que não foram editados.

Produtos são arquivados com `isArchived`, saem do catálogo e podem ser restaurados. Pedidos usam `arquivado`, mantendo os dados financeiros e as referências. Pedidos excluídos pelo sistema antigo permanecem identificados como `Excluido`; o status anterior não é inventado. Depoimentos arquivados saem da aprovação e podem voltar como pendentes. Nenhum registro existente foi migrado ou excluído durante a implementação.

As novas operações administrativas registram data, responsável e detalhes em `historico`. Alterações anteriores à atualização não possuem histórico retroativo. Atualizações de produto, conteúdo e contato verificam concorrência antes de sobrescrever campos editados.

Os testes incluem regras de transição dos pedidos, critérios financeiros, filtros de período, preservação de metadados, edição de categoria antiga e PDFs com 160 registros. As imagens `artifacts/admin-layout-375.png` e `artifacts/admin-layout-1440.png` são prévias do layout renderizadas em testes com dados de demonstração, não capturas de uma conta de produção.

Para validar uploads e operações autenticadas, é necessária uma conta administradora de teste. Confira as regras do Firebase Storage para permitir gravação administrativa em `produtos/{id}/...` e leitura das imagens usadas no catálogo. As regras de produção do Firestore e do Storage não estão versionadas neste projeto e não foram modificadas. A verificação visual de acesso e os testes locais não substituem a validação dessas regras no Firebase.
## Prévia publicada para testes

A versão validada foi publicada no canal `revisao-painel` do Firebase Hosting:

- Loja: https://benta-lacos--revisao-painel-0xuqm8gx.web.app
- Login: https://benta-lacos--revisao-painel-0xuqm8gx.web.app/login
- Painel: https://benta-lacos--revisao-painel-0xuqm8gx.web.app/admin

O canal expira em 16/10/2026. A prévia usa o mesmo projeto Firebase da loja: pedidos, produtos e alterações administrativas feitos nela usam os dados desse projeto. O domínio da prévia foi autorizado no Firebase Authentication pelo comando de publicação.

Para atualizar o canal após novas alterações, compile a aplicação e execute:

```powershell
flutter build web --release --no-web-resources-cdn
firebase hosting:channel:deploy revisao-painel --expires 7d --project benta-lacos
```

A configuração `hosting` em `firebase.json` publica somente `build/web`, encaminha as rotas da aplicação para `index.html` e evita cache prolongado dos arquivos de inicialização.
### Refinamento visual do painel

O painel ganhou navegação escura organizada por operação, resultados e marca; barra superior com seção atual, data e acesso à conta; componentes visuais consistentes e uma tela de entrada com acesso direto ao login.

Na visão geral, o gráfico mostra valores confirmados nos últimos 14 dias, preenchendo dias sem vendas com zero. Os indicadores e etapas do fluxo abrem os pedidos com o status correspondente. Pedidos arquivados ou excluídos pelo fluxo antigo ficam fora da fila operacional; o critério financeiro dos relatórios permanece o mesmo.

Pedidos e clientes usam tabelas no computador e cartões no celular. O catálogo destaca produtos em destaque, esgotados e arquivados. O estoque mostra unidades disponíveis, itens esgotados, alertas de reposição e valor a preço de venda, sempre separado de lucro. Enquanto os dados estão indisponíveis, os indicadores mostram um traço em vez de números inventados.

As prévias visuais em `artifacts/admin-layout-375.png` e `artifacts/admin-layout-1440.png` foram atualizadas e usam somente registros de demonstração nos testes. Não há uma rota de demonstração que contorne a autenticação da aplicação.
## Endereço fixo de testes

Loja: https://benta-lacos.web.app
Testes: https://benta-lacos-teste.web.app

O ambiente de testes usa coleções `teste_*` no banco existente do Firebase, com autenticação compartilhada e dados comerciais separados. Essa solução funciona no plano atual, sem criar outro banco nem ativar faturamento. Imagens novas de testes usam o prefixo `teste/` no Storage.

Pedidos de testes não movimentam estoque nem entram nos totais financeiros. As regras impedem usar a marca de teste para ignorar estoque na loja. Os administradores recebem registros mínimos de permissão nas coleções de testes; cadastros pessoais e pedidos reais não são copiados.

Para publicar testes, execute `./scripts/deploy_test.ps1`. O site principal usa `build/web` e os testes usam `build/web-test` com `STORE_TEST_MODE=true`.

Produção segue Pendente → Aceito → Fabricado → Enviado/Entregue. Retirada passa de Fabricado para Entregue. Pagamento é confirmado separadamente. Os detalhes permitem registrar motivo e solicitante de cancelamento, reembolso, previsão e instruções. O aviso de retirada abre WhatsApp com a mensagem pronta; o envio é confirmado manualmente.

Validação final: 45 testes do app, 32 testes das regras, pedido autenticado nas coleções de testes e proteção de preço/permissão verificados. As duas versões e as regras foram publicadas em 12/10/2026.
