# Transcribing recordings

Text is produced on the Mac after a recording ends. Ambiguous spots can
be replayed by timestamp in `omiloc`. Changing the engine does not
require reinstalling the phone app.

A separate experimental draft-text feed during recording is described in
[Live preview](LIVE_PREVIEW.md); it keeps the current final WAV
processing intact.

## WhisperKit

The chosen profile is **large-v3-turbo**, Core ML variant
`openai_whisper-large-v3-v20240930_626MB`; the audio encoder and text
decoder use `cpuAndNeuralEngine`.

The earlier experimental model speed/quality reports were outdated and
removed on September 9, 2026. This profile's quality and speed are being
evaluated anew.

After preparing the Mac with `start.command`, run from the project folder:

```bash
bash scripts/install-local-whisperkit.sh
```

Requirements: Apple Silicon, macOS 14 or newer, Xcode with Swift 5.10 or
newer, internet for the install, and at least 4 GiB free. The installer
builds WhisperKit 1.1.0 and downloads about 630 MB: the compressed
large-v3-turbo and the tokenizer. No Hugging Face account is needed.
Files and checksums are pinned in the repository. The first run can take
several minutes while Core ML prepares the model. Readiness is verified
on synthetic timed speech with the network forbidden.

The environment lives in `.local/whisperkit/`. If interrupted, repeat the
command: verified downloads and a matching build are reused. Compiler
errors land in `.local/whisperkit/build.log`. To check finished files
without building: `bash scripts/install-local-whisperkit.sh --check`.

The installer prepares the engine apart from live processing. If
processing is already on, wait for the current recording and
transcription to finish, then run:

```bash
bash scripts/local-mac.sh auto-transcribe-off
```

Save to `.local/dev-harness/ngrok/stt-engine.json`:

```json
{
  "engine": "whisperkit",
  "model": "openai_whisper-large-v3-v20240930_626MB",
  "language": "auto",
  "diarization_model": "none"
}
```

Then enable processing:

```bash
bash scripts/local-mac.sh auto-transcribe-on
```

WhisperKit reads prepared local model files; the network is forbidden for
every transcription process. The Core ML profile is CPU plus Neural
Engine, one task at a time. Segments and words get timestamps and a
single speaker `SPEAKER_00`. Hypotheses beyond the source audio boundary
are dropped. For a word crossing the end of the recording, only the
interval inside the WAV is kept; preceding speech is preserved.
`"language": "auto"` detects the recording language. Forcing
`"language": "ru"` can produce Russian text even for English speech; use
it only for recordings known to be Russian.

New recordings are processed on their own. Text appears in the library;
on the phone, refresh the list and open "Local recording". The Mac must
stay awake. Recordings that existed before processing was first enabled
must be submitted by hand. Old transcripts are kept; switching engines
does not re-transcribe the archive by itself. Tasks already started keep
their chosen engine on retry. If WhisperKit finds no speech, the library
shows "No speech detected". The WAV stays playable; the empty result is
recorded without creating a text entry or retrying.

| Action | Command from the project folder |
|---|---|
| Check processing | `bash scripts/local-mac.sh transcription-status` |
| Turn off, keeping recordings | `bash scripts/local-mac.sh auto-transcribe-off` |
| Process a file or retry after an error | `bash scripts/local-mac.sh transcribe "/path/to/recording.wav"` |

WAV PCM16, mono, 16 kHz is expected. A repeat with the same file and
profile reuses the saved result. After a Mac reboot, run `start.command`
again.

## Other prepared engines

WhisperX and Parakeet remain available for old tasks and explicit
selection. For WhisperX the previous installer is
`bash scripts/install-local-stt.sh`; it prepares
large-v3-turbo/ru/CPU/float32 without speaker separation in `.local/stt/`.
The earlier manual Python environment and its models are not removed by
the WhisperKit install.

[WhisperX and Parakeet parameters, environment requirements](DEVELOPMENT.md#speech-models)
