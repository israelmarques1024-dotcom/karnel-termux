# Hugging Face CLI

Official `hf` command-line client for the Hugging Face Hub, installed in an
isolated Python environment so it does not modify the user's global packages.

## Install

```bash
karnel install ai --hugging-face
hf auth login
hf auth whoami
```

Common commands:

```bash
hf models ls --search qwen --limit 10
hf download Cactus-Compute/needle
hf cache ls
```

Karnel stores the managed environment under
`~/.local/share/karnel-data/hugging-face`. Uninstalling removes only that
environment and the Karnel-owned `hf` command. Credentials and downloaded
models under `~/.cache/huggingface` are preserved.

The optional Xet accelerator is disabled because it does not publish an
Android wheel. Downloads use the standard Hugging Face HTTP transport instead.

Do not put Hugging Face tokens in shell history, repositories, screenshots, or
issue reports. Prefer the interactive `hf auth login` flow or the `HF_TOKEN`
environment variable.

Official documentation: <https://huggingface.co/docs/huggingface_hub/guides/cli>
