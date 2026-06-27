"""Run one approved Python control-plane script.

This module is intended for GitHub Actions usage via:
    python -m python.tools.run_approved_script --script hello_control_plane

It intentionally does not accept arbitrary shell commands.
"""

from __future__ import annotations

import argparse
import json
import os
import runpy
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from python.tools.approved_scripts import ApprovedScriptError, resolve_approved_script


def _utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run an approved Python script.")
    parser.add_argument("--script", required=True, help="Approved script registry key.")
    parser.add_argument(
        "--target-environment",
        required=True,
        choices=("development",),
        help="Foundation phase only permits development execution.",
    )
    parser.add_argument(
        "--output-dir",
        default="artifacts/python-run",
        help="Directory for execution artifacts.",
    )
    return parser.parse_args()


def write_summary(output_dir: Path, payload: dict[str, Any]) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)
    summary_path = output_dir / "approved-script-run-summary.json"
    summary_path.write_text(json.dumps(payload, indent=2, sort_keys=True), encoding="utf-8")


def main() -> int:
    args = parse_args()
    repo_root = Path.cwd().resolve()
    output_dir = (repo_root / args.output_dir).resolve()
    output_dir.mkdir(parents=True, exist_ok=True)

    payload: dict[str, Any] = {
        "status": "started",
        "script": args.script,
        "target_environment": args.target_environment,
        "started_at_utc": _utc_now(),
        "repo": os.environ.get("GITHUB_REPOSITORY", "local-or-unknown"),
        "run_id": os.environ.get("GITHUB_RUN_ID", "local-or-unknown"),
        "production_writes": "out_of_scope",
    }

    try:
        script_path = resolve_approved_script(args.script, repo_root=repo_root)
        os.environ["PYTHON_CONTROL_PLANE_TARGET_ENVIRONMENT"] = args.target_environment
        os.environ["PYTHON_CONTROL_PLANE_OUTPUT_DIR"] = str(output_dir)
        os.environ["PYTHON_CONTROL_PLANE_SCRIPT"] = args.script

        try:
            runpy.run_path(str(script_path), run_name="__main__")
        except SystemExit as exc:
            if exc.code not in (0, None):
                raise RuntimeError(f"Approved script exited with status {exc.code}.") from exc

        payload["status"] = "success"
        payload["completed_at_utc"] = _utc_now()
        payload["script_path"] = str(script_path.relative_to(repo_root))
        write_summary(output_dir, payload)
        print(f"Approved Python script completed: {args.script}")
        return 0

    except ApprovedScriptError as exc:
        payload["status"] = "rejected"
        payload["completed_at_utc"] = _utc_now()
        payload["error"] = str(exc)
        write_summary(output_dir, payload)
        print(f"Approved Python script rejected: {exc}")
        return 2

    except Exception as exc:  # noqa: BLE001 - write controlled diagnostic artifact.
        payload["status"] = "failed"
        payload["completed_at_utc"] = _utc_now()
        payload["error_type"] = type(exc).__name__
        payload["error"] = str(exc)
        write_summary(output_dir, payload)
        print(f"Approved Python script failed: {type(exc).__name__}: {exc}")
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
