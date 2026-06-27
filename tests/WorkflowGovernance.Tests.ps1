BeforeAll {
    $RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
}

Describe "Workflow governance audit" {
    It "has governance audit script and workflow" {
        Test-Path (Join-Path $RepoRoot "scripts/governance/Test-WorkflowGovernance.ps1") | Should -BeTrue
        Test-Path (Join-Path $RepoRoot ".github/workflows/manual-workflow-governance-audit.yml") | Should -BeTrue
    }

    It "publishes a governance report artifact" {
        $content = Get-Content -Path (Join-Path $RepoRoot ".github/workflows/manual-workflow-governance-audit.yml") -Raw
        $content | Should -Match "workflow-governance-report"
        $content | Should -Match "contents: read"
        $content | Should -Match "actions: read"
    }

    It "checks for write posture risks" {
        $content = Get-Content -Path (Join-Path $RepoRoot "scripts/governance/Test-WorkflowGovernance.ps1") -Raw
        $content | Should -Match "contents_write"
        $content | Should -Match "actions_write"
        $content | Should -Match "write_tools_enabled"
    }
}
