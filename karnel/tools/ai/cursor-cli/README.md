# Cursor CLI

Official Cursor AI coding agent adapted for Termux.

**Official:** https://cursor.com  
**Comando:** `cursor` / `cursor-agent`  
**Tipo:** Node.js app com Node.js empacotado (glibc)

## Instalação

```bash
karnel install ai --cursor-cli
```

## Gambiarra

O Cursor CLI oficial nao suporta Android. A solucao:
1. Baixa o tarball oficial de `downloads.cursor.com`
2. Usa `glibc` + `ld-linux-aarch64.so.1` para rodar o Node.js empacotado
3. Wrapper configurando `SSL_CERT_FILE`, `NODE_COMPILE_CACHE`, `HOST`, `BROWSER`

## OAuth

Se o OAuth travar no navegador:
```bash
BROWSER=echo cursor   # mostra URL de auth no terminal
```

## Gerenciamento

```bash
karnel update ai --cursor-cli
karnel uninstall ai --cursor-cli
```
