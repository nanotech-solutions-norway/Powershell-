BeforeAll {
    $RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
}

Describe "Evidence summary output" {
    It "contains job summary support" {
        $content = Get-Content -Path (Join-Path $RepoRoot "scripts/projects/Convert-ProjectHealthEvidenceSummary.ps1") -Raw
        $content | Should -Match "GITHUB_STEP_SUMMARY"
    }
}
