<p align="center">
  <img src="https://raw.githubusercontent.com/israel676767/omni/main/assets/images/logo.svg" alt="Omni Catalyst Logo" width="600">
</p>

<p align="center">
  <strong>🚀 Transforme seu Android em uma estação de desenvolvimento completa.</strong>
</p>

<p align="center">
  <a href="https://github.com/israel676767/omni">
    <img src="https://img.shields.io/badge/version-1.0.1-0078D4?style=for-the-badge&logo=appveyor" alt="Version">
  </a>
  <a href="https://www.npmjs.com/package/omni-catalyst">
    <img src="https://img.shields.io/npm/v/omni-catalyst?style=for-the-badge&logo=npm&color=cb3837" alt="npm">
  </a>
  <a href="https://www.npmjs.com/package/omni-catalyst">
    <img src="https://img.shields.io/npm/dt/omni-catalyst?style=for-the-badge&logo=npm&color=cb3837" alt="npm downloads">
  </a>
  <a href="https://github.com/israel676767/omni/blob/main/LICENSE">
    <img src="https://img.shields.io/badge/license-MIT-0078D4?style=for-the-badge&logo=bookstack" alt="License">
  </a>
  <a href="https://termux.dev/">
    <img src="https://img.shields.io/badge/platform-Termux%20%7C%20Android-0078D4?style=for-the-badge&logo=android" alt="Platform">
  </a>
  <a href="https://omni-catalyst.vercel.app">
    <img src="https://img.shields.io/badge/%F0%9F%8C%90%20Site-omni--catalyst.vercel.app-0078D4?style=for-the-badge" alt="Website">
  </a>
</p>

<p align="center">
  <a href="https://github.com/israel676767/omni/stargazers">
    <img src="https://img.shields.io/github/stars/israel676767/omni?style=for-the-badge&logo=github&color=f5c542" alt="Stars">
  </a>
  <a href="https://github.com/israel676767/omni/network/members">
    <img src="https://img.shields.io/github/forks/israel676767/omni?style=for-the-badge&logo=github&color=94a3b8" alt="Forks">
  </a>
  <a href="https://github.com/israel676767/omni/issues">
    <img src="https://img.shields.io/github/issues/israel676767/omni?style=for-the-badge&logo=github&color=ef4444" alt="Issues">
  </a>
  <a href="https://github.com/israel676767/omni/pulls">
    <img src="https://img.shields.io/github/issues-pr/israel676767/omni?style=for-the-badge&logo=github&color=22c55e" alt="Pull Requests">
  </a>
</p>

---

**OMNI CATALYST** é um ambiente de desenvolvimento modular que transforma o Termux em uma workstation completa. Com um único CLI (`omni`), instale e gerencie:

- **28 agentes de IA** para coding — Claude, Gemini, OpenCode, Ollama e mais
- **8 linguagens** — Node.js, Python, Go, Rust, C/C++, PHP, Perl
- **4 bancos de dados** — PostgreSQL, MariaDB, SQLite, MongoDB
- **19 ferramentas dev** — gh, curl, fzf, bat, lsd, jq e muito mais
- **3 CLIs de deploy** — Vercel, Railway, Netlify
- **Editor profissional** — Neovim + NvChad com LSP + Copilot
- **Segundo cérebro** — Sistema de memória com busca por IA e grafo de ideias
- **Comandos de voz** — Fale com seus agentes de IA

> [!IMPORTANT]
> Projetado exclusivamente para **Termux no Android**. Não funciona em outras plataformas.

---

## 📦 Instalação

### Via curl (recomendado)

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/israel676767/omni/main/install.sh)"
```

### Via npm

```bash
npm install -g omni-catalyst
```

### Via pnpm

```bash
pnpm add -g omni-catalyst
```

Depois de instalar, execute:

```bash
omni
```

---

## 🎯 Comandos Principais

| Comando | Descrição |
|---------|-----------|
| `omni install <modulo>` | Instala módulos e ferramentas |
| `omni list <modulo>` | Lista ferramentas disponíveis |
| `omni show <modulo> --<tool>` | Mostra documentação de uma ferramenta |
| `omni update <modulo>` | Atualiza módulos ou core |
| `omni uninstall <modulo>` | Remove módulos instalados |
| `omni reinstall <modulo>` | Reinstala módulos |
| `omni doctor` | Diagnostica o ambiente (20 verificações) |
| `omni brain` | Segundo cérebro — memórias e busca |
| `omni env` | Gerencia variáveis de ambiente |
| `omni voice` | Comandos de voz para agentes IA |
| `omni pg` | Gerenciador PostgreSQL |
| `omni init <template>` | Inicializa projetos com templates |
| `omni open <modulo>` | Abre documentação no navegador |
| `omni --version` | Mostra a versão instalada |

---

## 🧩 Módulos

| Módulo | Descrição | Instalação |
|--------|-----------|------------|
| `lang` | Node.js, Python, Go, Rust, C/C++, PHP, Perl | `omni install lang` |
| `db` | PostgreSQL, MariaDB, SQLite, MongoDB | `omni install db` |
| `ai` | 28 agentes de IA para coding | `omni install ai` |
| `editor` | Neovim + NvChad + LSP + Copilot | `omni install editor` |
| `dev` | gh, curl, fzf, bat, lsd, jq e mais | `omni install dev` |
| `npm` | TypeScript, NestJS CLI, Prettier e mais | `omni install npm` |
| `shell` | ZSH + Oh My Zsh + 10 plugins | `omni install shell` |
| `ui` | Fonte, cursor, extra-keys, banner | `omni install ui` |
| `auto` | Automação com n8n | `omni install auto` |
| `deploy` | Vercel, Railway, Netlify | `omni install deploy` |

---

## 🤖 Agentes de IA (28)

```bash
omni install ai                               # Instala todos
omni install ai --opencode --ollama           # Instala específicos
```

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
| **Kilo Code CLI** | `--kilocode-cli` | Cli nativo glibc para Termux |
| **Kiro CLI** | `--kiro-cli` | Assistente de linha de comando Kiro |
| **HeyGen CLI** | `--heygen` | Interface para HeyGen |
| **Seedance CLI** | `--seedance` | Ferramenta de linha de comando Seedance |
| **Veo 3 SDK** | `--veo3` | SDK para vídeo Veo 3 |
| **Odysseus** | `--odysseus` | Assistente de código Odysseus |
| **Kimchi AI** | `--kimchi-code` | Agente de IA Kimchi |

---

## 🏥 omni doctor

Diagnostique seu ambiente Termux + Omni com 20 verificações automáticas:

```bash
omni doctor
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
9. Framework Omni
10. Status dos agentes de IA
11. Configuração do shell
12. Compatibilidade Android
13. Termux:API
14. Configuração Git
15. Chaves SSH
16. Conectividade de rede
17. Servidor OpenSSH
18. Saúde do disco
19. Integridade dos dados Omni
20. Geração de relatório

