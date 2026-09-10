# Development

[Normal run](START.md) · [iPhone build](LOCAL_SETUP.md).
Commands run from the project root. Real recordings, `.local/`, keys,
certificates, and build artifacts never enter Git.

## Project and checks

`app/` — the phone app, `backend/` — audio intake and storage,
`scripts/dev-harness/` — local services, `web-local/` — the library and
the logo.

- `make test-library` — the library and the launcher.
- `make test-offline` — the local backend and services.
- `make test-transport-app` — the app and the analyzer; needs Flutter.

The last two suites are required before an iOS build. Physical recording
is verified separately: start and stop a recording on the CV1, then play
it in the library.

The installer uses Homebrew. Python 3.11.15 and dependencies are pinned
in `backend/.python-version` and `backend/pylock.macos.toml`, the
Firebase CLI in `package-lock.json`. Flutter, Xcode, and CocoaPods are
prepared per the [iPhone guide](LOCAL_SETUP.md);
`start.command --iphone-check` checks tools, signing, and the phone
without building. WhisperKit has `scripts/install-local-whisperkit.sh`;
engine selection is described in [LOCAL_STT.md](LOCAL_STT.md).
The Java check requires version 21 or newer; the iOS check rejects a
broken CocoaPods. Install output is saved to `.local/install.log`,
owner-only and outside Git. Homebrew prompts stay visible in the
terminal; key input is never recorded. Homebrew paths are detected
automatically. A separate Firebase cache can be set with
`FIREBASE_EMULATORS_PATH` before install and start. The install counts
as complete after all checks and the `.local/install.ready` marker.
Changing its inputs or interrupting preparation repeats it on the next
start.

Backend — `127.0.0.1:20000` (on the wifi transport it also listens on
the local network behind the pairing key), library — `127.0.0.1:20001`,
ngrok diagnostics — `127.0.0.1:16040`. Emulators and the library are
never exposed to the network or a tunnel. The backend requires the
pairing key except `/v1/health`; the Mac stores its hash. Deletion is
available through the local library; there is no new public route.

## iPhone build

Before installing, verify the commit, the configuration, the SHA-256 of
the executable, the signature, and entitlements. The exact path is
`app/build/ios/Profile-dev-iphoneos/Runner.app`; the copy in
`app/build/ios/iphoneos/Runner.app` may belong to another build.
A fresh project copy contains no prebuilt app.

With unchanged sources, dependencies, tools, and a valid signature, use
the verified artifact. Changing the server or address, or a USB failure,
needs no rebuild. An expired signing profile must be renewed. A clean
build is needed only after a relevant change of signing, native
dependencies, tools, or a confirmed intermediate-file problem.

## Speech models

WhisperKit 1.1.0 builds from Argmax commit
`1e2a163736dfa5a198e637ae44c114e1c6d5cc2d`, Swift Argument Parser 1.7.0
pinned by the upstream `Package.resolved`.
The [recipe](../scripts/dev-harness/whisperkit-models.json) pins
revisions and SHA-256 of the archive, the Core ML
large-v3-v20240930_626MB, the tokenizer, and the verification speech.
The runtime lives in `.local/whisperkit/`; `ready.json` appears after an
offline inference. The result key includes the model, language,
parameters, binary, and adapter version. The processor stores word
timestamps and their probability as the score; the network sandbox is
mandatory. The installer neither switches the current engine nor
installs Python ML dependencies.

WhisperX 3.8.6/CPU/float32/batch 1 uses a separate Python 3.12.14.
[Checksummed dependencies](../scripts/dev-harness/requirements-whisperx-macos.txt),
[WhisperX patches](../scripts/dev-harness/whisperx-local.patch), and
[model versions](../scripts/dev-harness/whisperx-models.json) are stored
in the repository. The installer places them in `.local/stt/`, verifies
transcription, and publishes `ready.json` only on success. File
completeness check: `bash scripts/install-local-stt.sh --check`.
Changing the environment version changes the transcript cache key; old
results are kept. The queue stores the chosen model and reports the
actually used environment version on retry.

Parakeet-MLX 0.5.2/GPU/FP32 and pyannote.audio 4.0.7 are also verified.
Parakeet used Python 3.14.6, Apple Silicon, and
[pinned dependencies](../scripts/dev-harness/requirements-parakeet-mlx-macos.txt).

`stt-engine.json` example for Parakeet:

```json
{
  "engine": "parakeet-mlx",
  "model": "mlx-community/parakeet-tdt-0.6b-v3",
  "language": "auto",
  "device": "gpu",
  "compute_type": "float32",
  "diarization_model": "none"
}
```

WhisperX and Parakeet support `python` and `library_path`. FFmpeg 7 for
standard WhisperX installs automatically. Its ASR, alignment, and NLTK
are pinned and loaded from local paths. Manual environments honor
`HF_HOME`, `HF_HUB_CACHE`, `TORCH_HOME`, and `NLTK_DATA`; their models,
including pyannote for speaker separation, are prepared separately.
`start.command --check` verifies the Mac services; ML readiness is
checked separately.

Queue and results: `.local/dev-harness/ngrok/services/local-transcripts/`.
After an error, up to three attempts run with 60- and 120-second pauses,
then a manual retry is needed. On emulator state loss it restores the
conversation from the saved JSON. After changing adapter code, wait for
processing to finish and restart it via `auto-transcribe-off` /
`auto-transcribe-on`.
