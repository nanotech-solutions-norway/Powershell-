BeforeAll {
    $RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
}

Describe "Control plane release phase" {
    It "has the release phase note" {
        Test-Path (Join-Path $RepoRoot "docs/CONTROL_PLANE_RELEASE_PHASE.md") | Should -BeTrue
    }
}
