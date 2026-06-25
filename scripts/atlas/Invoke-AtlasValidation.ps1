<#
.SYNOPSIS
Validates Atlas AI PowerShell repository structure and safe execution requirements.
#>
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("development","staging","production")]
    [string]$TargetEnvironment = "development",

    [Parameter(Mandatory = $false)]
    [ValidateSet("read_only","write_paused","staging_write_enabled","production_write_enabled")]
    [string]$WriteMode = "read_only",

    [Parameter(Mandatory = $false)]
    [string]$BaseUrl = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "../..")
$requiredPaths = @(
    "README.md",
    "SECURITY.md",
    "scripts/common/Initialize-AtlasContext.ps1",
    "scripts/common/Write-EvidenceLog.ps1",
    "scripts/atlas/Get-AtlasEndpointHealth.ps1",
    ".github/workflows/manual-atlas-health-check.yml",
    ".github/workflows/ci-powershell-quality.yml"
)

$missing = @()
foreach ($path in $requiredPaths) {
    if (-not (Test-Path (Join-Path $repoRoot $path))) {
        $missing += $path
    }
}

$classification = if ($missing.Count -eq 0) { "healthy" } else { "manual_review_required" }

$evidence = @{
    schema_version = "1.0"
    project = "Atlas AI"
    target_environment = $TargetEnvironment
    script = "Invoke-AtlasValidation.ps1"
    write_mode = $WriteMode
    classification = $classification
    missing_required_paths = $missing
    manual_review_required = ($missing.Count -gt 0)
}

& "$repoRoot/scripts/common/Write-EvidenceLog.ps1" -Evidence $evidence -Prefix "atlas-validation"

if ($missing.Count -gt 0) {
    Write-Error "Validation failed. Missing paths: $($missing -join ', ')"
}

if (-not [string]::IsNullOrWhiteSpace($BaseUrl)) {
    & "$repoRoot/scripts/atlas/Get-AtlasEndpointHealth.ps1" -BaseUrl $BaseUrl -TargetEnvironment $TargetEnvironment -WriteMode "read_only"
}

Write-Host "Atlas validation completed: $classification"
