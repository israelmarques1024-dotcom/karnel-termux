<p align="center">
  <img src="https://raw.githubusercontent.com/israelmarques1024-dotcom/karnel-termux/main/assets/images/karnel-logo.png" alt="Karnel Termux Logo" width="400">
</p>

<p align="center">
  <strong>🚀 Transforme seu Android em uma estação de desenvolvimento completa.</strong>
</p>

<p align="center">
  <a href="https://github.com/israelmarques1024-dotcom/karnel-termux">
    <img src="https://img.shields.io/badge/version-1.0.0-0078D4?style=for-the-badge&logo=appveyor" alt="Version">
  </a>
  <a href="https://www.npmjs.com/package/karnel-termux">
    <img src="https://img.shields.io/npm/v/karnel-termux?style=for-the-badge&logo=npm&color=cb3837" alt="npm">
  </a>
  <a href="https://www.npmjs.com/package/karnel-termux">
    <img src="https://img.shields.io/npm/dt/karnel-termux?style=for-the-badge&logo=npm&color=cb3837" alt="npm downloads">
  </a>
  <a href="https://github.com/israelmarques1024-dotcom/karnel-termux/blob/main/LICENSE">
    <img src="https://img.shields.io/badge/license-MIT-0078D4?style=for-the-badge&logo=bookstack" alt="License">
  </a>
  <a href="https://termux.dev/">
    <img src="https://img.shields.io/badge/platform-Termux%20%7C%20Android-0078D4?style=for-the-badge&logo=android" alt="Platform">
  </a>
  <a href="https://kerneltermux.vercel.app">
    <img src="https://img.shields.io/badge/%F0%9F%8C%90%20Site-karnel--termux.vercel.app-0078D4?style=for-the-badge" alt="Website">
  </a>
</p>



---

**KARNEL TERMUX** é um ambiente de desenvolvimento modular que transforma o Termux em uma workstation completa. Com um único CLI (`karnel`), instale e gerencie:

Criado por **israel marques** (tenho 12 anos).

- **30 agentes de IA** para coding — Claude, Gemini, OpenCode, Ollama, Cline, karnelRoute e mais
- **7 linguagens** — Node.js, Python, Go, Rust, C/C++, PHP, Perl
- **4 bancos de dados** — PostgreSQL, MariaDB, SQLite, MongoDB
- **19 ferramentas dev** — gh, curl, fzf, bat, lsd, jq e muito mais
- **3 CLIs de deploy** — Vercel, Railway, Netlify
- **Editor profissional** — code-server (VS Code no navegador)
- **Segundo cérebro** — Sistema de memória com busca por IA e grafo de ideias
- **Comandos de voz** — Fale com seus agentes de IA

> [!IMPORTANT]
> Projetado exclusivamente para **Termux no Android**. Não funciona em outras plataformas.

---

## 📦 Instalação

