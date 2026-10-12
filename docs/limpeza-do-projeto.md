# Limpeza do projeto

Removidos 33 arquivos Dart sem caminho de importação a partir de `lib/main.dart` ou dos testes, considerando imports, exports e partes de bibliotecas.

Os arquivos pertenciam a telas antigas de pagamento, perfil e dashboard, modelos/repositórios sem consumidores, relatórios substituídos e seus widgets/dados simulados, cabeçalhos antigos e seções não utilizadas. O histórico Git conserva o código anterior.

Também foi removido o `package.json` de exemplo: o teste sempre retornava erro e o ponto de entrada `index.js` não existia. Os scripts de manutenção `.cjs` continuam independentes; o aplicativo usa o gerenciamento de dependências do Flutter.

Dependências diretas removidas: `flutter_slidable`, `flutter_card_swiper`, `confetti`, `qr_flutter` e `mask_text_input_formatter`. Nenhuma era importada pelo código ativo.

O analisador exclui a cópia local `Benta_Lacos/`, os diagnósticos em `artifacts/` e os resultados de compilação em `build/`, evitando tratar cópias e arquivos gerados como código do aplicativo principal.

As plataformas Flutter, imagens e backups locais foram mantidos. Recursos declarados no pubspec e referências dinâmicas de imagens exigem revisão específica antes de exclusão.

## Validação

Após a limpeza, os 45 testes passaram e a versão web compilou. A análise estática concluiu sem erros, com 7 advertências e avisos de estilo ainda existentes. Nenhum arquivo Dart remanescente ficou desconectado da entrada do aplicativo e dos testes na revisão de imports.
