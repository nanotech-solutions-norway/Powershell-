<#
.SYNOPSIS
Runs a narrow development maintenance task for approved repository documentation files.
.DESCRIPTION
This script is intentionally constrained for workflow_dispatch use. It supports only development target environment, a development edit mode, and an allow-listed documentation target.
#>
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("append_task_log")]
    [string]$TaskName,

    [Parameter(Mandatory = $true)]
    [ValidateSet("development")]
    [string]$TargetEnvironment,

    [Parameter(Mandatory = $true)]
    [ValidateSet("development_edit_enabled")]
    [string]$ExecutionMode,

    [Parameter(Mandatory = $false)]
    [ValidateSet("docs/CONTROL_PLANE_TASK_LOG.md","docs/PHASE7_DEVELOPMENT_EXECUTION_ENABLEMENT.md")]
    [string]$TargetPath = "docs/CONTROL_PLANE_TASK_LOG.md",

    [Parameter(Mandatory = $false)]
    [string]$Message = "Development maintenance task executed.",

    [Parameter(Mandatory = $false)]
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "../..")
$fullTargetPath = Join-Path $repoRoot $TargetPath
$allowedPrefix = Join-Path $repoRoot "docs"

if (-not ($fullTargetPath.StartsWith($allowedPrefix))) {
    throw "TargetPath must resolve under docs/."
}

if ($TargetEnvironment -ne "development") {
    throw "Only development target environment is allowed."
}

if ($ExecutionMode -ne "development_edit_enabled") {
    throw "Only development_edit_enabled execution mode is allowed."
}

New-Item -ItemType Directory -Path (Split-Path $fullTargetPath -Parent) -Force | Out-Null

$timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$entry = @"

## Development maintenance entry — $timestamp

- task: `$TaskName`
- target_environment: `$TargetEnvironment`
- execution_mode: `$ExecutionMode`
- message: $Message
"@

if ($DryRun) {
    Write-Host "Dry run only. Target: $TargetPath"
    Write-Host $entry
    return
}

if (-not (Test-Path $fullTargetPath)) {
    Set-Content -Path $fullTargetPath -Value "# Control Plane Task Log`n" -Encoding UTF8
}

Add-Content -Path $fullTargetPath -Value $entry -Encoding UTF8
Write-Host "Development maintenance task completed for $TargetPath"
