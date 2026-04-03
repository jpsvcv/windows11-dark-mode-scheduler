# Solução - Problema de Localização

## O Problema

O instalador estava bloqueando porque:
- ✅ Serviço de localização (lfsvc) está rodando
- ✅ Consentimento de localização está ativado
- ❌ **Windows ainda não tem dados de localização**

Isto é **normal** na primeira vez que o Windows é configurado.

## Soluções

### Solução 1: Aguardar dados (Recomendado)

1. Abra: **Configurações > Privacidade e Segurança > Localização**
2. Deixe aberto por **3-5 minutos**
3. Windows coleta dados WiFi automaticamente
4. Execute o instalador novamente

### Solução 2: Usar coordenadas manuais (Rápido)

Forneça coordenadas manualmente, contornando a detecção automática:

```powershell
cd "C:\Users\jakso\OneDrive - Electra\projetos\win11-dark-mode"

# Exemplo: São Paulo
.\install.ps1 -Latitude -23.5505 -Longitude -46.6333 -LocationName "Sao Paulo"

# Exemplo: Lisboa
.\install.ps1 -Latitude 38.7223 -Longitude -9.1393 -LocationName "Lisboa"

# Exemplo: New York
.\install.ps1 -Latitude 40.7128 -Longitude -74.0060 -LocationName "New York"
```

### Solução 3: Usar o script de teste

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\Users\jakso\OneDrive - Electra\projetos\win11-dark-mode\test-install-manual.ps1"
```

## Mudanças Realizadas

**Arquivo**: `install.ps1`

**Linha 476**: Localização agora é **OPCIONAL** em vez de crítica

```powershell
# ANTES:
IsCritical = $true   # Bloqueava a instalação

# DEPOIS:
IsCritical = $false  # Aviso que pode ser contornado
```

**Impacto**:
- Se Windows não tiver dados de localização, o instalador vai pedir coordenadas manualmente
- Não bloqueia mais a instalação

## Como Encontrar suas Coordenadas

Se não souber suas coordenadas, acesse:
https://www.google.com/maps

1. Clique no seu local no mapa
2. As coordenadas aparecem na barra de pesquisa
3. Use `-Latitude` e `-Longitude`

Exemplo:
```
Latitude Norte: 40
Longitude Oeste: -74

Comando: .\install.ps1 -Latitude 40 -Longitude -74
```

## Próximos Passos

Execute uma destas opções:

1. **Teste rápido com coordenadas manuais**:
   ```powershell
   test-install-manual.ps1
   ```

2. **Instalação com suas coordenadas**:
   ```powershell
   .\install.ps1 -Latitude SEU_LAT -Longitude SEU_LON
   ```

3. **Espere dados WiFi e tente instalação normal**:
   ```powershell
   .\install.ps1
   ```
