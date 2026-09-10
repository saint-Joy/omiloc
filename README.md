# omiloc

A personal audio library on your Mac: Omi CV1 recordings, local
transcription, and a player that jumps to any phrase. The phone app
controls recording; audio travels over your home Wi-Fi straight to the
Mac. Storage and speech recognition never leave your machine.

Open **[start.command](start.command)** (double-click, or `./start.command`
from the project folder). It prepares the Mac, shows the pairing key for
the phone, and opens the library. [Setup guide](docs/START.md).

After setup, the **`omiloc`** command opens the library from any Terminal
folder. To receive new recordings, run `start.command`.

You need an Apple Silicon Mac, a CV1, and the phone app installed
separately. Prepare the [speech models](docs/LOCAL_STT.md) once.
The phone and the Mac pair over the local network — no accounts, no
tunnels. Remote access over ngrok stays available as an option
([details](docs/NGROK.md)).

[Phone pairing](docs/NGROK.md) · [Transcription](docs/LOCAL_STT.md) ·
[Limitations](docs/TEMPORARY_DISABLED_FEATURES.md) · [Development](docs/DEVELOPMENT.md)

Based on [Omi by Based Hardware](https://github.com/BasedHardware/omi).
[Origin](UPSTREAM.md) · [MIT](LICENSE) · [Logo](web-local/assets/omiloc.png)
