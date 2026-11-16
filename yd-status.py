#!/usr/bin/env python3
import json
import os
import shutil
import subprocess


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
        return {
            "state": "error",
            "message": output or f"Client exited with code {result.returncode}",
        }

    prefix = "Synchronization core status:"
    for line in output.splitlines():
        if line.startswith(prefix):
            state = line[len(prefix):].strip()
            if state in {"idle", "busy", "index"}:
                return {"state": state}
            return {"state": "unknown", "message": state}

    return {
        "state": "unknown",
        "message": output or "Empty status response",
    }


print(json.dumps(get_status(), ensure_ascii=False))
