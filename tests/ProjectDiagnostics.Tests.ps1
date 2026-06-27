BeforeAll {
    $RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
}

Describe "Project diagnostics" {
    It "has diagnostics script and workflow" {
        Test-Path (Join-Path $RepoRoot "scripts/projects/Invoke-ProjectDiagnostics.ps1") | Should -BeTrue
        Test-Path (Join-Path $RepoRoot ".github/workflows/manual-project-diagnostics.yml") | Should -BeTrue
    }

    It "supports all project adapters" {
        $content = Get-Content -Path (Join-Path $RepoRoot "scripts/projects/Invoke-ProjectDiagnostics.ps1") -Raw
        foreach ($project in @("atlas", "solarex", "domeneshop", "conta", "wix")) {
            $content | Should -Match $project
        }
    }

    It "keeps diagnostics read-only" {
        $content = Get-Content -Path (Join-Path $RepoRoot "scripts/projects/Invoke-ProjectDiagnostics.ps1") -Raw
        $content | Should -Match "read_only"
        $content | Should -Match "Write-EvidenceLog.ps1"
    }
}
