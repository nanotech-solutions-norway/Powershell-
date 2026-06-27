BeforeAll {
    $RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
}

Describe "Scheduled audit workflow" {
    It "has the scheduled audit workflow file" {
        Test-Path (Join-Path $RepoRoot ".github/workflows/scheduled-workflow-governance-audit.yml") | Should -BeTrue
    }
}
