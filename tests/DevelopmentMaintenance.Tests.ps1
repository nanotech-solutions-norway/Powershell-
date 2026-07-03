BeforeAll {
    $RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
}

Describe "Development maintenance dispatch" {
    It "has the development maintenance workflow and script" {
        Test-Path (Join-Path $RepoRoot ".github/workflows/manual-development-maintenance.yml") | Should -BeTrue
        Test-Path (Join-Path $RepoRoot "scripts/common/Invoke-DevelopmentMaintenanceTask.ps1") | Should -BeTrue
    }

    It "workflow is manual, development scoped, and content-write capable" {
        $workflow = Get-Content -Path (Join-Path $RepoRoot ".github/workflows/manual-development-maintenance.yml") -Raw

        $workflow | Should -Match "workflow_dispatch"
        $workflow | Should -Match "contents: write"
        $workflow | Should -Match "environment: development"
        $workflow | Should -Match "docs/CONTROL_PLANE_TASK_LOG.md"
        $workflow | Should -Match "docs/PHASE7_DEVELOPMENT_EXECUTION_ENABLEMENT.md"
        $workflow | Should -Not -Match "environment: production"
    }

    It "script allows only development maintenance targets" {
        $script = Get-Content -Path (Join-Path $RepoRoot "scripts/common/Invoke-DevelopmentMaintenanceTask.ps1") -Raw

        $script | Should -Match 'ValidateSet\("development"\)'
        $script | Should -Match 'ValidateSet\("development_edit_enabled"\)'
        $script | Should -Match 'ValidateSet\("docs/CONTROL_PLANE_TASK_LOG.md","docs/PHASE7_DEVELOPMENT_EXECUTION_ENABLEMENT.md"\)'
        $script | Should -Not -Match 'production_edit_enabled'
        $script | Should -Not -Match 'staging_edit_enabled'
    }

    It "supports dry-run validation without editing files" {
        $tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("development-maintenance-" + [guid]::NewGuid().ToString("N"))
        try {
            New-Item -ItemType Directory -Path (Join-Path $tempRoot "scripts/common") -Force | Out-Null
            New-Item -ItemType Directory -Path (Join-Path $tempRoot "docs") -Force | Out-Null
            Copy-Item -Path (Join-Path $RepoRoot "scripts/common/Invoke-DevelopmentMaintenanceTask.ps1") -Destination (Join-Path $tempRoot "scripts/common/Invoke-DevelopmentMaintenanceTask.ps1")

            Push-Location (Join-Path $tempRoot "scripts/common")
            & ./Invoke-DevelopmentMaintenanceTask.ps1 -TaskName append_task_log -TargetEnvironment development -ExecutionMode development_edit_enabled -TargetPath "docs/CONTROL_PLANE_TASK_LOG.md" -Message "Pester dry run" -DryRun
            Pop-Location

            Test-Path (Join-Path $tempRoot "docs/CONTROL_PLANE_TASK_LOG.md") | Should -BeFalse
        }
        finally {
            if ((Get-Location).Path -like "$tempRoot*") {
                Pop-Location
            }
            if (Test-Path $tempRoot) {
                Remove-Item -Path $tempRoot -Recurse -Force
            }
        }
    }
}
