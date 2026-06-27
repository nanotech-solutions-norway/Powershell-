"""Collect sanitized Python control-plane diagnostics for GitHub Actions."""

from __future__ import annotations

import argparse
import json
import platform
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Collect Python diagnostics.")
    parser.add_argument(
        "--diagnostic-level",
        choices=("baseline", "dependencies", "repository"),
        default="baseline",
        help="Diagnostic detail level. No level prints secrets.",
    )
    parser.add_argument(
        "--output-dir",
        default="artifacts/python-debug",
        help="Directory for debug artifacts.",
    )
    return parser.parse_args()


def run_python_command(args: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [sys.executable, *args],
        check=False,
        capture_output=True,
        text=True,
    )


def write_text(path: Path, content: str) -> None:
    path.write_text(content, encoding="utf-8")


def collect_repo_structure(repo_root: Path) -> str:
    roots = [
        repo_root / "python",
        repo_root / ".github" / "workflows",
        repo_root / "docs",
    ]

    lines: list[str] = []
    for root in roots:
        if not root.exists():
            lines.append(f"MISSING {root.relative_to(repo_root)}")
            continue

        for path in sorted(root.rglob("*")):
            if path.is_file():
                relative = path.relative_to(repo_root)
                lines.append(str(relative))

    return "\n".join(lines) + "\n"


def build_summary(diagnostic_level: str) -> dict[str, Any]:
    return {
        "status": "success",
        "diagnostic_level": diagnostic_level,
        "created_at_utc": datetime.now(timezone.utc).isoformat(),
        "python_version": sys.version,
        "python_executable": sys.executable,
        "platform": platform.platform(),
        "secrets_policy": "environment variables and secrets are not printed",
        "production_writes": "out_of_scope",
    }


def main() -> int:
    args = parse_args()
    repo_root = Path.cwd().resolve()
    output_dir = (repo_root / args.output_dir).resolve()
    output_dir.mkdir(parents=True, exist_ok=True)

    write_text(output_dir / "python-version.txt", sys.version)
    pip_version = run_python_command(["-m", "pip", "--version"])
    write_text(output_dir / "pip-version.txt", pip_version.stdout + pip_version.stderr)

    if args.diagnostic_level in {"dependencies", "repository"}:
        pip_list = run_python_command(["-m", "pip", "list", "--format=json"])
        write_text(output_dir / "pip-list.json", pip_list.stdout or "[]")

    if args.diagnostic_level == "repository":
        write_text(output_dir / "repo-structure.txt", collect_repo_structure(repo_root))

    summary = build_summary(args.diagnostic_level)
    (output_dir / "debug-summary.json").write_text(
        json.dumps(summary, indent=2, sort_keys=True),
        encoding="utf-8",
    )

    print("Python debug diagnostics completed. Artifacts were written without printing secrets.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
