BeforeAll {
    $RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
}

Describe "Scheduled control report" {
    It "has scheduled control report workflow" {
        Test-Path (Join-Path $RepoRoot ".github/workflows/scheduled-project-control-report.yml") | Should -BeTrue
    }
}