### Via curl (recomendado)

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/israelmarques1024-dotcom/karnel-termux/main/install.sh)"
```

### Via npm

```bash
npm install -g karnel-termux
```

### Via pnpm

```bash
pnpm add -g karnel-termux
```

Depois de instalar, execute:

```bash
karnel
```

---

## 🎯 Comandos Principais

| Comando | Descrição |
|---------|-----------|
| `karnel install <modulo>` | Instala módulos e ferramentas |
| `karnel list <modulo>` | Lista ferramentas disponíveis |
| `karnel show <modulo> --<tool>` | Mostra documentação de uma ferramenta |
| `karnel open <modulo>` | Abre documentação no navegador |
| `karnel update <modulo>` | Atualiza módulos ou o karnel |
| `karnel uninstall <modulo>` | Remove módulos instalados |
| `karnel reinstall <modulo>` | Reinstala módulos |
| `karnel doctor` | Diagnostica o ambiente (30+ verificações) |
| `karnel brain` | Segundo cérebro — memórias e busca |
| `karnel env` | Gerencia variáveis de ambiente |
| `karnel voice` | Comandos de voz para agentes IA |
| `karnel start editor` | Inicia code-server (VS Code no navegador) |
| `karnel pg` | Gerenciador PostgreSQL |
| `karnel init <template>` | Inicializa projetos com templates |
| `karnel deploy` | Publica projetos (Vercel, Railway, Netlify) |
| `karnel --version` | Mostra a versão instalada |

---

## 🧩 Módulos

| Módulo | Descrição | Instalação |
|--------|-----------|------------|
| `lang` | Node.js, Python, Go, Rust, C/C++, PHP, Perl | `karnel install lang` |
| `db` | PostgreSQL, MariaDB, SQLite, MongoDB | `karnel install db` |
| `ai` | 30 agentes de IA para coding | `karnel install ai` |
| `editor` | code-server (VS Code no navegador) | `karnel install editor` |
| `dev` | gh, curl, fzf, bat, lsd, jq e mais | `karnel install dev` |
| `npm` | TypeScript, NestJS CLI, Prettier e mais | `karnel install npm` |
| `shell` | ZSH + Oh My Zsh + 10 plugins | `karnel install shell` |
| `ui` | Fonte, cursor, extra-keys, banner | `karnel install ui` |
| `auto` | Automação com n8n | `karnel install auto` |
| `deploy` | Vercel, Railway, Netlify | `karnel install deploy` |

---

## 🤖 Agentes de IA (30)

```bash
karnel install ai                               # Instala todos
karnel install ai --opencode --ollama           # Instala específicos
```

<details>
<summary><strong>Ver lista completa de agentes</strong></summary>

| Agente | Flag | Descrição |
|--------|------|-----------|
| **Qwen Code** | `--qwen-code` | Assistente de codificação da Alibaba |
| **Gemini CLI** | `--gemini-cli` | Assistente Google Gemini |
| **Claude Code** | `--claude-code` | CLI da Anthropic com Claude AI |
| **Mistral Vibe** | `--mistral-vibe` | Assistente de linha de comando Mistral |
| **OpenClaude** | `--openclaude` | Alternativa open source ao Claude Code |
| **OpenClaw** | `--openclaw` | Assistente pessoal de IA |
| **Ollama** | `--ollama` | Execute LLMs open source localmente |
| **Codex CLI** | `--codex` | Agente de codificação OpenAI |
| **OpenCode** | `--opencode` | Agente open source para terminal |
| **MiMoCode** | `--mimocode` | Agente de IA rápido e open source |
| **Engram** | `--engram` | Sistema de memória persistente |
| **CodeGraph** | `--codegraph` | Análise de estrutura de código |
| **Pi** | `--pi` | Harness de terminal minimalista |
| **Antigravity CLI** | `--antigravity-cli` | Interface terminal para Antigravity |
| **MiniMax CLI** | `--minimax-cli` | Gere texto, imagem, vídeo e áudio |
| **Gentle AI** | `--gentle-ai` | Ecossistema de workflows para IA |
| **GGA** | `--gga` | Code review automatizado multi-provider |
| **Hermes Agent** | `--hermes-agent` | Agente auto-melhorável Nous Research |
| **Kimi Code** | `--kimi-code` | CLI Kimi Code —下一代 agent |
| **Command Code** | `--command-code` | Agente que aprende seu estilo |
| **Freebuff** | `--freebuff` | Agente comunitário gratuito |
| **Kilo Code CLI** | `--kilocode-cli` | CLI nativo glibc para Termux |
| **Kiro CLI** | `--kiro` | Assistente de código AI da AWS |
| **Crush CLI** | `--crush` | CLI para AI agents Charm |
| **Odysseus** | `--odysseus` | Assistente de código Odysseus |
| **Kimchi CLI** | `--kimchi-code` | Agente de IA Kimchi |
| **Cline CLI** | `--cline` | Agente de codificação autônomo (via proot-distro) |
| **karnelRoute** | `--karnel-route` | AI Gateway com 236+ provedores |
| **Context7** | `--ctx7` | Documentação para AI assistants |
| **OpenSpec** | `--openspec` | Spec-Driven Development |

</details>

---

## 🏥 karnel doctor

Diagnostique seu ambiente Termux + Karnel com 30+ verificações automáticas:

```bash
karnel doctor
```

**Verificações incluídas:**
1. Informações do sistema (Android, Termux, CPU)
2. Recursos (disco, RAM, alertas)
3. Armazenamento e permissões
4. Linguagens e ferramentas críticas
5. Saúde do gerenciador de pacotes (dpkg, apt)
6. Node.js e npm
7. Ambiente Python
8. PostgreSQL
9. Framework Karnel
10. Status dos agentes de IA
11. Configuração do shell
12. Compatibilidade Android
13. Termux:API
14. Configuração Git
15. Chaves SSH
16. Conectividade de rede
17. Servidor OpenSSH
18. Saúde do disco
19. Integridade dos dados Karnel
20. Geração de relatório

Cada verificação pode ser corrigida automaticamente com auto-fix.

---

## 🧠 karnel brain — Segundo Cérebro

Sistema de memória integrado com busca semântica por IA e visualização em grafo.

```bash
karnel brain save "minha ideia"       # Salva um pensamento
karnel brain search "postgres"       # Busca por similaridade semântica
karnel brain graph                   # Visualiza conexões entre ideias
karnel brain sync                    # Sincroniza com GitHub privado
```

---

## 🎤 karnel voice

Capture áudio pelo microfone, revise no editor, copie para a área de transferência e dispare qualquer agente de IA com o prompt transcrito.

```bash
karnel voice opencode                # Grava → edita → opencode run
karnel voice text                    # Grava → edita → imprime no terminal
karnel voice claude-code --lang pt-BR # Fala em português → claude -p
karnel voice "!"                     # Atalho para "text"
```

### Agentes Suportados (15)

| Agente | Comando executado |
|--------|------------------|
| `kilo` | `kilo --prompt "..."` |
| `opencode` | `opencode run "..."` |
| `claude-code` | `claude -p "..."` |
| `codex` | `codex "..."` |
| `gemini-cli` | `gemini -p "..."` |
| `hermes-agent` | `hermes chat -q "..."` |
| `kimi-code` | `kimi -p "..."` |
| `mimocode` | `mimo run "..."` |
| `mistral-vibe` | `vibe --prompt "..."` |
| `openclaude` | `openclaude --bg "..."` |
| `pi` | `pi -p "..."` |
| `qwen-code` | `qwen -p "..."` |
| `crush` | `crush "..."` |
| `kiro` | `kiro-cli "..."` |
| `text` | Imprime o prompt no terminal |

### Opções

| Flag | Descrição |
|------|-----------|
| `--lang <code>` | Idioma da fala: `pt-BR`, `en-US`, `es`, etc |
| `--raw` | Pula edição no editor, usa captura direta |
| `--no-clip` | Não copia prompt para área de transferência |

### Fluxo de Uso

```
Microfone → termux-speech-to-text → editor (edição) → clipboard → AI agent
```

1. Fale o prompt
2. Revise e corrija no editor
3. Prompt é copiado pro clipboard
4. Agente de IA é disparado com o prompt

### Requisitos

- Termux:API: `pkg install termux-api`
- App Termux:API: https://kerneltermux.vercel.app/termux/api
- Editor: `karnel install editor`

---

## 🗄️ karnel pg — PostgreSQL

Gerencie bancos PostgreSQL com comandos simples:

```bash
karnel pg init && karnel pg start      # Inicializa e sobe o servidor
karnel pg create meuapp              # Cria um banco
karnel pg shell                      # Abre o console psql
```

---

## 🚀 karnel init — Templates de Projetos

Crie projetos pré-configurados em segundos:

```bash
cd my-app && karnel init next         # Next.js + TypeScript + Tailwind
cd my-api && karnel init express      # Express + TypeORM
cd backend && karnel init nest        # NestJS + autenticação
```

| Template | Descrição |
|----------|-----------|
| `next` | Next.js com Turbopack, TypeScript, Tailwind, React Query, Zustand |
| `react` | React + Vite com estrutura moderna |
| `express` | Express API com TypeScript + TypeORM + migrations |
| `nest` | NestJS com TypeORM e autenticação JWT |
| `python` | FastAPI com SQLModel/SQLAlchemy |
| `go` | Go com Gin ou Fiber |
| `rust` | Rust com Axum ou Actix Web |

---

## 🔧 karnel env

Gerencie variáveis de ambiente com segurança:

```bash
karnel env set OPENAI_API_KEY        # Adiciona chave (input oculto)
karnel env list                      # Lista variáveis
karnel env ls                        # Lista variáveis
```

---

## 🚢 karnel deploy

Publique seus projetos diretamente do terminal:

```bash
karnel deploy vercel                  # Deploy para Vercel
karnel deploy railway                 # Deploy para Railway
karnel deploy netlify                 # Deploy para Netlify
```

Os CLIs das plataformas são instalados automaticamente e você faz deploy sem sair do Termux.

---

## 📖 karnel open

Abra a documentação de qualquer módulo ou ferramenta no navegador:

```bash
karnel open ai                        # Abre documentação do módulo AI
karnel open db                        # Abre documentação do módulo DB
karnel open ai --opencode             # Abre docs do OpenCode no site
```

A documentação é carregada do site oficial em https://kerneltermux.vercel.app.

---

## 📖 Exemplos de Uso

```bash
# Instalar banco de dados
karnel install db --postgresql --sqlite

