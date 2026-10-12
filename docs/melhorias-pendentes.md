# Melhorias do Benta Laços — preparação para publicação

## Comportamento preparado

- Etapas de produção: Pendente → Aceito → Fabricado → Enviado/Entregue. Retirada passa de Fabricado para Entregue. Pagamento aparece separadamente e não troca a etapa de produção.
- Produto pronto usa estoque; produto sob encomenda usa limite de unidades por pedido e prazo de fabricação em dias corridos. A capacidade cadastrada é um limite por pedido, não uma agenda global de produção.
- Ao aceitar uma encomenda, calcula-se uma previsão a partir do maior prazo dos itens. O administrador pode ajustar previsão e orientações, visíveis ao cliente.
- Cancelamento exige motivo e quem solicitou. Registra responsável; pagamentos confirmados e legados ficam com reembolso a verificar, até confirmação manual.
- Aviso de retirada abre WhatsApp com texto. Somente a confirmação manual registra envio; não se enviam mensagens automaticamente.
- Busca por prefixo de nome/sobrenome ou ID, filtro de status e período e páginas de 20 pedidos consultados no servidor.
- Erros de checkout sem nomes técnicos; diagnóstico preservado no console.

## Segurança preparada

- Cliente não altera preço/estoque ou sua permissão de administrador.
- Servidor confere proprietário, estado inicial, valores e totais. Itens são gravados na mesma transação como registros imutáveis validados pelas regras do Firestore.
- Até nove produtos diferentes por pedido e até 100 unidades por produto, respeitando disponibilidade ou limite da encomenda. Limite de nove mantém a transação dentro dos limites de avaliação e leitura das regras do Firestore.
- Pedido de teste somente no banco de testes; essa marca não permite ignorar estoque na produção.
- Backups das regras atuais são feitos antes de qualquer publicação.

## Separação de testes preparada

O site fixo https://benta-lacos-teste.web.app usará o banco `benta-teste`. A loja usa `(default)`. Imagens novas no ambiente de testes usam o prefixo `teste/` no Storage.

O login Firebase Auth permanece compartilhado. A separação é de dados comerciais e arquivos novos; não é um segundo projeto com contas e senhas independentes. Fotos públicas existentes permanecem referenciadas por URL.

Na preparação remota, serão copiados apenas catálogo/conteúdo público e registros mínimos de permissão administrativa (UID, tipo e nome genérico), sem e-mails, pedidos ou cadastros pessoais de clientes.

Pedidos existentes recebem campos de busca e arquivamento, sem alterar valores ou status. Na ausência de data de pedido, conserva-se uma data existente ou a data de criação do documento. Sete índices são preparados em cada banco para suportar os filtros.

## Publicação pendente

A revisão automática rejeitou a preparação remota por envolver criação do banco, publicação de regras e cópia de registros administrativos sem aprovação específica do destino/payload. Nenhuma dessas alterações foi executada.

Após aprovação: executar `node scripts/review_firebase.cjs --prepare`, conferir a conclusão dos índices, validar um pedido no banco de testes e publicar as versões compiladas de ambos os sites. A publicação da loja deve acompanhar as regras novas porque o checkout agora grava os itens validados na mesma transação.

As validações estão em `artifacts/improvements-rules-tests.json`, `artifacts/improvements-tests.log` e `artifacts/improvements-analyze.log`. A publicação das regras exige o hash exato da versão aprovada nos testes.

## Resultado da validação local

45 testes do aplicativo passaram (improvements-tests-final.log); 25 testes das regras passaram, com hash da fonte registrado. As versões build/web-test e build/web compilaram com sucesso. A análise geral/scoped do Flutter foi interrompida por travamento; não foi marcada como aprovada. Nenhuma alteração remota nem teste de pedido no novo banco foi executado. A publicação e a verificação integrada do banco de testes permanecem pendentes da aprovação específica.


## Limpeza autorizada em 12/10/2026

Estoque verificado em zero nos 6 produtos e 3 depoimentos removidos do banco principal, que atualmente atende aos dois endereços publicados. O backup de recuperação permanece local em artifacts/ e não é enviado ao GitHub. Essa limpeza não publica as regras novas nem cria o banco separado de testes.
