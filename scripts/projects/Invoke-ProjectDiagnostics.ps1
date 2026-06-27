param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("atlas","solarex","domeneshop","conta","wix")]
    [string]$Project,

    [Parameter(Mandatory = $false)]
    [ValidateSet("development","staging","production")]
    [string]$TargetEnvironment = "development"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Resolve-ProjectUri {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BaseUrl,

        [Parameter(Mandatory = $false)]
        [string]$Path = "/"
    )

    $normalizedBaseUrl = $BaseUrl
    if ($normalizedBaseUrl -notmatch '^https?://') {
        $normalizedBaseUrl = "https://$normalizedBaseUrl"
    }

    if ([string]::IsNullOrWhiteSpace($Path) -or $Path -eq "/") {
        return [System.Uri]::new($normalizedBaseUrl)
    }

    return [System.Uri]::new(([System.Uri]::new($normalizedBaseUrl)), $Path)
}

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "../..")
$writeEvidencePath = Join-Path $repoRoot "scripts/common/Write-EvidenceLog.ps1"

if (-not (Test-Path $writeEvidencePath)) {
    throw "Required script not found: $writeEvidencePath"
}

$defaults = @{
    atlas = @{ BaseUrl = "https://www.atlas-ai.no"; Path = "/" }
    solarex = @{ BaseUrl = "https://nanotech-solutions-norway.github.io/SolarEX-Final-recreate/"; Path = "/" }
    domeneshop = @{ BaseUrl = "https://forms.nanotech-solutions.com"; Path = "/solarex_forms/health.php" }
    conta = @{ BaseUrl = "https://mcp.atlas-ai.no"; Path = "/health" }
    wix = @{ BaseUrl = "https://www.atlas-ai.no"; Path = "/" }
}

$selected = $defaults[$Project]
$uri = Resolve-ProjectUri -BaseUrl $selected.BaseUrl -Path $selected.Path
$addresses = @()
$dnsClassification = "failed"
$httpStatus = $null
$httpClassification = "not_checked"
$serverHeader = $null
$contentType = $null
$errorSummary = $null

try {
    $addresses = [System.Net.Dns]::GetHostAddresses($uri.Host) | ForEach-Object { $_.IPAddressToString }
    if ($addresses.Count -gt 0) {
        $dnsClassification = "resolved"
    }
    else {
        $dnsClassification = "unresolved"
    }
}
catch {
    $dnsClassification = "unresolved"
    $errorSummary = $_.Exception.Message
}

try {
    $response = Invoke-WebRequest -Uri $uri.AbsoluteUri -Method GET -TimeoutSec 30 -UseBasicParsing -MaximumRedirection 5 -Headers @{ "User-Agent" = "AtlasAI-ProjectDiagnostics/1.0" }
    $httpStatus = [int]$response.StatusCode
    $serverHeader = [string]$response.Headers["Server"]
    $contentType = [string]$response.Headers["Content-Type"]
    if ($httpStatus -ge 200 -and $httpStatus -lt 400) {
        $httpClassification = "healthy"
    }
    elseif ($httpStatus -eq 401 -or $httpStatus -eq 403) {
        $httpClassification = "unauthorized"
    }
    elseif ($httpStatus -eq 404) {
        $httpClassification = "not_found"
    }
    else {
        $httpClassification = "degraded"
    }
}
catch {
    if ($_.Exception.Response -and $_.Exception.Response.StatusCode) {
        $httpStatus = [int]$_.Exception.Response.StatusCode
        if ($httpStatus -eq 401 -or $httpStatus -eq 403) {
            $httpClassification = "unauthorized"
        }
        elseif ($httpStatus -eq 404) {
            $httpClassification = "not_found"
        }
        else {
            $httpClassification = "failed"
        }
    }
    else {
        $httpClassification = "failed"
    }

    if ([string]::IsNullOrWhiteSpace($errorSummary)) {
        $errorSummary = $_.Exception.Message
    }
}

$evidence = @{
    schema_version = "1.1"
    project = $Project
    target_environment = $TargetEnvironment
    script = "Invoke-ProjectDiagnostics.ps1"
    base_url = $selected.BaseUrl
    path = $selected.Path
    resolved_url = $uri.AbsoluteUri
    host = $uri.Host
    dns_addresses = $addresses
    dns_classification = $dnsClassification
    http_status = $httpStatus
    http_classification = $httpClassification
    server_header = $serverHeader
    content_type = $contentType
    error_summary = $errorSummary
    write_mode = "read_only"
}

& $writeEvidencePath -Evidence $evidence -Prefix "project-diagnostics-$Project"

Write-Host "Project: $Project"
Write-Host "DNS: $dnsClassification"
Write-Host "HTTP: $httpClassification"
Write-Host "Status: $httpStatus"
