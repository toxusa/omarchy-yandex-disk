# omarchy-yandex-disk

A minimal Yandex Disk integration for the Omarchy bar.

## Features

- Displays the daemon status in the bar.
- Refreshes the status every 5 seconds.
- Opens a popup with Start and Stop controls.
- Uses the official Yandex Disk CLI directly, without systemd integration.
- Uses the Omarchy theme foreground color.

## Requirements

- Omarchy with shell plugin support.
- Python 3.
- The official `yandex-disk` CLI, installed and configured.

On Arch Linux, the client is available as `yandex-disk` in the AUR.

Automatic client installation and initial account setup are not implemented.

## Installation

```bash
omarchy plugin add [https://github.com/toxusa/omarchy-yandex-disk.git](https://github.com/toxusa/omarchy-yandex-disk.git) --enable
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

- Client installation and authorization must be completed separately.
- Control command output is logged, but command errors are not yet shown
  in the popup.
- Sync progress, storage quota, and recent files are not displayed.
- Each widget instance polls the client independently.
