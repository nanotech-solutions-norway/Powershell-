BeforeAll {
    $RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
}

Describe "Control plane handoff" {
    It "has the handoff document" {
        Test-Path (Join-Path $RepoRoot "docs/CONTROL_PLANE_HANDOFF.md") | Should -BeTrue
    }
}
