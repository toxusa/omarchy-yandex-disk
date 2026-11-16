# omarchy-yandex-disk

A minimal Yandex Disk integration for the Omarchy bar.

## Features

- Displays the daemon status in the bar.
- Refreshes the status every 5 seconds.
- Opens a popup with Start and Stop controls.
- Uses the official Yandex Disk CLI directly, without systemd integration.
- Uses the Omarchy theme foreground color.
- Displays status adapter messages and non-zero daemon control exit errors
  in the popup.
- Offers an Install button when the Yandex Disk CLI is not found.
- Opens an interactive AUR installer in a terminal using yay.

## Requirements

- Omarchy with shell plugin support.
- Python 3.
- The official `yandex-disk` CLI for status monitoring and daemon controls.

If the client is missing, the popup offers an Install button. Installation
requires `yay` and `omarchy-launch-terminal`.

The installer runs `yay -S --needed aur/yandex-disk` in a separate terminal,
without `--noconfirm`. Review the AUR build files and installation prompts
before proceeding.

Account authorization and initial client configuration must be completed
separately. The installer does not configure an account, start the daemon,
or change autostart settings.

## Installation

```bash
omarchy plugin add https://github.com/toxusa/omarchy-yandex-disk.git --enable
```

If the widget does not appear or still shows the previous version after an
update, restarting the shell helped during development:

```bash
omarchy restart shell
```

## Usage

Click the bar widget to open the popup.

- Start is available when the daemon is stopped.
- Stop is available when the daemon reports `idle`, `busy`, or `index`.
- Both controls are disabled while a control command is running.
- Status changes may take up to one polling interval to appear.

Stopping the daemon interrupts synchronization. Use Start to resume it.

When the CLI is not found, Start and Stop are replaced by an Install button.
Click Install to open the installer terminal. The installer asks for
confirmation before invoking yay and waits for Enter before closing.

Status polling continues while the installer is open. Once the CLI becomes
available, the widget returns to the normal status and control view.
Installing the package alone does not authorize or configure the client.

Status adapter messages and daemon control exit errors are displayed
separately in the popup. A control error is cleared before the next control
or installation attempt. A status message is replaced on each status
response and cleared when that response has no message.

Daemon control commands have a 15-second timeout. If a command is still
running, the widget sends SIGTERM, followed by SIGKILL after another
3 seconds if necessary.

A timeout message remains visible until the next control or installation
attempt. After the control process exits, the widget requests the actual
client status. A timeout does not necessarily mean that the requested
action had no effect.

The timeout applies only to Start and Stop commands, not to the interactive
installer.

## Status adapter

To query the status independently of the widget:

```bash
python3 yd-status.py
```

The adapter prints one JSON object with a `state` field:

- `not_installed`
- `stopped`
- `idle`
- `busy`
- `index`
- `unknown`
- `error`

The adapter only reads the status. It does not change client configuration.

## Current limitations

- Account authorization and initial client configuration must be completed
  separately.
- Installation requires yay and the Omarchy terminal launcher.
- Installation progress and results are shown in the terminal, not in the
  popup. The widget does not track the package manager's exit status.
- Daemon control errors show a generic message with an exit code or an
  abnormal termination message. Detailed command output is only logged.
- Failure to start a control process is not explicitly handled.
- Sync progress, storage quota, and recent files are not displayed.
- Each widget instance polls the client independently.
