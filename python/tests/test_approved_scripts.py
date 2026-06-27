"""Guardrail tests for approved Python script execution."""

from __future__ import annotations

from pathlib import Path

import pytest

from python.tools.approved_scripts import (
    ApprovedScriptError,
    list_approved_scripts,
    resolve_approved_script,
)


def test_approved_script_registry_contains_sample_script() -> None:
    assert "hello_control_plane" in list_approved_scripts()


def test_resolve_approved_script_stays_under_scripts_directory() -> None:
    repo_root = Path.cwd()
    script_path = resolve_approved_script("hello_control_plane", repo_root=repo_root)

    assert script_path.name == "hello_control_plane.py"
    assert script_path.is_file()
    assert script_path.relative_to(repo_root / "python" / "scripts")


@pytest.mark.parametrize(
    "script_name",
    [
        "",
        "../hello_control_plane",
        "python/scripts/hello_control_plane.py",
        "hello_control_plane; echo unsafe",
        "unknown_script",
    ],
)
def test_unapproved_script_names_are_rejected(script_name: str) -> None:
    with pytest.raises(ApprovedScriptError):
        resolve_approved_script(script_name, repo_root=Path.cwd())


def test_approved_script_registry_has_no_path_tokens() -> None:
    for script_name in list_approved_scripts():
        assert "/" not in script_name
        assert "\\" not in script_name
        assert ".." not in script_name
