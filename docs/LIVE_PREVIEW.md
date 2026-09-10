# Experimental live preview on the Mac

The existing app accepts a JSON array of segments on `/v4/listen`. One
`id` per live session lets the whole draft text be replaced, including
corrections and contractions, without duplicates. Mac-only changes need
no iOS build. The home screen keeps the original Omi interface; the text
opens by tapping the recording card. There is no temporary "Transcript"
button.

The CV1 sends Opus; the backend decodes it to PCM16 little-endian, mono,
16 kHz. The phone microphone sends PCM16. A copy of the PCM goes over
the local WebSocket `/asr`; the WAV is saved by the existing handler.
Live text stays in memory; the finished WAV is still processed by the
selected final WhisperKit. The current experimental ASR is Core ML
Parakeet TDT v3 INT8 via FluidAudio. New tokens of each window are
appended to the accumulated text, and the app receives the whole updated
draft under the same segment ID. Low confidence in a new window does not
erase earlier phrases. This text does not replace the final WhisperKit
transcript.

## Prepared environment

Requires an installed FluidAudio v0.15.6, the local
`FluidInference/parakeet-tdt-0.6b-v3-coreml` model, and a built
`ParakeetWorker.swift`. The INT8 encoder, `cpuAndNeuralEngine`, and
automatic language without a hint are used. The stock
`SlidingWindowAsrManager.default` processes windows sequentially:
11 seconds of new audio with 2 seconds of context on each side. The
batch parameters `parallelChunkConcurrency` and `melChunkContext` are
not used on this path. Models load once from verified local files; each
new session gets separate state. There are no network downloads; the
worker's network is forbidden by the system sandbox policy. Swapping is
not a stop criterion.

From the `scripts/` folder, run with the prepared Python:

```bash
"$BACKEND_PYTHON" -m local_live_preview.serve_parakeet \
  --worker "$PARAKEET_WORKER" \
  --model-dir "$PARAKEET_MODEL_DIR" \
  --inference-lock ../.local/dev-harness/ngrok/services/local-transcripts/.lock \
  --port 18090
```

The variables point to the existing backend Python, the built worker,
and the `parakeet-tdt-0.6b-v3` model folder. Prepared components are
reused; the WLK code and its model are kept for a separate explicit
return. The lock file must belong to the same local backend instance
that runs the final transcription. Wait for `model_ready`;
`http://127.0.0.1:18090/health` carries only technical indicators.

When starting the backend, pass
`OMI_LOCAL_LIVE_PREVIEW_URL=ws://127.0.0.1:18090/asr`.
Restart only the backend owned by this instance, after the current
recording's Stop. An already-running process does not pick up the new
variable. Without the variable, the preview is off. This is a separate
experimental run; `start.command` does not manage the live process yet.

## Verifying on the phone

Start a recording with a single press of the physical CV1 button, then
tap the recording card in the app. Speak for 30–60 seconds with a pause.
The first text is expected in about 13 seconds, later updates every
11 seconds. Check that new phrases are appended and earlier ones stay.
Press the CV1 button again and check the WAV and the final text in the
library.

For a separate phone-microphone trial, disconnect the Omi, keep the Mac
link, and keep Transcribe Later off. The original bottom "+" button
starts the microphone and opens the stock recording screen; a long press
shows the menu. The local capture controller forbids starting the phone
while an Omi is connected; switching sources during a recording is out
of scope. Without a network the stock phone fallback can record locally,
but delivering such recordings into this library is not wired up yet.

On Stop the phone closes `/v4/listen` immediately; the backend sends EOF
to Parakeet separately and ends the session. Text remaining after Stop
may not reach the screen. The next session gets a new segment and empty
recognition context. Live uses one nominal speaker; its timestamps are
not final. Early tokens are kept without later revision. This is
windowed experimental output, not word-level updating; human quality
assessment is still needed.

One recording is transcribed at a time. If live or final transcription
is busy, the preview is unavailable for a new connection; WAV saving
continues. After an `/asr` failure there is no reconnect within the
recording. Transport buffer limits and completion timeouts protect the
recording from a hung preview and are not recognition quality criteria.
Audio and text are never written to live logs.
