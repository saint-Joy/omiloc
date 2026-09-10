# Running omiloc

You need an Apple Silicon Mac. For recording — a CV1 and the
[phone app](LOCAL_SETUP.md). The first install needs internet access.

## Install

In Terminal, fetch the project and run the preparation:

```bash
git clone https://github.com/saint-Joy/omiloc.git omiloc
cd omiloc
./start.command
```

If the Mac offers to install developer tools for Git, finish that install
and repeat the command. If the project is already downloaded, start with
`start.command`.

## First run

1. Open `start.command` with a double-click, or run `./start.command`
   in Terminal from the project folder.
2. The script installs missing dependencies and verifies them. On an
   error it says what to fix; Enter retries the check, `q` quits.
3. The framed box shows the **pairing key**. In the phone app, open
   "Local Mac" — the app finds this Mac over the shared Wi-Fi network on
   its own. Enter the key and check the connection.

The key is shown once — save it. The Mac keeps only its verification
hash. A repeat run reuses the saved settings. At the end you get a frame
with the `omiloc` command and the library address; after startup the
Terminal can be closed. The phone app and the
[speech models](LOCAL_STT.md) are installed separately.

The phone and the Mac must share one network. For recording away from
home there is an optional [ngrok transport](NGROK.md).

## Use

To record, run `start.command`. Connect the CV1 in the app and press the
CV1 button once to start, once more to finish a recording. Mute silences
the audio temporarily without ending the file. The Mac must stay awake.

To browse the archive, run **`omiloc`** from any Terminal folder. The
[library](http://127.0.0.1:20001/) opens — it is reachable only on this
Mac. Do not open `index.html` directly.

Pick a recording, play it, or click a phrase to jump to its timestamp.
Change the speed, search by date, source, and the opening words.
New recordings and finished transcripts appear on their own.

**Delete recording** removes the audio, the transcript, and the linked
conversation after confirmation. Deletion needs `start.command` running;
wait for transcription to finish. If the audio is duplicated, the shared
transcript stays until the last copy is deleted. Then pull the
conversation list down in the phone app to refresh it.

## If something goes wrong

The Mac preparation output is saved to `.local/install.log`.
Run the commands below from the project folder.

- `omiloc` not found: `./omiloc --install`, then open a new Terminal window.
- `start.command` does not open: `bash start.command`.
- Preparation stopped: run `start.command` again — it repeats the install.
  Manual dependency recovery: `bash scripts/install-local-mac.sh`.
- Check the Mac services: `./start.command --check`.
- Check tools, signing, and the phone: `./start.command --iphone-check`.
- Stop the services, keeping data: `bash scripts/local-mac.sh down`.
- Replace a lost key: after stopping, run `bash scripts/local-mac.sh rotate-key`,
  start `start.command`, and enter the new key on the phone.
- No connection to the phone: [pairing guide](NGROK.md).

After a Mac reboot, run `start.command` again for recording, or `omiloc`
for listening. [Current limitations](TEMPORARY_DISABLED_FEATURES.md).
