<#
.SYNOPSIS
Initializes common execution context for Atlas AI and project-neutral GitHub PowerShell workflows.
#>
param(
    [Parameter(Mandatory = $false)]
    [string]$Project = "Atlas AI",

    [Parameter(Mandatory = $false)]
    [ValidateSet("development","staging","production")]
    [string]$TargetEnvironment = "development",

    [Parameter(Mandatory = $false)]
    [ValidateSet("read_only","write_paused","staging_write_enabled","production_write_enabled")]
    [string]$WriteMode = "read_only"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$context = [ordered]@{
    Project = $Project
    TargetEnvironment = $TargetEnvironment
    WriteMode = $WriteMode
    RunId = $env:GITHUB_RUN_ID
    Workflow = $env:GITHUB_WORKFLOW
    Repository = $env:GITHUB_REPOSITORY
    Actor = $env:GITHUB_ACTOR
    Ref = $env:GITHUB_REF
    TimestampUtc = (Get-Date).ToUniversalTime().ToString("o")
}

if ($WriteMode -eq "production_write_enabled" -and $TargetEnvironment -ne "production") {
    throw "Invalid write mode: production_write_enabled requires TargetEnvironment=production."
}

if ($TargetEnvironment -eq "production" -and $WriteMode -eq "production_write_enabled") {
    if ($env:GITHUB_ACTIONS -ne "true") {
        throw "Production write mode may only run inside GitHub Actions."
    }
}

[pscustomobject]$context
