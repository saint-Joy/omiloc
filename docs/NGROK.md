# Pairing the phone with the Mac

By default the phone talks to the Mac over the shared Wi-Fi network:
the Mac advertises itself via Bonjour, the app finds it, and only the
pairing key is entered by hand. No accounts, no tunnels; audio never
leaves your network. This page covers connection checks and the optional
ngrok transport for recording away from home.

## Wi-Fi (default)

1. Run `start.command`. The framed box shows the LAN address and the
   pairing key (shown once — save it).
2. In the phone app, open "Local Mac", pick the discovered Mac (or enter
   the shown address), and enter the key.

## If there is no connection

- Make sure the Mac is on, awake, and `start.command` is running.
- The phone and the Mac must be on the same network; guest Wi-Fi and
  client isolation break discovery.
- Check the key under "Local Mac" on the phone.
- Open `http://<address>/v1/health`: `{"status":"ok"}` means the server
  is reachable. The key is verified separately by the button in the app.
- Service checks from the project folder: `bash scripts/local-mac.sh status`,
  more detail with `bash scripts/local-mac.sh check`.

## Optional: ngrok for remote access

Ngrok gives the Mac a permanent HTTPS address reachable from mobile
networks. Audio passes through ngrok; storage stays on the Mac.

1. [Create an ngrok account](https://dashboard.ngrok.com/signup) and
   finish its verification steps.
2. Under [Domains](https://dashboard.ngrok.com/domains), take the **dev
   domain** the account assigns. The free plan includes exactly one such
   address; custom names need a paid plan.
3. Open [Your Authtoken](https://dashboard.ngrok.com/get-started/your-authtoken)
   and copy the token value only.
4. Start with `OMI_LOCAL_TRANSPORT=ngrok ./start.command`: it asks for
   the HTTPS address (`https://your-domain.ngrok-free.app`) and the
   authtoken. Use the domain and token of one account.
5. On the phone, enter the domain and the pairing key under "Local Mac".

The pairing key differs from the ngrok authtoken. Do not share either.
The free plan has [traffic and request limits](https://ngrok.com/docs/pricing-limits/free-plan-limits);
when exhausted, transfer stops until the limit resets or the plan changes.

## Changing settings

Stop the services first. From the project folder:

```bash
bash scripts/local-mac.sh down
bash scripts/local-mac.sh edit-connection   # ngrok transport only
./start.command
```

`edit-connection` changes the ngrok address or authtoken, keeping the
pairing key. After changing the address, update it on the phone; no app
reinstall is needed. For a lost key use `rotate-key` instead, and enter
the new key on the phone.

Separate commands for manual install and start: `bash scripts/local-mac.sh install`,
then `configure` and `up`. For normal use, [start.command](START.md) is enough.

[Transcription](LOCAL_STT.md) · [Phone app install](LOCAL_SETUP.md) ·
[Technical checks](DEVELOPMENT.md)
