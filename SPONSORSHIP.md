# Karnel-Termux Sponsorship

Karnel-Termux supports a separate, independent sponsored distribution. The package published on npm does not display sponsor messages automatically.

## User experience

- Sponsor messages are clearly labeled.
- At most one message is shown every 24 hours.
- Messages only appear after a successful interactive command.
- `karnel sponsor off` disables them immediately.
- Piped output, CI, updates, uninstall flows, help, and version commands never show sponsor messages.
- The system does not collect commands, files, shell history, device identifiers, or personal data.

## Install the sponsored distribution

```bash
curl -fsSL https://raw.githubusercontent.com/israelmarques1024-dotcom/karnel-termux/main/install-sponsored.sh | bash
```

Inspect or change the setting:

```bash
karnel sponsor status
karnel sponsor show
karnel sponsor off
karnel sponsor on
```

## Sponsor feed

The CLI reads a small HTTPS feed from:

```text
https://karneltermux.vercel.app/api/sponsors?format=tsv
```

Each active line uses four tab-separated fields:

```text
id<TAB>name<TAB>message<TAB>https_url
```

The CLI validates identifiers, field lengths, control characters, and HTTPS URLs before caching or displaying a message.

## Commercial model

The recommended first model is a fixed sponsorship fee for a defined period rather than behavioral advertising or per-user tracking. A sponsor agreement should define:

- start and end dates;
- approved name, message, and destination URL;
- prohibited categories and claims;
- payment terms;
- removal and refund conditions;
- whether aggregate, privacy-preserving reporting will be added later.

Because the project owner is under 18, contracts, invoicing, payment accounts, and tax responsibilities must be handled with a responsible adult and the applicable service requirements.

The npm Open Source Terms require users of npm Services to be at least 13 years old. Until the project owner meets that requirement, an eligible responsible adult must formally own and manage the npm account and publishing access.

## npm policy boundary

The npm package contains reusable sponsor infrastructure but does not enable or display sponsor messages. Automatic sponsor display is restricted to the independent installer, which writes an explicit `direct` installation marker. Unknown and npm installation sources remain disabled.
