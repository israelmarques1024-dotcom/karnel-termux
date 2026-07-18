# Robin OSINT

Robin is an independent, AI-assisted dark-web OSINT project. Karnel installs a
tested Robin release, Tor, native Termux scientific packages, and a local
Streamlit interface.

Upstream project: https://github.com/apurvsinghgautam/robin

## Responsible Use

Use Robin only for lawful, authorized, and ethical research. Tor improves
connection privacy but does not guarantee anonymity. Robin automatically
retrieves web pages. Do not execute or open unknown files.

Queries, URLs, collected content, and summaries can be sent directly to the
configured LLM provider outside Tor. Third parties may process and retain that
data. Investigations are stored locally as plain JSON. Minimize personal data,
follow applicable laws and institutional policies, and independently verify AI
output before treating it as evidence.

The web interface is bound to `127.0.0.1`. Never expose port `8501` publicly.

## Install

```bash
karnel install osint --robin
karnel robin config
karnel robin doctor
karnel robin start
```

Open `http://127.0.0.1:8501` after the health check succeeds.

For an intentional non-interactive first start:

```bash
karnel robin start --accept-responsible-use
```

## Commands

| Command | Description |
| --- | --- |
| `karnel robin start` | Start Tor when needed and launch the local UI |
| `karnel robin stop` | Stop the managed Streamlit process |
| `karnel robin status` | Show installation, Tor, UI, config, and data status |
| `karnel robin config` | Show the protected configuration path and variables |
| `karnel robin doctor` | Run local dependency and service diagnostics |
| `karnel robin doctor --network` | Also verify an HTTP request through Tor |
| `karnel robin update` | Reconcile the installation with Karnel's pinned release |
| `karnel robin purge-data` | Permanently remove config and investigations after confirmation |

## Data Locations

Karnel separates executable code from persistent user data:

| Data | Location |
| --- | --- |
| Upstream source | `$KARNEL_TOOLS/osint/robin/app` |
| Python environment | `$KARNEL_TOOLS/osint/robin/.venv` |
| Provider configuration | `$KARNEL_CONFIG/robin/.env` |
| Saved investigations | `$KARNEL_DATA/robin/investigations` |
| Runtime log | `$KARNEL_LOGS/robin.log` |
| Installation log | `$KARNEL_CACHE/install_osint.log` |

Uninstall and reinstall preserve configuration and investigations. API keys and
investigations are intentionally excluded from ordinary Karnel backups. Use
`karnel robin purge-data` only when permanent deletion is intended.

## Provider Configuration

Supported variables include:

- `OPENAI_API_KEY`
- `ANTHROPIC_API_KEY`
- `GOOGLE_API_KEY`
- `OPENROUTER_API_KEY`
- `OPENROUTER_BASE_URL`
- `OLLAMA_BASE_URL`
- `LLAMA_CPP_BASE_URL`
- `CUSTOM_API_BASE_URL`
- `CUSTOM_API_KEY`
- `CUSTOM_API_MODEL`

Never commit or display secret values. Existing files are repaired to mode
`0600`; configuration directories use mode `0700`.

## Troubleshooting

Run `karnel robin doctor`. The default doctor is local and does not call an LLM
or consume provider credits. `--network` performs a small request through Tor.

Streamlit can take up to one minute to become healthy on a mobile device. The
start command waits for the health endpoint instead of relying only on a PID.
Android may still stop background processes because of battery optimization or
phantom-process limits.

Robin is third-party software distributed under its upstream license. Karnel is
not affiliated with the upstream author or any LLM provider.
