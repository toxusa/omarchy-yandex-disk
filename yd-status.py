#!/usr/bin/env python3
import re
import json
import os
import shutil
import subprocess


CONFIGURATION_ERRORS = (
    "option 'dir' is missing",
    "indicated directory does not exist",
    "oauth token hasn't been found",
)


def is_configuration_error(output):
    lowered = output.lower()
    return any(message in lowered for message in CONFIGURATION_ERRORS)


def parse_status(output):
    state_prefix = "Synchronization core status:"
    state = None
    recent_files = []
    reading_recent = False
    progress_percent = None
    progress_text = ""
    sync_dir = ""
    directory_prefix = "Path to Yandex.Disk directory:"

    for line in output.splitlines():
        if line.startswith("Sync progress:"):
            progress_text = line[len("Sync progress:"):].strip()
            match = re.search(
                r"\(\s*(\d+(?:\.\d+)?)\s*%\s*\)\s*$",
                progress_text,
            )
            if match:
                value = float(match.group(1))
                if 0 <= value <= 100:
                    progress_percent = value
        if line.startswith(state_prefix):
            state = line[len(state_prefix):].strip()

        if line.startswith(directory_prefix):
            value = line[len(directory_prefix):].strip()
            if len(value) >= 2 and value.startswith("'") and value.endswith("'"):
                sync_dir = value[1:-1]

        if line.strip() == "Last synchronized items:":
            reading_recent = True
            continue

        if reading_recent:
            item = line.strip()
            if not item:
                continue

            if item.startswith("file: '") and item.endswith("'"):
                recent_files.append(item[len("file: '"):-1])
            else:
                reading_recent = False

    result = {
        "recent_files": recent_files[:10],
        "progress_percent": progress_percent,
        "progress_text": progress_text,
        "sync_dir": sync_dir,
    }

    if state in {"idle", "busy", "index"}:
        result["state"] = state
    elif state is not None:
        result["state"] = "unknown"
        result["message"] = state or "Empty synchronization state"
    else:
        result["state"] = "unknown"
        result["message"] = output or "Empty status response"

    return result


def get_status():
    executable = shutil.which("yandex-disk")
    if executable is None:
        return {"state": "not_installed"}

    try:
        result = subprocess.run(
            [executable, "status"],
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            encoding="utf-8",
            errors="replace",
            timeout=10,
            env={**os.environ, "LC_ALL": "C"},
        )
    except subprocess.TimeoutExpired:
        return {"state": "error", "message": "Status request timed out"}
    except OSError as error:
        return {"state": "error", "message": str(error)}

    output = result.stdout.strip()

    if result.returncode == 1 and output == "Error: daemon not started":
        return {"state": "stopped"}

    if result.returncode != 0:
        if is_configuration_error(output):
            return {
                "state": "not_configured",
                "message": (
                    "Client is not configured. Run 'yandex-disk setup' to "
                    "choose a sync directory and sign in."
                ),
            }
        return {
            "state": "error",
            "message": output or f"Client exited with code {result.returncode}",
        }

    return parse_status(output)


if __name__ == "__main__":
    print(json.dumps(get_status(), ensure_ascii=False))
