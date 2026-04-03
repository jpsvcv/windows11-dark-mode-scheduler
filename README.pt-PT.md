# Win11 Auto Appearance Scheduler

Utilitario para Windows 11 criado para aproximar o comportamento do sistema ao do macOS no que toca a aparencia automatica.

O objetivo e que o Windows 11 passe a comportar-se de forma semelhante ao macOS, transitando automaticamente entre modo claro e modo escuro com base num horario definido pelo utilizador ou na deteccao local do nascer e do por do Sol.

A transicao pode ser feita com base:

- numa hora definida pelo utilizador para entrar em modo escuro
- ou, por defeito, na hora do por do sol da localizacao configurada
- na hora local do nascer do sol para voltar ao modo claro

Se o Visual Studio Code estiver instalado, o instalador tambem consegue listar todos os temas escuros disponiveis no computador e permitir ao utilizador escolher o tema escuro predefinido. Se nenhuma escolha for feita, o instalador adota `VS Code Dark` e, quando necessario, usa o tema escuro built-in mais proximo disponivel.

## Funcionalidades

- Aproxima o Windows 11 de um fluxo de aparencia automatica ao estilo do macOS
- Alterna automaticamente o tema de apps e do sistema no Windows 11
- Calcula nascer e por do sol a partir de latitude, longitude e `TimeZoneId` do Windows
- Permite definir manualmente a hora de entrada no modo escuro
- Regista tarefas autonomas no Windows Task Scheduler
- Deteta o VS Code e configura:
  - `window.autoDetectColorScheme`
  - `workbench.preferredLightColorTheme`
  - `workbench.preferredDarkColorTheme`
- Permite interacao do instalador em `pt-PT` ou `en-EN`

## Requisitos

- Windows 11
- PowerShell 5.1 ou superior
- Permissao para criar tarefas no Windows Task Scheduler para o utilizador atual
- Localizacao do Windows ativa caso queira detecao automatica das coordenadas

Se algum requisito relevante nao estiver ativo ou disponivel, o instalador inclui agora um assistente interativo de requisitos que pode:

- abrir as definicoes de localizacao do Windows quando a autodeteccao nao estiver pronta
- instalar ou abrir o fluxo de download do VS Code quando a sincronizacao do tema do editor estiver ativa
- guiar o utilizador antes de a instalacao continuar

## Inicio Rapido

Executar o instalador e escolher o idioma durante a instalacao:

```powershell
.\scripts\install.ps1
```

O menu principal disponibiliza:

- `Instalar ou atualizar`
- `Desinstalar`
- `Verificar requisitos`
- `Sair`

Instalacao com coordenadas explicitas para Praia, Cabo Verde:

```powershell
.\scripts\install.ps1 -Language pt-PT -Latitude 14.9330 -Longitude -23.5133 -LocationName "Praia, Cabo Verde" -TimeZoneId "Cape Verde Standard Time"
```

Instalacao com hora fixa para modo escuro:

```powershell
.\scripts\install.ps1 -Language pt-PT -Latitude 14.9330 -Longitude -23.5133 -LocationName "Praia, Cabo Verde" -TimeZoneId "Cape Verde Standard Time" -DarkModeTime 19:30
```

Prever a instalacao sem aplicar alteracoes:

```powershell
.\scripts\install.ps1 -Language pt-PT -Latitude 14.9330 -Longitude -23.5133 -TimeZoneId "Cape Verde Standard Time" -WhatIf
```

## Selecao de Tema no VS Code

Quando o VS Code e detetado e `-VSCodeDarkTheme` nao e fornecido, o instalador:

1. lista todos os temas escuros encontrados nas extensoes instaladas e nos temas built-in
2. pede ao utilizador para escolher qual deve ser o tema escuro predefinido
3. assume `VS Code Dark` quando o utilizador carrega Enter sem escolher

O tema claro continua, por defeito, a ser `Quit Lite`, a menos que seja alterado com `-VSCodeLightTheme`.

## Como Funciona

O instalador copia os scripts de runtime para `%LOCALAPPDATA%\Win11DarkMode`, grava um `config.json` persistente e cria tres tarefas agendadas:

- uma tarefa de refresco diario e no logon
- uma tarefa pontual para a proxima transicao para modo escuro
- uma tarefa pontual para a proxima transicao para modo claro

O runtime atualiza os valores do tema do Windows em:

- `HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize`

Como o tema fica guardado em `HKCU`, as tarefas agendadas correm no contexto do utilizador atual.

Na pratica, isto faz com que o Windows 11 ganhe um ciclo automatico de aparencia semelhante ao do macOS: claro durante o dia e escuro ao anoitecer, com base num horario fixo ou nos eventos solares da localizacao configurada.

O instalador funciona como ponto de entrada principal do projeto, por isso a instalacao, a desinstalacao e a validacao assistida dos requisitos acontecem a partir da mesma experiencia orientada por menu.

## Comandos Uteis

Aplicar o tema imediatamente a partir do runtime instalado:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:LOCALAPPDATA\Win11DarkMode\runtime\Invoke-Win11ThemeMode.ps1"
```

Atualizar manualmente as tarefas agendadas:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:LOCALAPPDATA\Win11DarkMode\runtime\Refresh-ThemeSchedule.ps1"
```

Remover a ferramenta:

```powershell
.\scripts\uninstall.ps1
```

Inspecionar o agendamento instalado:

```powershell
.\scripts\check-tasks.ps1
```

Executar os testes de integracao ponta a ponta:

```powershell
.\tests\Invoke-IntegrationTests.ps1
```

## Estrutura do Projeto

- `src/Win11DarkMode.psm1`: logica principal, descoberta de temas do VS Code, calculo solar e agendamento
- `src/Invoke-Win11ThemeMode.ps1`: aplica imediatamente o tema claro ou escuro
- `src/Refresh-ThemeSchedule.ps1`: recalcula os proximos eventos e atualiza as tarefas no Task Scheduler
- `scripts/install.ps1`: instalador localizado e seletor de tema do VS Code
- `scripts/uninstall.ps1`: remove ficheiros instalados e tarefas agendadas
- `scripts/check-tasks.ps1`: inspeciona a configuracao instalada e as tarefas agendadas
- `tests/Invoke-IntegrationTests.ps1`: executa testes de integracao isolados

## Notas

- Se a detecao automatica da localizacao falhar, volte a correr o instalador com `-Latitude` e `-Longitude`.
- Se a localizacao configurada nao usar a timezone atual do Windows, passe `-TimeZoneId` explicitamente.
- Por defeito, as definicoes do VS Code sao escritas no primeiro `settings.json` encontrado nos caminhos padrao. Pode alterar isso com `-VSCodeSettingsPath`.
- Os logs ficam em `%LOCALAPPDATA%\Win11DarkMode\theme-switch.log`.
