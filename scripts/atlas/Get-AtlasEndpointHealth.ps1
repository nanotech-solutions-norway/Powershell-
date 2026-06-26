<#
.SYNOPSIS
Runs a non-sensitive Atlas AI endpoint health check and writes evidence.
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$BaseUrl,

    [Parameter(Mandatory = $false)]
    [string]$Path = "/",

    [Parameter(Mandatory = $false)]
    [ValidateSet("development","staging","production")]
    [string]$TargetEnvironment = "development",

    [Parameter(Mandatory = $false)]
    [ValidateSet("read_only","write_paused","staging_write_enabled","production_write_enabled")]
    [string]$WriteMode = "read_only"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "../..")
$commonDir = Join-Path $repoRoot "scripts/common"
$initializeContextPath = Join-Path $commonDir "Initialize-AtlasContext.ps1"
$writeEvidencePath = Join-Path $commonDir "Write-EvidenceLog.ps1"

if (-not (Test-Path $initializeContextPath)) {
    throw "Required script not found: $initializeContextPath"
}

if (-not (Test-Path $writeEvidencePath)) {
    throw "Required script not found: $writeEvidencePath"
}

$context = & $initializeContextPath -Project "Atlas AI" -TargetEnvironment $TargetEnvironment -WriteMode $WriteMode

if ($WriteMode -ne "read_only") {
    Write-Host "Health check is read-only. Requested write mode '$WriteMode' will not perform writes."
}

$uri = [System.Uri]::new(([System.Uri]::new($BaseUrl)), $Path)

$statusCode = $null
$classification = "failed"
$errorSummary = $null

try {
    $headers = @{
        "User-Agent" = "AtlasAI-GitHub-PowerShell-HealthCheck/1.0"
    }

    if (-not [string]::IsNullOrWhiteSpace($env:ATLAS_HEALTH_BEARER_TOKEN)) {
        $headers["Authorization"] = "Bearer $($env:ATLAS_HEALTH_BEARER_TOKEN)"
    }

    $response = Invoke-WebRequest -Uri $uri.AbsoluteUri -Method GET -Headers $headers -TimeoutSec 30 -UseBasicParsing -MaximumRedirection 5
    $statusCode = [int]$response.StatusCode

    if ($statusCode -ge 200 -and $statusCode -lt 400) {
        $classification = "healthy"
    }
    elseif ($statusCode -eq 401 -or $statusCode -eq 403) {
        $classification = "unauthorized"
    }
    elseif ($statusCode -eq 404) {
        $classification = "not_found"
    }
    else {
        $classification = "degraded"
    }
}
catch {
    $errorSummary = $_.Exception.Message

    if ($_.Exception.Response -and $_.Exception.Response.StatusCode) {
        $statusCode = [int]$_.Exception.Response.StatusCode
    }

    if ($statusCode -ge 200 -and $statusCode -lt 400) {
        $classification = "healthy"
    }
    elseif ($statusCode -eq 401 -or $statusCode -eq 403) {
        $classification = "unauthorized"
    }
    elseif ($statusCode -eq 404) {
        $classification = "not_found"
    }
    else {
        $classification = "failed"
    }
}

$evidence = @{
    schema_version = "1.0"
    project = "Atlas AI"
    target_environment = $TargetEnvironment
    workflow = $context.Workflow
    repository = $context.Repository
    run_id = $context.RunId
    script = "Get-AtlasEndpointHealth.ps1"
    base_url = $BaseUrl
    path = $Path
    resolved_url = $uri.AbsoluteUri
    http_status = $statusCode
    classification = $classification
    write_mode = $WriteMode
    manual_review_required = ($classification -notin @("healthy"))
    error_summary = $errorSummary
}

& $writeEvidencePath -Evidence $evidence -Prefix "atlas-health"

if ($classification -notin @("healthy")) {
    Write-Warning "Atlas health classification: $classification"
    exit 1
}

Write-Host "Atlas health classification: $classification"
