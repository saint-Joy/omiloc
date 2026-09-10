# Wi-Fi transport: local pairing without ngrok

Goal: the phone reaches the Mac over the home network. No ngrok account,
no domain, no authtoken. The paired-key boundary stays.

## Semantics (transport = "wifi", new default)

- `OMI_LOCAL_TRANSPORT=wifi` — offline providers required, like ngrok.
- `dev_bind_host` stays `127.0.0.1`: emulators, redis, library never leave
  loopback. Only the backend uvicorn binds `0.0.0.0`
  (`HarnessConfig.backend_bind_host` property; cli.py uvicorn line).
- Auth unchanged: `local_tunnel_enabled()` is true for {ngrok, wifi};
  every non-loopback request needs the Bearer pairing key (43 chars,
  SHA-256 at rest, `pairing.json`).
- Discovery: `dns-sd -R omiloc _omiloc._tcp local <backend_port>` runs as
  an owned harness service (`bonjour`, port=0 background record).
  TXT carries no secrets. The phone browses `_omiloc._tcp` and offers
  found Macs; the user types only the key.
- `configure`: wifi skips domain/token prompts entirely; it provisions the
  key once and shows a frame with `http://<lan-ip>:<port>` (display only,
  detected via UDP getsockname; no packets sent) plus the key.
- `edit-connection` is ngrok-only; wifi answers with a hint. `rotate-key`
  works for both.
- ngrok path stays intact behind `OMI_LOCAL_TRANSPORT=ngrok`.

## Files

- `scripts/dev-harness/dev_harness/config.py` — transport set, wifi rules,
  backend_bind_host, pairing env for {ngrok,wifi}.
- `scripts/dev-harness/dev_harness/cli.py` — uvicorn host, bonjour health.
- `backend/utils/local_transport_auth.py` — mode set.
- `scripts/dev-harness/dev_harness/local_mac.py` — wifi configure/up,
  lan_address, English messages.
- `scripts/local-mac.sh` — default transport wifi.
- Tests: test_local_transport_auth, test_local_mac, test_env_stage (if
  transport-coupled), app-side later.

## App side (after Android toolchain)

- `LocalMacSession`: accept `http://<private-ip>:<port>` next to
  https:443; `permits()` and `parseLocalTunnelUrl` gain the private-host
  branch (reuse `Env.isPrivateOrLoopbackHost`).
- Bonjour browse + one-field key entry on the Local Mac page.
- QR pairing: later; keys must stay off disk, so QR belongs to the
  configure-time terminal only.

## Out of scope now

Relay server, TLS on LAN (key boundary + private ranges carry v1),
iOS personal-team path (unchanged).
