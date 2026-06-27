"""Approved-script registry for the Python control plane.

The manual execution workflow must only call scripts through this registry.
Do not replace this with arbitrary shell command input.
"""

from __future__ import annotations

from pathlib import Path

APPROVED_SCRIPTS: dict[str, str] = {
    "hello_control_plane": "python/scripts/hello_control_plane.py",
}


class ApprovedScriptError(ValueError):
    """Raised when a script is not approved for controlled execution."""


def list_approved_scripts() -> tuple[str, ...]:
    """Return approved script names in stable order."""

    return tuple(sorted(APPROVED_SCRIPTS))


def resolve_approved_script(script_name: str, repo_root: Path | None = None) -> Path:
    """Resolve an approved script name to a safe repository-local path.

    Args:
        script_name: Name selected from the workflow_dispatch allowlist.
        repo_root: Repository root. Defaults to the current working directory.

    Returns:
        Absolute path to the approved script.

    Raises:
        ApprovedScriptError: If the script is unknown, unsafe, outside the
            approved scripts directory, or missing.
    """

    if not script_name or any(token in script_name for token in ("/", "\\", "..")):
        message = "Unsafe script name. Use an approved registry key only."
        raise ApprovedScriptError(message)

    if script_name not in APPROVED_SCRIPTS:
        approved = ", ".join(list_approved_scripts())
        message = f"Script is not approved. Approved scripts: {approved}"
        raise ApprovedScriptError(message)

    root = (repo_root or Path.cwd()).resolve()
    scripts_dir = (root / "python" / "scripts").resolve()
    script_path = (root / APPROVED_SCRIPTS[script_name]).resolve()

    try:
        script_path.relative_to(scripts_dir)
    except ValueError as exc:
        message = "Approved script path escaped python/scripts."
        raise ApprovedScriptError(message) from exc

    if not script_path.is_file():
        raise ApprovedScriptError(f"Approved script file is missing: {script_path}")

    return script_path
