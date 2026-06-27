BeforeAll {
    $RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
}

Describe "Scheduled diagnostics suite files" {
    It "has scheduled diagnostics suite workflow" {
        Test-Path (Join-Path $RepoRoot ".github/workflows/scheduled-project-diagnostics-suite.yml") | Should -BeTrue
    }

    It "publishes scheduled diagnostics artifacts" {
        $content = Get-Content -Path (Join-Path $RepoRoot ".github/workflows/scheduled-project-diagnostics-suite.yml") -Raw
        $content | Should -Match "scheduled-project-diagnostics-suite-raw-evidence"
        $content | Should -Match "scheduled-project-diagnostics-suite-summary"
    }
}
