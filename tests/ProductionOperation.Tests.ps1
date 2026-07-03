BeforeAll {
    $RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
}

Describe "Production operation dispatch" {
    It "has required files" {
        Test-Path (Join-Path $RepoRoot ".github/workflows/manual-production-operation.yml") | Should -BeTrue
        Test-Path (Join-Path $RepoRoot "scripts/common/Invoke-ProductionOperationTask.ps1") | Should -BeTrue
    }

    It "workflow is manually started and production scoped" {
        $workflow = Get-Content -Path (Join-Path $RepoRoot ".github/workflows/manual-production-operation.yml") -Raw

        $workflow | Should -Match "workflow_dispatch"
        $workflow | Should -Match "contents: write"
        $workflow | Should -Match "environment: production"
        $workflow | Should -Match "dry_run"
        $workflow | Should -Not -Match "environment: development"
    }

    It "script is constrained to named production mode" {
        $script = Get-Content -Path (Join-Path $RepoRoot "scripts/common/Invoke-ProductionOperationTask.ps1") -Raw

        $script | Should -Match "production"
        $script | Should -Match "production_change_enabled"
        $script | Should -Match "primary_external_endpoint"
        $script | Should -Match "GITHUB_ACTIONS"
        $script | Should -Not -Match "development_edit_enabled"
        $script | Should -Not -Match "staging_edit_enabled"
    }
}
