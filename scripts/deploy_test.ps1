$ErrorActionPreference = 'Stop'
Push-Location (Split-Path -Parent $PSScriptRoot)
try {
    flutter build web --release --no-wasm-dry-run --dart-define=STORE_TEST_MODE=true --output=build/web-test
    if ($LASTEXITCODE -ne 0) { throw 'A compilação do site falhou.' }
    firebase deploy --only hosting:benta-lacos-teste --project benta-lacos
    if ($LASTEXITCODE -ne 0) { throw 'A publicação do site de testes falhou.' }
    Write-Host 'Site de testes: https://benta-lacos-teste.web.app'
} finally {
    Pop-Location
}
