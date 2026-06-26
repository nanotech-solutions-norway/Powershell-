<#
.SYNOPSIS
Runs a non-sensitive Atlas AI domain or HTTP health check and writes evidence.
.DESCRIPTION
For domains without a published homepage, use CheckMode=dns. For published web routes, use CheckMode=http.
By default this script writes evidence and returns success even when HTTP status is non-healthy. Use -FailOnUnhealthy for strict CI/deployment gating.
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$BaseUrl,

    [Parameter(Mandatory = $false)]
    [string]$Path = "/",

    [Parameter(Mandatory = $false)]
    [ValidateSet("dns","http")]
    [string]$CheckMode = "dns",

    [Parameter(Mandatory = $false)]
    [ValidateSet("development","staging","production")]
    [string]$TargetEnvironment = "development",

    [Parameter(Mandatory = $false)]
    [ValidateSet("read_only","write_paused","staging_write_enabled","production_write_enabled")]
    [string]$WriteMode = "read_only",

    [Parameter(Mandatory = $false)]
    [switch]$FailOnUnhealthy
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

$normalizedBaseUrl = $BaseUrl
if ($normalizedBaseUrl -notmatch '^https?://') {
    $normalizedBaseUrl = "https://$normalizedBaseUrl"
}

$uri = [System.Uri]::new(([System.Uri]::new($normalizedBaseUrl)), $Path)
$hostName = $uri.Host

$statusCode = $null
$classification = "failed"
$errorSummary = $null
$dnsAddresses = @()

if ($CheckMode -eq "dns") {
    try {
        $dnsAddresses = [System.Net.Dns]::GetHostAddresses($hostName) | ForEach-Object { $_.IPAddressToString }
        if ($dnsAddresses.Count -gt 0) {
            $classification = "healthy"
        }
        else {
            $classification = "dns_unresolved"
            $errorSummary = "No DNS addresses returned for host '$hostName'."
        }
    }
    catch {
        $classification = "dns_unresolved"
        $errorSummary = $_.Exception.Message
    }
}
else {
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
}

$strictFailure = ($classification -notin @("healthy"))

$evidence = @{
    schema_version = "1.0"
    project = "Atlas AI"
    target_environment = $TargetEnvironment
    workflow = $context.Workflow
    repository = $context.Repository
    run_id = $context.RunId
    script = "Get-AtlasEndpointHealth.ps1"
    check_mode = $CheckMode
    base_url = $BaseUrl
    path = $Path
    resolved_url = $uri.AbsoluteUri
    host = $hostName
    dns_addresses = $dnsAddresses
    http_status = $statusCode
    classification = $classification
    write_mode = $WriteMode
    fail_on_unhealthy = [bool]$FailOnUnhealthy
    strict_failure = $strictFailure
    manual_review_required = $strictFailure
    error_summary = $errorSummary
}

& $writeEvidencePath -Evidence $evidence -Prefix "atlas-health"

if ($strictFailure) {
    Write-Warning "Atlas health classification: $classification"

    if ($CheckMode -eq "http") {
        Write-Warning "HTTP mode requires the checked route to return a healthy 2xx/3xx status. For domains without a published homepage, use CheckMode=dns."
    }

    if ($FailOnUnhealthy) {
        exit 1
    }

    Write-Host "Non-blocking health evidence mode: workflow will not fail. Use -FailOnUnhealthy for strict gating."
    exit 0
}

Write-Host "Atlas health classification: $classification"
