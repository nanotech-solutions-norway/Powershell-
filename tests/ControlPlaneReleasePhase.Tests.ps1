BeforeAll {
    $RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
}

Describe "Control plane release phase" {
    It "has the release phase notes" {
        Test-Path (Join-Path $RepoRoot "docs/CONTROL_PLANE_RELEASE_PHASE.md") | Should -BeTrue
        Test-Path (Join-Path $RepoRoot "docs/PHASE6_CONTROL_PLANE_RELEASE_CLOSURE.md") | Should -BeTrue
    }

    It "keeps Phase 6 write boundaries explicit" {
        $phase6Path = Join-Path $RepoRoot "docs/PHASE6_CONTROL_PLANE_RELEASE_CLOSURE.md"
        $phase6 = Get-Content -Path $phase6Path -Raw

        $phase6 | Should -Match "production writes remain out of scope"
        $phase6 | Should -Match "deployment writes remain out of scope"
        $phase6 | Should -Match "future write gates require a separate approved phase"
    }
}
