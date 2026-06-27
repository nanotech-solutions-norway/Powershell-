BeforeAll {
    $RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
}

Describe "Evidence summary annotations" {
    It "emits non-blocking GitHub warning annotations" {
        $content = Get-Content -Path (Join-Path $RepoRoot "scripts/projects/Convert-ProjectHealthEvidenceSummary.ps1") -Raw
        $content | Should -Match "Write-ProjectHealthAnnotation"
        $content | Should -Match "::warning"
        $content | Should -Match "SuppressAnnotations"
    }
}
