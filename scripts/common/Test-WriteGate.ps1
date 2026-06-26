<#
.SYNOPSIS
Evaluates whether a workflow is allowed to perform write operations.
.DESCRIPTION
This guard keeps production and staging writes paused unless the GitHub workflow, target environment, and explicit write mode all match the expected policy.
#>
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("development","staging","production")]
    [string]$TargetEnvironment,

    [Parameter(Mandatory = $true)]
    [ValidateSet("read_only","write_paused","staging_write_enabled","production_write_enabled")]
    [string]$WriteMode,

    [Parameter(Mandatory = $false)]
    [string]$WriteToolsEnabled = $env:WRITE_TOOLS_ENABLED
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$normalizedWriteToolsEnabled = if ([string]::IsNullOrWhiteSpace($WriteToolsEnabled)) { "false" } else { $WriteToolsEnabled.ToLowerInvariant() }

$result = [ordered]@{
    TargetEnvironment = $TargetEnvironment
    WriteMode = $WriteMode
    WriteToolsEnabled = $normalizedWriteToolsEnabled
    WritesAllowed = $false
    Classification = "write_paused"
    Reason = "Write tools are disabled or write mode is not approved."
}

if ($normalizedWriteToolsEnabled -ne "true") {
    return [pscustomobject]$result
}

switch ($WriteMode) {
    "read_only" {
        $result.Reason = "Read-only mode never permits writes."
    }
    "write_paused" {
        $result.Reason = "Write mode is explicitly paused."
    }
    "staging_write_enabled" {
        if ($TargetEnvironment -eq "staging") {
            $result.WritesAllowed = $true
            $result.Classification = "staging_write_allowed"
            $result.Reason = "Staging write mode is approved for staging."
        }
        else {
            $result.Reason = "Staging write mode requires TargetEnvironment=staging."
        }
    }
    "production_write_enabled" {
        if ($TargetEnvironment -eq "production" -and $env:GITHUB_ACTIONS -eq "true") {
            $result.WritesAllowed = $true
            $result.Classification = "production_write_allowed"
            $result.Reason = "Production write mode is approved in GitHub Actions production environment."
        }
        else {
            $result.Reason = "Production write mode requires TargetEnvironment=production inside GitHub Actions."
        }
    }
}

[pscustomobject]$result
