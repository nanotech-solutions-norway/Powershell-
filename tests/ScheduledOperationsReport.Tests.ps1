BeforeAll {
    $RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
}

Describe "Scheduled operations report" {
    It "has scheduled operations report workflow" {
        Test-Path (Join-Path $RepoRoot ".github/workflows/scheduled-project-operations-report.yml") | Should -BeTrue
    }

    It "runs health diagnostics and report conversion" {
        $content = Get-Content -Path (Join-Path $RepoRoot ".github/workflows/scheduled-project-operations-report.yml") -Raw
        $content | Should -Match "Invoke-ProjectHealthCheck.ps1"
        $content | Should -Match "Invoke-ProjectDiagnostics.ps1"
        $content | Should -Match "Convert-ProjectOperationsReport.ps1"
    }

    It "publishes scheduled operations artifacts" {
        $content = Get-Content -Path (Join-Path $RepoRoot ".github/workflows/scheduled-project-operations-report.yml") -Raw
        $content | Should -Match "scheduled-project-operations-raw-evidence"
        $content | Should -Match "scheduled-project-operations-report"
    }
}
