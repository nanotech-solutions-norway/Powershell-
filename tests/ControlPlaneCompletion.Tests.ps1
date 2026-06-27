BeforeAll {
    $RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
}

Describe "Control plane completion report" {
    It "has the completion report" {
        Test-Path (Join-Path $RepoRoot "docs/CONTROL_PLANE_COMPLETION_REPORT.md") | Should -BeTrue
    }
}
