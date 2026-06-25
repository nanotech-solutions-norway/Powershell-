BeforeAll {
    $RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
}

Describe "Atlas AI PowerShell repository baseline" {
    It "has required documentation files" {
        Test-Path (Join-Path $RepoRoot "README.md") | Should -BeTrue
        Test-Path (Join-Path $RepoRoot "ATLAS_GITHUB_POWERSHELL_BLUEPRINT_REPORT.md") | Should -BeTrue
    }

    It "has required Atlas scripts" {
        Test-Path (Join-Path $RepoRoot "scripts/atlas/Get-AtlasEndpointHealth.ps1") | Should -BeTrue
        Test-Path (Join-Path $RepoRoot "scripts/atlas/Invoke-AtlasValidation.ps1") | Should -BeTrue
    }

    It "does not contain obvious secret files" {
        Test-Path (Join-Path $RepoRoot ".env") | Should -BeFalse
        Test-Path (Join-Path $RepoRoot "secrets") | Should -BeFalse
    }
}
