# 🎤 Omni Voice — Speech-to-Agent

> Transforme sua fala em comandos para agentes de IA diretamente do Termux.

## Visão Geral

`omni voice` captura áudio do microfone, transcreve com o speech-to-text do Android,
permite revisão no Neovim, copia para a área de transferência e dispara qualquer
agente de IA com o prompt. Tudo em um único comando.

## Instalação

```bash
# 1. Instalar dependências
pkg install termux-api
omni install editor     # Neovim (opcional, mas recomendado)

# 2. Instalar o app Termux:API no Android
#    https://omni-catalyst.vercel.app/termux/api

# 3. Verificar instalação
omni doctor
```

## Uso Básico

```bash
omni voice opencode          # Grava → edita → executa no opencode
omni voice text              # Grava → edita → imprime no terminal
omni voice "!"               # Atalho para "text"
omni voice                   # Mostra ajuda
```

## Opções

### `--lang <código>`

Define o idioma do reconhecimento de fala. Use códigos ISO:

```bash
omni voice opencode --lang pt-BR    # Português brasileiro
omni voice claude-code --lang en-US # Inglês americano
omni voice kimi-code --lang es      # Espanhol
```

### `--raw`

Pula a etapa de edição no Neovim. A captura bruta é enviada diretamente:

```bash
omni voice opencode --raw
omni voice text --raw
```

### `--no-clip`

Não copia o prompt para a área de transferência:

```bash
omni voice opencode --no-clip
```

## Agentes Suportados

| Nome | Comando | Exemplo |
|------|---------|---------|
| `kilo` | `kilo --prompt "..."` | `omni voice kilo` |
| `opencode` | `opencode run "..."` | `omni voice opencode` |
| `claude-code` | `claude -p "..."` | `omni voice claude-code` |
| `codex` | `codex "..."` | `omni voice codex` |
| `gemini-cli` | `gemini -p "..."` | `omni voice gemini-cli` |
| `hermes-agent` | `hermes chat -q "..."` | `omni voice hermes-agent` |
| `kimi-code` | `kimi -p "..."` | `omni voice kimi-code` |
| `mimocode` | `mimo run "..."` | `omni voice mimocode` |
| `mistral-vibe` | `vibe --prompt "..."` | `omni voice mistral-vibe` |
| `openclaude` | `openclaude --bg "..."` | `omni voice openclaude` |
| `pi` | `pi -p "..."` | `omni voice pi` |
| `qwen-code` | `qwen -p "..."` | `omni voice qwen-code` |
| `text` | stdout | `omni voice text` |

## Fluxo Detalhado

```
1. omni voice <agent>
         │
         ▼
2. termux-api-start (inicia API activity)
         │
         ▼
3. termux-speech-to-text (abre microfone)
         │
         ├── Fale o prompt
         │
         ▼
4. Transcrição salva em arquivo temporário
         │
         ▼
5. nvim (edição e correção)
         │
         ├── Corrigir erros de transcrição
         │   Ajustar pontuação e formatação
         │   :wq para continuar
         │
         ▼
6. Prompt → clipboard (termux-clipboard-set)
         │
         ▼
7. Prompt → AI Agent (executa comando)
```

## Exemplos Práticos

### Desenvolvimento com Voz

```bash
# Pedir para o Claude criar um componente React
omni voice claude-code --lang en-US

# Falar: "Create a React component that shows a counter with increment and decrement buttons"
```

### Código com opencode

```bash
# Descrever uma feature em português
omni voice opencode --lang pt-BR

# Falar: "Cria uma função que valida email com regex e retorna boolean"
```

### Anotações Rápidas

```bash
# Transcrever ideia e salvar em arquivo
omni voice text --raw --no-clip >> ideias.txt
```

### Pipeline com `!`

```bash
# "!" é atalho para "text" (mas cuidado com history expansion no bash)
omni voice '!' --raw
```

## Solução de Problemas

### "No speech detected"

Causas possíveis:
- Microfone sem permissão: vá em Config. Android > Apps > Termux > Permissões > Microfone
- App Termux:API não instalado: https://omni-catalyst.vercel.app/termux/api
- Termux:API desatualizado: `pkg upgrade termux-api`

### "Termux:API is not installed"

```bash
pkg install termux-api
```

### Captura em inglês mesmo falando português

Use `--lang pt-BR`:

```bash
omni voice opencode --lang pt-BR
```

### Neovim não abre

Certifique-se de que há um TTY disponível. Se estiver em pipe/redirecionamento,
use `--raw` para pular a edição.

### `!` dá erro de history expansion no bash

Use aspas simples ou escape:

```bash
omni voice '!'
# ou
omni voice \!
```

## Arquitetura

```
omni/cli/commands/voice.sh    → CLI command (dispatcher)
omni/modules/voice.sh         → Module orchestrator (install/update/uninstall)
omni/tools/voice/             → Tool installers
  ├── all.sh                  → Aggregate component installer
  ├── install.sh              → Component installation
  └── uninstall.sh            → Component removal
```

Dependências externas:
- `termux-api` package (speech-to-text, clipboard, API start)
- Termux:API Android app (APK)
- `nvim` (opcional — edição do prompt)

## Licença

MIT — parte do ecossistema Omni Catalyst.
