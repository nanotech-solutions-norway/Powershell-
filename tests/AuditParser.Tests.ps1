BeforeAll {
    $RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
}

Describe "Audit parser" {
    It "parses the workflow audit script" {
        $scriptText = Get-Content -Path (Join-Path $RepoRoot "scripts/governance/Test-WorkflowGovernance.ps1") -Raw
        { [scriptblock]::Create($scriptText) } | Should -Not -Throw
    }
}
