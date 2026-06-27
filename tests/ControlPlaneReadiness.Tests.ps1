BeforeAll {
    $RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
}

Describe "Control plane readiness" {
    It "has readiness script and workflow" {
        Test-Path (Join-Path $RepoRoot "scripts/governance/Test-ControlPlaneReleaseReadiness.ps1") | Should -BeTrue
        Test-Path (Join-Path $RepoRoot ".github/workflows/manual-control-plane-readiness.yml") | Should -BeTrue
    }
}
