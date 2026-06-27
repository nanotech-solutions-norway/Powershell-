BeforeAll {
    $RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
}

Describe "Scheduled project health suite" {
    It "has the scheduled suite workflow" {
        Test-Path (Join-Path $RepoRoot ".github/workflows/scheduled-project-health-suite.yml") | Should -BeTrue
    }

    It "runs all supported project adapters" {
        $content = Get-Content -Path (Join-Path $RepoRoot ".github/workflows/scheduled-project-health-suite.yml") -Raw
        foreach ($project in @("atlas", "solarex", "domeneshop", "conta", "wix")) {
            $content | Should -Match $project
        }
    }

    It "creates summary and raw evidence artifacts" {
        $content = Get-Content -Path (Join-Path $RepoRoot ".github/workflows/scheduled-project-health-suite.yml") -Raw
        $content | Should -Match "Convert-ProjectHealthEvidenceSummary.ps1"
        $content | Should -Match "scheduled-project-health-suite-summary"
        $content | Should -Match "scheduled-project-health-suite-raw-evidence"
    }
}
