#!/usr/bin/env python3
import json
import os
from pathlib import Path
import stat
import subprocess
import sys
import time


def get_stats(directory):
    root = Path(os.path.abspath(directory))
    if not root.is_dir():
        return {"state": "error", "message": "Sync directory is unavailable"}

    deadline = time.monotonic() + 30
    pending = [root]
    file_count = 0

    try:
        while pending:
            if time.monotonic() >= deadline:
                raise TimeoutError("Directory scan timed out")

            current = pending.pop()
            with os.scandir(current) as entries:
                for entry in entries:
                    if time.monotonic() >= deadline:
                        raise TimeoutError("Directory scan timed out")

                    if current == root and entry.name == ".sync":
                        continue

                    mode = entry.stat(follow_symlinks=False).st_mode
                    if stat.S_ISDIR(mode):
                        pending.append(Path(entry.path))
                    elif stat.S_ISREG(mode):
                        file_count += 1

        remaining = deadline - time.monotonic()
        if remaining <= 0:
            raise TimeoutError("Directory scan timed out")

        result = subprocess.run(
            [
                "du",
                "--summarize",
                "--block-size=1",
                "--exclude=./.sync",
                "--",
                ".",
            ],
            cwd=root,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            encoding="utf-8",
            errors="replace",
            timeout=remaining,
            env={**os.environ, "LC_ALL": "C"},
        )

        if result.returncode != 0:
            return {
                "state": "error",
                "message": result.stderr.strip() or "Disk usage query failed",
            }

        disk_bytes = int(result.stdout.split("\t", 1)[0].strip())

        return {
            "state": "ok",
            "sync_dir": str(root),
            "file_count": file_count,
            "disk_bytes": disk_bytes,
        }
    except (TimeoutError, subprocess.TimeoutExpired):
        return {"state": "error", "message": "Directory scan timed out"}
    except (OSError, ValueError) as error:
        return {"state": "error", "message": str(error)}


if __name__ == "__main__":
    if len(sys.argv) != 2:
        response = {
            "state": "error",
            "message": "Expected one sync directory argument",
        }
    else:
        response = get_stats(sys.argv[1])

    print(json.dumps(response, ensure_ascii=False))
