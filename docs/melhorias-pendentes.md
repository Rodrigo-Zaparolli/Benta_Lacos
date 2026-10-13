# Melhorias do Benta Laços — publicadas

## Comportamento publicado

- Etapas de produção: Pendente → Aceito → Fabricado → Enviado/Entregue. Retirada passa de Fabricado para Entregue. Pagamento aparece separadamente e não troca a etapa de produção.
- Produto pronto usa estoque; produto sob encomenda usa limite de unidades por pedido e prazo de fabricação em dias corridos. A capacidade cadastrada é um limite por pedido, não uma agenda global de produção.
- Ao aceitar uma encomenda, calcula-se uma previsão a partir do maior prazo dos itens. O administrador pode ajustar previsão e orientações, visíveis ao cliente.
- Cancelamento exige motivo e quem solicitou. Registra responsável; pagamentos confirmados e legados ficam com reembolso a verificar, até confirmação manual.
- Aviso de retirada abre WhatsApp com texto. Somente a confirmação manual registra envio; não se enviam mensagens automaticamente.
- Busca por prefixo de nome/sobrenome ou ID, filtro de status e período e páginas de 20 pedidos consultados no servidor.
- Erros de checkout sem nomes técnicos; diagnóstico preservado no console.

## Segurança publicada

- Cliente não altera preço/estoque ou sua permissão de administrador.
- Servidor confere proprietário, estado inicial, valores e totais. Itens são gravados na mesma transação como registros imutáveis validados pelas regras do Firestore.
- Até nove produtos diferentes por pedido e até 100 unidades por produto, respeitando disponibilidade ou limite da encomenda. Limite de nove mantém a transação dentro dos limites de avaliação e leitura das regras do Firestore.
- Pedido de teste somente no banco de testes; essa marca não permite ignorar estoque na produção.
- Backups das regras atuais são feitos antes de qualquer publicação.

## Publicação concluída em 12/10/2026

A exigência de faturamento para outro banco foi resolvida com coleções teste_* no banco atual. Login compartilhado, dados comerciais separados e imagens novas com prefixo teste/. Regras e índices estão ativos e ambos os sites foram publicados.

Validação: 45 testes do app, 32 testes de segurança e pedido autenticado registrado. Cliente consultou Pendente, Aceito e Fabricado; elevação de permissão e alteração de preço foram bloqueadas. Estoque real permaneceu igual. Conta e registros temporários foram removidos.

Estoque dos 6 produtos da loja zerado e 3 depoimentos removidos conforme autorização. Backups permanecem locais em artifacts/.
