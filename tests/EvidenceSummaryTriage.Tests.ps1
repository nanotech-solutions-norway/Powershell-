BeforeAll {
    $RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
}

Describe "Evidence summary triage metadata" {
    It "contains run metadata and recommended actions" {
        $content = Get-Content -Path (Join-Path $RepoRoot "scripts/projects/Convert-ProjectHealthEvidenceSummary.ps1") -Raw
        $content | Should -Match "run_metadata"
        $content | Should -Match "recommended_action"
        $content | Should -Match "Get-RecommendedAction"
    }
}
