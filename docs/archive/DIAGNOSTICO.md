# Diagnóstico e Teste - Problema de Georreferenciação

## Instruções

Execute o script de diagnóstico completo para identificar o problema real:

```powershell
# 1. Abra PowerShell com direitos de Administrador
# 2. Execute:
cd C:\Users\jakso\OneDrive\ -\ Electra\projetos\win11-dark-mode
powershell -NoProfile -ExecutionPolicy Bypass -File diagnostic.ps1
```

## O que fazer com os resultados

Depois de executar `diagnostic.ps1`, observe:

### Se o TESTE 4 mostrar "✓ COORDENADAS OBTIDAS COM SUCESSO!"
- **Status**: Georreferenciação FUNCIONA ✓
- **Próximo Passo**: A correção foi bem-sucedida, teste a instalação completa

### Se TESTE 4 retornar "TryStart retornou false" em TODOS os timeouts
- **Problema**: Serviço de localização desabilitado ou sem permissão
- **Solução**:
  1. Vá para **Configurações > Privacidade e Segurança > Localização**
  2. Ative "Localização" (switch no topo)
  3. Certifique-se de que "Serviços de localização" estão ON
  4. Reexecute o diagnóstico

### Se TESTE 4 mostrar "IsUnknown: True"
- **Problema**: Localização está habilitada mas sem dados
- **Causa Possível**: Windows precisa de tempo para primeiro acesso, ou não há sensores
- **Solução**:
  1. Aguarde 1-2 minutos com as Configurações de Localização abertas
  2. Windows pode precisar fazer triangulação WiFi inicial
  3. Reexecute o diagnóstico

### Se TESTE 1 mostrar "❌ Serviço 'lfsvc' não foi encontrado"
- **Problema**: Sistema não foi reconhecido
- **Situação Alternativa**: Pode ser um problema de permissões ou versão Windows

## Testes Adicionais

Se o diagnóstico completo não resolver, execute testes individuais:

### Teste 1: Verificar Status do Serviço
```powershell
Get-Service lfsvc | Select-Object Name, Status, StartType
```

### Teste 2: Verificar Registro de Permissões
```powershell
Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location"
```

### Teste 3: Testar Assembly System.Device
```powershell
Add-Type -AssemblyName System.Device
$watcher = [System.Device.Location.GeoCoordinateWatcher]::new()
$result = $watcher.TryStart($true, [timespan]::FromSeconds(10))
Write-Host "TryStart retornou: $result"
Write-Host "Status: $($watcher.Status)"
Write-Host "Permission: $($watcher.Permission)"
$location = $watcher.Position.Location
Write-Host "Localização: Lat=$($location.Latitude), Lon=$($location.Longitude), Unknown=$($location.IsUnknown)"
$watcher.Stop()
```

## Mudanças Realizadas

**Arquivo**: `src/Win11DarkMode.psm1` (função `Get-CoordinatesFromWindowsLocation`)

### Alterações:
1. ✓ Mudado de `TryStart($false, ...)` para `TryStart($true, ...)`
   - **Razão**: `$false` tentava iniciar em thread de background, retornando imediatamente antes de obter coordenadas
   - **Efeito**: `$true` bloqueia o thread atual até obter coordenadas ou timeout

2. ✓ Aumentado timeout padrão de 10 para 30 segundos
   - **Razão**: Sistemas lentos podem precisar de mais tempo para obter localização WiFi
   - **Efeito**: Maior taxa de sucesso em primeiro acesso

3. ✓ Adicionado logging de debug
   - **Razão**: Ajuda a diagnosticar problemas
   - **Uso**: Execute com `-Debug` para ver mensagens

4. ✓ Melhorado tratamento de erros e limpeza de recursos
   - **Razão**: Evita vazamento de recursos
   - **Efeito**: Mais estável em múltiplas chamadas

## Próximos Passos

1. Execute `diagnostic.ps1` **com direitos de Administrador**
2. Compartilhe os resultados, especialmente:
   - Status do TESTE 4 (se coordenadas foram obtidas)
   - Se IsUnknown é true ou false
   - Qualquer mensagem de erro específica
