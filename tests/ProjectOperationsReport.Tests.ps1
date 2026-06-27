BeforeAll {
    $RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
}

Describe "Project operations report" {
    It "has operations report workflow and script" {
        Test-Path (Join-Path $RepoRoot ".github/workflows/manual-project-operations-report.yml") | Should -BeTrue
        Test-Path (Join-Path $RepoRoot "scripts/projects/Convert-ProjectOperationsReport.ps1") | Should -BeTrue
    }

    It "runs health and diagnostics in one workflow" {
        $content = Get-Content -Path (Join-Path $RepoRoot ".github/workflows/manual-project-operations-report.yml") -Raw
        $content | Should -Match "Invoke-ProjectHealthCheck.ps1"
        $content | Should -Match "Invoke-ProjectDiagnostics.ps1"
        $content | Should -Match "Convert-ProjectOperationsReport.ps1"
    }
}
