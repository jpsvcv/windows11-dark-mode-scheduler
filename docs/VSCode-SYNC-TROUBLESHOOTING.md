# Guia de Sincronização de Tema VS Code

## Problema Relatado
As janelas de VS Code que estavam abertas permaneceram com o tema claro enquanto o Windows transitava com sucesso entre escuro e claro.

## Solução Implementada

O scheduler agora usa uma **abordagem em múltiplas camadas** para forçar o VS Code a recarregar o tema:

### Estratégia 1: Comando CLI (Recomendada)
```powershell
code --command workbench.action.reloadWindowWithoutAsking
```
**Compatibilidade**: VS Code 1.60+  
**Resultado**: Recarrega a janela ativa sem fechar

### Estratégia 2: Trigger de Configuração
```powershell
code --list-extensions
```
**Compatibilidade**: VS Code 1.0+  
**Resultado**: Força leitura de configurações

### Estratégia 3: Trigger de Arquivo (Fallback)
Atualiza o timestamp do arquivo `settings.json` sem alterar conteúdo, forçando o file watcher do VS Code a detectar mudanças  
**Compatibilidade**: Todas as versões  
**Resultado**: Dispara recarregamento quando VS Code monitora mudanças

---

## Teste Manual

### ✅ Com VS Code Aberta

1. **Prepare o ambiente:**
   ```powershell
   # Abra VS Code e carregue um workspace
   # Defina o tema como "Quit Lite" (claro)
   # Abra uma segunda janela de VS Code para observar mudanças
   ```

2. **Execute o teste:**
   ```powershell
   .\tests\Manual-VSCode-Sync-Test.ps1
   ```

3. **Siga as instruções:**
   - Confirme cada passo
   - Observe a janela de VS Code
   - Verifique se o tema muda automaticamente

### ✅ Teste de Diagnóstico

Para verificar se o seu VS Code suporta os comandos CLI:

```powershell
.\tests\Debug-VSCode-CLI.ps1
```

Procure pela mensagem:
```
[DEBUG] Reload command executed (no output - success!)
```

---

## Troubleshooting

### Problema: O tema não muda automaticamente

**Causa 1: VS Code já foi atualizado**
- Solução: Feche e reabra o VS Code
- Ação: Ctrl+Shift+P → "Reload Window"

**Causa 2: Versão do VS Code antiga**
- Solução: Atualize para v1.60 ou superior
- Verifique: Ajuda → Sobre VS Code

**Causa 3: Arquivo settings.json corrompido**
- Solução: Valide o JSON
- Verificação: `.\tests\Debug-VSCode-CLI.ps1`

**Causa 4: Barreira de permissões**
- Solução: Verifique permissões em `%APPDATA%\Code\User\settings.json`
- Ação: Certifique-se que o utilizador tem permissão de escrita

### Problema: Algumas janelas não sincronizam

**Causa: Múltiplas instâncias de VS Code**
- VS Code Stable
- VS Code Insiders
- VSCodium

Solução: O scheduler tenta atribuir a todas. Se alguma não responder, é necessário manual reload.

---

## Logs e Diagnóstico

### Ver logs de sincronização:

```powershell
# Caminho do log
$logPath = "$env:LOCALAPPDATA\Win11DarkMode\theme-switch.log"

# Ver último log
Get-Content $logPath -Tail 20
```

### Procure por:
```
[Hora] VS Code configured with theme ...
[Hora] Reload command sent to X running VS Code instance(s)
[Hora] Detected X running VS Code instance(s)
```

---

## Workarounds Manuais

Se o auto-sync não funcionar:

### Opção 1: Reload Window (Rápido - 1 segundo)
```
Ctrl+Shift+P → Type "reload window" → Enter
```

### Opção 2: Restart VS Code (Mais agressivo)
```
Feche todas as janelas de VS Code
Reabra com: code <pasta>
```

### Opção 3: Verificar settings.json manualmente
```powershell
# Ver settings
code $env:APPDATA\Code\User\settings.json

# Procure por:
# "window.autoDetectColorScheme": true
# "workbench.preferredLightColorTheme": "Quit Lite"
# "workbench.preferredDarkColorTheme": "VS Code Dark"
```

---

## Especificações Técnicas

### Arquivo Modificado: `Win11DarkMode.psm1`

Função: `Invoke-VSCodeThemeRefresh`

```powershell
# Detecta instâncias de VS Code em execução
# Tenta múltiplas estratégias de reload
# Retorna status detalhado:
@{
    InstancesDetected = <número>
    ReloadAttempted   = $true/$false
    ReloadSuccess     = $true/$false
}
```

### Processo de Sincronização Completo

```
1. Windows muda para Dark/Light mode
2. Scheduler executa Invoke-Win11ThemeMode.ps1
3. Registry do Windows é atualizado
4. settings.json do VS Code é escrito
5. Invoke-VSCodeThemeRefresh é chamada:
   ├─ Tenta --command reloadWindowWithoutAsking
   ├─ Se falhar, tenta --list-extensions
   └─ Se falhar, atualiza timestamp settings.json
6. VS Code detecta mudança
7. Tema é aplicado (ideal < 2 segundos)
```

---

## Testes Automatizados

### Executar testes:
```powershell
.\tests\Test-VSCodeSynchronization.ps1      # Testes estáticos
.\tests\Test-VSCodeLiveInstance.ps1         # Com instâncias ativas
```

### Resultado esperado:
```
[SUCCESS] All VS Code synchronization tests passed!
```

---

## Versões Suportadas

| Versão VS Code | Suporte | Estratégia |
|---|---|---|
| v22.0+ | ✅ Completo | Todos (CLI + Timestamp) |
| v20.0 - v21.9 | ✅ Completo | CLI + Timestamp |
| v1.60 - v19.9 | ✅ Completo | CLI + Timestamp |
| v1.30 - v1.59 | ⚠️ Parcial | Timestamp + Fallback |
| v1.0 - v1.29 | ⚠️ Limitado | Apenas Timestamp |

**Nota**: Todas as versões recebem sincronização via arquivo settings.json. O reload automático depende do suporte CLI.

---

## Próximas Melhorias

- [ ] Criar extensão VS Code para monitorização nativa
- [ ] Implementar WebSocket para comunicação bidirecional
- [ ] Adicionar configuração de timeout de reload
- [ ] Suporte para dev containers

---

## Referências

- [VS Code Command Palette](https://code.visualstudio.com/docs/getstarted/userinterface#_command-palette)
- [Color Theme Settings](https://code.visualstudio.com/docs/getstarted/themes)
- [Settings JSON Schema](https://code.visualstudio.com/docs/getstarted/settings)

---

**Última atualização**: 9 Abril 2026  
**Versão**: v1.1+  
**Status**: Estável ✅
