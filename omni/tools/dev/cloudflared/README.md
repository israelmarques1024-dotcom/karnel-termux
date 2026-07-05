# Cloudflared

Cloudflare Tunnel client for secure connections

**Package:** cloudflared  
**Author:** israel676767  
**Repository:** https://github.com/israel676767/omni  
**Official:** https://developers.cloudflare.com/cloudflare-one/connections/connect-networks  
**Type:** Networking tool (pkg)  
**License:** Apache 2.0 / Cloudflare License

## Description

Cloudflared creates secure tunnels from your local server to Cloudflare's edge network. It exposes local services to the internet through Cloudflare without opening firewall ports, providing DDoS protection and SSL/TLS encryption.

## Dependencies

- Installed via pkg

## Install

```bash
omni install dev --cloudflared
```

## Uninstall

```bash
omni uninstall dev --cloudflared
```

## Update

```bash
omni update dev --cloudflared
```

## Notes

- Command: `cloudflared`
- Requires Cloudflare account for tunnel setup
- Supports load balancing and failover

