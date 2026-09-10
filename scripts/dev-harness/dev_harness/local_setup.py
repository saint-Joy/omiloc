"""Short terminal UX over the existing checked, owned Mac lifecycle."""

import contextlib
import io
import os
import shutil
import sys
import webbrowser

from . import cli, config, local_launcher, local_library, local_stt_watch


class SetupError(ValueError):
    pass


def frame(title, lines):
    width = max(len(title), *(len(line) for line in lines)) + 4
    border = '─' * width
    return '\n'.join(['┌' + border + '┐', '│  ' + title.ljust(width - 2) + '│',
                      '├' + border + '┤', *['│  ' + line.ljust(width - 2) + '│' for line in lines],
                      '└' + border + '┘'])


def show_frame(title, lines):
    output = frame(title, lines)
    if sys.stdout.isatty() and 'NO_COLOR' not in os.environ and os.environ.get('TERM') != 'dumb':
        output = '\033[1m' + output + '\033[0m'
    print(output)


def check(cfg):
    if cfg.local_transport == 'ngrok' and not shutil.which('ngrok'):
        raise SetupError('ngrok is missing. Run ./start.command to prepare the Mac.')
    # Capture diagnostic chatter in memory; credentials are never provisioned here.
    with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
        missing, _warnings = cli.prerequisite_report(cfg)
    if missing:
        raise SetupError('Dependency check failed. Diagnostics: bash scripts/local-mac.sh check')
    if not all((cfg.repo_root / 'web-local' / f).is_file() for f in ('index.html', 'style.css', 'app.js', 'player.mjs')):
        raise SetupError('Library page files are missing. Restore the project copy.')
    try:
        local_launcher.install_plan(cfg.repo_root)
    except local_launcher.LauncherError as error:
        raise SetupError(str(error)) from error
    return 0


def run(cfg, *, open_browser=True):
    from . import local_mac

    if not sys.stdin.isatty() or not sys.stdout.isatty():
        raise SetupError('Run ./start.command in a local Terminal.')
    print('Checking readiness…', flush=True)
    check(cfg)
    local_launcher.install(cfg.repo_root)
    cfg = config.load_config(cfg.repo_root, create_layout=True)
    # Configure remains outside redirected output: key provisioning requires a TTY.
    local_mac.configure(cfg)
    print('Starting services…', flush=True)
    with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
        if local_mac.up(cfg):
            raise SetupError('Startup stopped. Diagnostics: bash scripts/local-mac.sh check')
        local_library.start(cfg)
    print()
    print('Mac services are running. You can close this terminal.')
    show_frame('OPEN THE LIBRARY', ['omiloc', local_library.url(cfg)])
    print('Phone app: docs/LOCAL_SETUP.md')
    if local_stt_watch.worker_ready(cfg):
        print('New recordings are transcribed on their own.')
    else:
        print('For automatic transcription: docs/LOCAL_STT.md')
    print('To stop: bash scripts/local-mac.sh down')
    if open_browser:
        webbrowser.open(local_library.url(cfg))
    return 0