# Instalar agentes de IA específicos
karnel install ai --opencode --ollama --claude-code

# Ver ferramentas disponíveis
karnel list ai

# Ver documentação de uma ferramenta
karnel show ai --opencode

# Atualizar tudo
karnel update karnel

# Reinstalar um módulo
karnel reinstall shell

# Diagnóstico completo
karnel doctor

# Deploy direto
karnel deploy vercel
```

---

## 🏗️ Estrutura do Projeto

```
karnel/
├── karnel/
│   ├── bin/           # Binário (karnel)
│   ├── cli/
│   │   ├── commands/  # Comandos CLI (install, list, show, etc.)
│   │   └── karnel.sh    # CLI principal (com TUI)
│   ├── modules/       # Orquestradores de módulos
│   ├── tools/         # Instaladores de ferramentas
│   │   ├── ai/        # 30 agentes de IA
│   │   ├── lang/      # Linguagens
│   │   ├── db/        # Bancos de dados
│   │   ├── dev/       # Ferramentas dev
│   │   ├── editor/    # Editor de código
│   │   ├── npm/       # Pacotes npm globais
│   │   ├── shell/     # Plugins ZSH
│   │   ├── ui/        # Interface Termux
│   │   ├── auto/      # Automação
│   │   └── deploy/    # CLIs de deploy
│   └── utils/         # Utilitários (banner, log, env, etc.)
├── install.sh         # Script de instalação
├── package.json       # Publicação npm/pnpm
└── .github/workflows/ # CI/CD
```

---

## ⚙️ Configuração

### Variáveis de Ambiente

```bash
export KARNEL_DEBUG=1      # Logs de debug
```

### Diretórios

| Diretório | Descrição |
|-----------|-----------|
| `~/.local/share/karnel-data/` | Dados persistentes das ferramentas |
| `~/.cache/karnel/` | Logs e cache |
| `~/.config/karnel/` | Configuração do usuário |

---

## 🔄 Atualizações Automáticas

O framework verifica atualizações a cada 24 horas em background.

```bash
karnel update karnel     # Atualiza o framework
```

---

## ⭐ Apoie o Projeto

Se o Karnel Termux foi útil pra você, considere apoiar via Pix ou dar uma estrela no GitHub — isso ajuda outros desenvolvedores a descobrirem o projeto.

**Pix:** `037f07bd-a326-42b6-a5a3-f29b36e703db`

---

## 📄 Licença

MIT © israel marques

---

<p align="center">
  <a href="https://kerneltermux.vercel.app">
    <img src="https://img.shields.io/badge/%F0%9F%8C%90%20Documenta%C3%A7%C3%A3o%20Completa-0078D4?style=for-the-badge" alt="Documentação">
  </a>
  <a href="https://github.com/israelmarques1024-dotcom/karnel-termux-site">
    <img src="https://img.shields.io/badge/%F0%9F%93%B1%20Site%20Repo-0078D4?style=for-the-badge" alt="Site Repo">
  </a>
</p>
