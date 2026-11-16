# omarchy-yandex-disk

A work-in-progress Yandex Disk integration for Omarchy.

## MVP scope

- Display the Yandex Disk daemon status.
- Start and stop the daemon using the official CLI.

This repository is not yet an installable Omarchy plugin.

## Current implementation

`yd-status.py` queries `yandex-disk status` and prints a JSON object.

Supported states:

- `not_installed`
- `stopped`
- `idle`
- `busy`
- `index`
- `unknown`
- `error`

## Requirements

- Python 3
- The official `yandex-disk` CLI, configured for your account

## Usage

```bash
python3 yd-status.py
```

The status script does not start or stop the daemon and does not modify
the Yandex Disk configuration.
