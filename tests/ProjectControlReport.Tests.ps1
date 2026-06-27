BeforeAll {
    $RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
}

Describe "Project control report" {
    It "has control report workflow and converter" {
        Test-Path (Join-Path $RepoRoot ".github/workflows/manual-project-control-report.yml") | Should -BeTrue
        Test-Path (Join-Path $RepoRoot "scripts/projects/Convert-ProjectControlReport.ps1") | Should -BeTrue
    }
}
