"""Minimal approved Python script for the control-plane foundation."""

from __future__ import annotations

import json
import os
from datetime import datetime, timezone
from pathlib import Path


def build_payload() -> dict[str, str]:
    target_environment = os.environ.get(
        "PYTHON_CONTROL_PLANE_TARGET_ENVIRONMENT",
        "development",
    )

    if target_environment != "development":
        raise RuntimeError("Foundation phase only permits development execution.")

    return {
        "status": "success",
        "script": "hello_control_plane",
        "target_environment": target_environment,
        "created_at_utc": datetime.now(timezone.utc).isoformat(),
        "execution_model": "GitHub Actions orchestrated by ChatGPT",
        "production_writes": "out_of_scope",
    }


def main() -> int:
    output_dir = Path(
        os.environ.get("PYTHON_CONTROL_PLANE_OUTPUT_DIR", "artifacts/python-run")
    )
    output_dir.mkdir(parents=True, exist_ok=True)

    payload = build_payload()
    output_path = output_dir / "hello-control-plane-output.json"
    output_path.write_text(
        json.dumps(payload, indent=2, sort_keys=True),
        encoding="utf-8",
    )

    print("hello_control_plane completed in development mode.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
