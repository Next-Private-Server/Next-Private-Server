from __future__ import annotations

from pathlib import Path
import runpy
import sys


def find_repo_root(start: Path) -> Path:
    for folder in (start, *start.parents):
        debug_script = folder / "tools" / "debug_official_save_exporter.py"
        if debug_script.exists():
            return folder
    raise FileNotFoundError(
        "Could not find tools/debug_official_save_exporter.py above this file. "
        "Run this from inside the Launcher repo."
    )


def main() -> int:
    repo_root = find_repo_root(Path(__file__).resolve())
    debug_script = repo_root / "tools" / "debug_official_save_exporter.py"
    sys.argv[0] = str(debug_script)
    runpy.run_path(str(debug_script), run_name="__main__")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
