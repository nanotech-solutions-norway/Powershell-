BeforeAll {
    $RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
}

Describe "Atlas AI PowerShell repository baseline" {
    It "has required documentation files" {
        Test-Path (Join-Path $RepoRoot "README.md") | Should -BeTrue
        Test-Path (Join-Path $RepoRoot "ATLAS_GITHUB_POWERSHELL_BLUEPRINT_REPORT.md") | Should -BeTrue
        Test-Path (Join-Path $RepoRoot "SECURITY.md") | Should -BeTrue
    }

    It "has required common scripts" {
        Test-Path (Join-Path $RepoRoot "scripts/common/Initialize-AtlasContext.ps1") | Should -BeTrue
        Test-Path (Join-Path $RepoRoot "scripts/common/Write-EvidenceLog.ps1") | Should -BeTrue
        Test-Path (Join-Path $RepoRoot "scripts/common/Test-WriteGate.ps1") | Should -BeTrue
    }

    It "has required Atlas scripts" {
        Test-Path (Join-Path $RepoRoot "scripts/atlas/Get-AtlasEndpointHealth.ps1") | Should -BeTrue
        Test-Path (Join-Path $RepoRoot "scripts/atlas/Invoke-AtlasValidation.ps1") | Should -BeTrue
        Test-Path (Join-Path $RepoRoot "scripts/atlas/Invoke-AtlasDeploymentPreflight.ps1") | Should -BeTrue
    }

    It "has required GitHub workflows" {
        Test-Path (Join-Path $RepoRoot ".github/workflows/ci-powershell-quality.yml") | Should -BeTrue
        Test-Path (Join-Path $RepoRoot ".github/workflows/manual-atlas-health-check.yml") | Should -BeTrue
        Test-Path (Join-Path $RepoRoot ".github/workflows/manual-atlas-validation.yml") | Should -BeTrue
        Test-Path (Join-Path $RepoRoot ".github/workflows/manual-atlas-deployment-preflight.yml") | Should -BeTrue
        Test-Path (Join-Path $RepoRoot ".github/workflows/scheduled-atlas-health.yml") | Should -BeTrue
        Test-Path (Join-Path $RepoRoot ".github/workflows/manual-run-script.yml") | Should -BeTrue
    }

    It "does not contain obvious secret files" {
        Test-Path (Join-Path $RepoRoot ".env") | Should -BeFalse
        Test-Path (Join-Path $RepoRoot "secrets") | Should -BeFalse
        Test-Path (Join-Path $RepoRoot "private") | Should -BeFalse
        Test-Path (Join-Path $RepoRoot "credentials") | Should -BeFalse
    }

    It "does not use obsolete common-script path references" {
        $scripts = Get-ChildItem (Join-Path $RepoRoot "scripts") -Recurse -Filter "*.ps1"
        foreach ($script in $scripts) {
            $content = Get-Content -Path $script.FullName -Raw
            $content | Should -Not -Match '\$root/common/'
            $content | Should -Not -Match '\$repoRoot/common/'
        }
    }
}

Describe "Atlas AI write gate" {
    It "blocks writes when WRITE_TOOLS_ENABLED is false" {
        $result = & (Join-Path $RepoRoot "scripts/common/Test-WriteGate.ps1") -TargetEnvironment "production" -WriteMode "production_write_enabled" -WriteToolsEnabled "false"
        $result.WritesAllowed | Should -BeFalse
        $result.Classification | Should -Be "write_paused"
    }

    It "allows staging writes only when explicitly enabled for staging" {
        $result = & (Join-Path $RepoRoot "scripts/common/Test-WriteGate.ps1") -TargetEnvironment "staging" -WriteMode "staging_write_enabled" -WriteToolsEnabled "true"
        $result.WritesAllowed | Should -BeTrue
        $result.Classification | Should -Be "staging_write_allowed"
    }
}
