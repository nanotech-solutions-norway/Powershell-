BeforeAll {
    $RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
}

Describe "Diagnostics suite files" {
    It "has suite workflow and summary script" {
        Test-Path (Join-Path $RepoRoot ".github/workflows/manual-project-diagnostics-suite.yml") | Should -BeTrue
        Test-Path (Join-Path $RepoRoot "scripts/projects/Convert-ProjectDiagnosticsSummary.ps1") | Should -BeTrue
    }
}
