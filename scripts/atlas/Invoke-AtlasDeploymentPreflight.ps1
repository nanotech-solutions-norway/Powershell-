<#
.SYNOPSIS
Runs Atlas AI deployment preflight checks without performing deployment writes.
.DESCRIPTION
This script validates repository structure, write gate status, and runtime context before any staging or production deployment workflow is allowed to proceed.
#>
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("development","staging","production")]
    [string]$TargetEnvironment = "development",

    [Parameter(Mandatory = $false)]
    [ValidateSet("read_only","write_paused","staging_write_enabled","production_write_enabled")]
    [string]$WriteMode = "read_only",

    [Parameter(Mandatory = $false)]
    [string]$BaseUrl = "https://www.atlas-ai.no"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "../..")
$initializeContextPath = Join-Path $repoRoot "scripts/common/Initialize-AtlasContext.ps1"
$writeEvidencePath = Join-Path $repoRoot "scripts/common/Write-EvidenceLog.ps1"
$writeGatePath = Join-Path $repoRoot "scripts/common/Test-WriteGate.ps1"

foreach ($requiredScript in @($initializeContextPath, $writeEvidencePath, $writeGatePath)) {
    if (-not (Test-Path $requiredScript)) {
        throw "Required script not found: $requiredScript"
    }
}

$context = & $initializeContextPath -Project "Atlas AI" -TargetEnvironment $TargetEnvironment -WriteMode $WriteMode
$writeGate = & $writeGatePath -TargetEnvironment $TargetEnvironment -WriteMode $WriteMode

$requiredPaths = @(
    "README.md",
    "SECURITY.md",
    "config/atlas.example.json",
    "scripts/common/Initialize-AtlasContext.ps1",
    "scripts/common/Write-EvidenceLog.ps1",
    "scripts/common/Test-WriteGate.ps1",
    "scripts/atlas/Get-AtlasEndpointHealth.ps1",
    "scripts/atlas/Invoke-AtlasValidation.ps1",
    "scripts/atlas/Invoke-AtlasDeploymentPreflight.ps1",
    ".github/workflows/ci-powershell-quality.yml",
    ".github/workflows/manual-atlas-health-check.yml",
    ".github/workflows/manual-atlas-validation.yml",
    ".github/workflows/manual-atlas-deployment-preflight.yml",
    ".github/workflows/manual-run-script.yml",
    ".github/workflows/scheduled-atlas-health.yml"
)

$missing = @()
foreach ($path in $requiredPaths) {
    if (-not (Test-Path (Join-Path $repoRoot $path))) {
        $missing += $path
    }
}

$classification = "preflight_passed"
$manualReviewRequired = $false
$errorSummary = $null

if ($missing.Count -gt 0) {
    $classification = "manual_review_required"
    $manualReviewRequired = $true
    $errorSummary = "Missing required paths: $($missing -join ', ')"
}

if ($WriteMode -in @("staging_write_enabled","production_write_enabled") -and -not $writeGate.WritesAllowed) {
    $classification = "write_paused"
    $manualReviewRequired = $true
    $errorSummary = $writeGate.Reason
}

$evidence = @{
    schema_version = "1.0"
    project = "Atlas AI"
    target_environment = $TargetEnvironment
    workflow = $context.Workflow
    repository = $context.Repository
    run_id = $context.RunId
    script = "Invoke-AtlasDeploymentPreflight.ps1"
    base_url = $BaseUrl
    write_mode = $WriteMode
    write_gate = $writeGate
    classification = $classification
    missing_required_paths = $missing
    manual_review_required = $manualReviewRequired
    error_summary = $errorSummary
}

& $writeEvidencePath -Evidence $evidence -Prefix "atlas-deployment-preflight"

if ($classification -ne "preflight_passed") {
    Write-Warning "Atlas deployment preflight classification: $classification"
    exit 1
}

Write-Host "Atlas deployment preflight classification: $classification"
