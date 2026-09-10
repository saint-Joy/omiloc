#!/usr/bin/env bash
# One terminal entrypoint for the Mac services and local web library.
set -euo pipefail
umask 077
cd "$(dirname "$0")"

if [[ "${1:-}" == --help ]]; then
  printf 'omiloc — Mac launcher\n\n  ./start.command                 Prepare and start\n  ./start.command --check         Check the Mac services\n  ./start.command --iphone-check  Check iPhone install readiness\n\nDetails: docs/START.md\n'
  exit 0
fi
if [[ "${1:-}" != '' && "${1:-}" != --check && "${1:-}" != --iphone-check ]]; then
  echo 'Available commands: ./start.command --help' >&2
  exit 1
fi
source scripts/macos-runtime.sh
omi_require_apple_silicon "$PWD/start.command" "$@"
for input in backend/.python-version backend/pylock.macos.toml package.json package-lock.json firebase.json web-local/index.html; do
  [[ -s "$input" ]] || { echo "Missing project file: $input" >&2; exit 1; }
done
omi_macos_path
if [[ "${1:-}" == --iphone-check ]]; then
  cd app
  exec bash setup.sh ios personal --check
fi
if [[ "${1:-}" == --check ]]; then
  exec bash scripts/local-mac.sh setup-check
fi
if [[ ! -t 0 || ! -t 1 ]]; then
  echo 'Open start.command in Terminal. Keys are shown only in a local terminal.' >&2
  exit 1
fi
printf '\nomiloc\n\n'
needs_install=0
omi_install_ready || needs_install=1
[[ -x backend/.venv/bin/python && -x node_modules/.bin/firebase ]] || needs_install=1
for tool in uv node java redis-server ffmpeg ngrok jq; do
  command -v "$tool" >/dev/null 2>&1 || needs_install=1
done
omi_java_ready || needs_install=1
if command -v brew >/dev/null 2>&1; then
  brew list --versions opus >/dev/null 2>&1 || needs_install=1
else
  needs_install=1
fi
if [[ "$needs_install" == 1 ]]; then
  echo 'Preparing missing dependencies. The first run can take several minutes.'
  echo 'If the system asks for your Mac password, enter it in this terminal.'
  until bash scripts/install-local-mac.sh --quiet; do
    printf '\nPreparation stopped.\n' >&2
    [[ ! -f .local/install.log ]] || echo 'Log: .local/install.log' >&2
    echo 'Fix the cause per the hint above. Details: docs/START.md' >&2
    read -r -p 'Enter — retry the check and install; q — quit: ' retry || exit 1
    [[ "$retry" != q && "$retry" != Q ]] || exit 1
    omi_macos_path
  done
fi
exec bash scripts/local-mac.sh start