Cada verificação pode ser corrigida automaticamente com auto-fix.

---

## 🧠 omni brain — Segundo Cérebro

Sistema de memória integrado com busca semântica por IA e visualização em grafo.

```bash
omni brain add "minha ideia"       # Salva um pensamento
omni brain search "postgres"       # Busca por similaridade semântica
omni brain graph                   # Visualiza conexões entre ideias
omni brain sync                    # Sincroniza com GitHub privado
```

---

## 🎤 omni voice

Capture áudio, revise no Neovim e envie para qualquer agente de IA.

```bash
omni voice gemini                  # Grava → revisa → envia pro Gemini
omni voice text                    # Grava → revisa → imprime no terminal
```

---

## 🗄️ omni pg — PostgreSQL

Gerencie bancos PostgreSQL com comandos simples:

```bash
omni pg init && omni pg start      # Inicializa e sobe o servidor
omni pg create meuapp              # Cria um banco
omni pg shell                      # Abre o console psql
```

---

## 🚀 omni init — Templates de Projetos

Crie projetos pré-configurados em segundos:

```bash
cd my-app && omni init next         # Next.js + TypeScript + Tailwind
cd my-api && omni init express      # Express + TypeORM
cd backend && omni init nest        # NestJS + autenticação
```

| Template | Descrição |
|----------|-----------|
| `next` | Next.js com Turbopack, TypeScript, Tailwind, React Query, Zustand |
| `react` | React + Vite com estrutura moderna |
| `express` | Express API com TypeScript + TypeORM + migrations |
| `nest` | NestJS com TypeORM e autenticação JWT |

---

## 🔧 omni env

Gerencie variáveis de ambiente com segurança:

```bash
omni env set OPENAI_API_KEY        # Adiciona chave (input oculto)
omni env list                      # Lista variáveis
omni env export                    # Exporta para o shell atual
```

---

## 📖 Exemplos de Uso

```bash
# Instalar banco de dados
omni install db --postgresql --sqlite

# Instalar agentes de IA específicos
omni install ai --opencode --ollama --claude-code

# Ver ferramentas disponíveis
omni list ai

# Ver documentação de uma ferramenta
omni show ai --opencode

# Atualizar tudo
omni update core

# Reinstalar um módulo
omni reinstall shell

# Diagnóstico completo
omni doctor
```

---

## 🏗️ Estrutura do Projeto

```
omni/
├── core/
│   ├── bin/           # Binários (core, omni)
│   ├── cli/
│   │   ├── commands/  # Comandos CLI (install, list, show, etc.)
│   │   └── core.sh    # CLI principal
│   ├── modules/       # Orquestradores de módulos
│   ├── tools/         # Instaladores de ferramentas
│   │   ├── ai/        # 28 agentes de IA
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
export OMNI_DEBUG=1      # Logs de debug
```

### Diretórios

| Diretório | Descrição |
|-----------|-----------|
| `~/.local/share/omni-data/` | Dados persistentes das ferramentas |
| `~/.cache/omni/` | Logs e cache |
| `~/.config/omni/` | Configuração do usuário |

---

## 🔄 Atualizações Automáticas

O framework verifica atualizações a cada 24 horas em background.

```bash
omni update core     # Atualiza o framework
```

---

## 📄 Licença

MIT © israel marques

---

<p align="center">
  <a href="https://omni-catalyst.vercel.app">
    <img src="https://img.shields.io/badge/%F0%9F%8C%90%20Documenta%C3%A7%C3%A3o%20Completa-0078D4?style=for-the-badge" alt="Documentação">
  </a>
  <a href="https://github.com/israel676767/omni-site">
    <img src="https://img.shields.io/badge/%F0%9F%93%B1%20Site%20Repo-0078D4?style=for-the-badge" alt="Site Repo">
  </a>
</p>
