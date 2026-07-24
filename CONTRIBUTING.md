# Contribuindo com o Karnel Termux

## Código de Conduta

Seja respeitoso e construtivo. Projetos open source dependem de colaboração.

## Como Contribuir

### Reportar Bugs

Abra uma [issue](https://github.com/israelmarques1024-dotcom/karnel-termux/issues) com:

- Versão do Karnel (`karnel --version`)
- Passos para reproduzir
- Comportamento esperado vs real
- Logs de erro (`~/.cache/karnel/`)

### Sugerir Features

Abra uma issue com o prefixo `[feature]` descrevendo:

- O problema que resolve
- Como funcionaria
- Exemplos de uso

### Adicionar um Tool Installer

Cada ferramenta instalável segue esta estrutura:

```
karnel/tools/<module>/<tool-name>/
├── install.sh        # Script de instalação (obrigatório)
├── uninstall.sh      # Script de desinstalação (opcional)
└── README.md         # Documentação (opcional, mas recomendado)
```

O `install.sh` deve:

1. Detectar se já está instalado (`is_installed`)
2. Instalar dependências se necessário
3. Instalar o tool
4. Chamar `log success` ao final

Veja exemplos reais em `karnel/tools/security/template.sh`.

### Adicionar um Módulo

Módulos orquestradores ficam em `karnel/modules/<module>.sh`.

Eles importam `karnel/utils/*` e chamam os installers de `karnel/tools/<module>/`.

```bash
# Estrutura mínima de um módulo
install_<module>() {
    local tool="${1:-all}"
    case "$tool" in
        all)  install_tools "<module>" ;;
        tool1) source "$KARNEL_DIR/tools/<module>/tool1/install.sh" ;;
        *) log error "Tool '$tool' não encontrada no módulo <module>" ;;
    esac
}
```

### Criar um Plugin (para usuários)

```bash
karnel plugin create meu-plugin
cd "${XDG_DATA_HOME:-$HOME/.local/share}/karnel-data/plugins/meu-plugin"
# Edite karnel-plugin.json e adicione comandos em commands/
```

Estrutura:

```
meu-plugin/
├── karnel-plugin.json   # Manifesto obrigatório
├── LICENSE              # Licença obrigatória
└── commands/            # Somente comandos declarados no manifesto
    └── meu-comando.sh
```

Exemplo de `karnel-plugin.json`:

```json
{
  "schemaVersion": 1,
  "name": "meu-plugin",
  "version": "1.0.0",
  "description": "Faz algo incrível",
  "commands": ["meu-comando"],
  "minKarnelVersion": "4.11.6",
  "license": "MIT",
  "checksum": "sha256:<hash-do-payload-do-plugin>",
  "capabilities": []
}
```

Os nomes seguem `^[a-z][a-z0-9-]{0,62}$`; a versão e
`minKarnelVersion` seguem SemVer. `commands/meu-comando.sh` precisa declarar
`meu-comando_main()` com a chave de abertura na mesma linha. Campos
desconhecidos, arquivos de comando extras, qualquer symlink no payload e
colisões de comando são rejeitados.

Plugins são Bash executado com as permissões do usuário. `capabilities` é apenas
uma declaração informativa; não existe sandbox. Para instalar repositório que
não está no registry é obrigatório `karnel plugin install owner/repo --unsafe`
e confirmação interativa.

## Plugin Registry — Publicar seu Plugin

Quer que seu plugin apareça em `karnel plugin search`?

1. Crie um repositório GitHub com seu plugin
2. Adicione o arquivo `karnel-plugin.json` na raiz
3. Abra um PR adicionando seu repositório ao registry em:

   `https://github.com/israelmarques1024-dotcom/karnel-plugins`

Formato da entrada:

```json
{
  "name": "meu-plugin",
  "repo": "seu-user/meu-plugin",
  "ref": "main",
  "version": "1.0.0",
  "description": "Descrição curta",
  "commands": ["meu-comando"],
  "minKarnelVersion": "4.11.6",
  "license": "MIT",
  "checksum": "sha256:<hash-do-payload-do-plugin>",
  "capabilities": []
}
```

O registry valida schema, unicidade, SemVer, repositório acessível, licença,
manifesto, comandos e checksum. Consulte o README e a política de revisão do
[`karnel-plugins`](https://github.com/israelmarques1024-dotcom/karnel-plugins)
antes de abrir o PR.

## Pull Requests

1. Fork o repositório
2. Crie um branch descritivo: `feat/meu-recurso` ou `fix/meu-bug`
3. Faça commits pequenos e descritivos
4. Teste suas mudanças
5. Abra o PR para `main`

### Checklist do PR

- [ ] Testei manualmente
- [ ] Segue a estrutura de diretórios existente
- [ ] Usa `log success` / `log error` para feedback
- [ ] Não quebra funcionalidades existentes
- [ ] Atualizei o README se necessário

## Estrutura do Projeto

```
karnel/
├── karnel/
│   ├── bin/karnel              # Entrypoint
│   ├── cli/commands/           # Comandos do CLI
│   ├── modules/                # Orquestradores de módulo
│   ├── tools/                  # Installers de ferramentas
│   └── utils/                  # Utilitários compartilhados
├── install.sh                  # Instalação curl
├── package.json                # Publicação npm
├── scripts/                    # Scripts auxiliares
└── .github/                    # CI/CD e templates
```

## Ambiente de Desenvolvimento

```bash
git clone https://github.com/israelmarques1024-dotcom/karnel-termux.git
cd karnel-termux
chmod +x karnel/bin/karnel
export PATH="$PWD/karnel/bin:$PATH"
karnel doctor
```

## Dúvidas

Abra uma issue ou pergunte no [site oficial](https://karneltermux.vercel.app).
