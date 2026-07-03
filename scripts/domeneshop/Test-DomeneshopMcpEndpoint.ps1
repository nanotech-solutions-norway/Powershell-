param(
    [Parameter(Mandatory = $false)]
    [string]$BaseUrl = "http://ds.atlas-ai.no",

    [Parameter(Mandatory = $false)]
    [string]$OutputDirectory = "domeneshop-mcp-validation-report",

    [Parameter(Mandatory = $false)]
    [int]$ExpectedSiteIdCount = 40,

    [Parameter(Mandatory = $false)]
    [switch]$IncludeStatusEndpoint,

    [Parameter(Mandatory = $false)]
    [string]$BearerToken = $env:DOMENESHOP_MCP_BEARER_TOKEN,

    [Parameter(Mandatory = $false)]
    [switch]$FailOnUnhealthy
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Resolve-EndpointUri {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RootUrl,

        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $normalizedRoot = $RootUrl.TrimEnd("/")
    if ($normalizedRoot -notmatch '^https?://') {
        $normalizedRoot = "https://$normalizedRoot"
    }

    return [System.Uri]::new(([System.Uri]::new($normalizedRoot + "/")), $Path.TrimStart("/"))
}

function ConvertTo-BooleanText {
    param([object]$Value)

    if ($null -eq $Value) {
        return "missing"
    }

    if ($Value -is [bool]) {
        return $Value.ToString().ToLowerInvariant()
    }

    return [string]$Value
}

function Test-JsonEndpoint {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [hashtable]$Headers = @{}
    )

    $uri = Resolve-EndpointUri -RootUrl $BaseUrl -Path $Path
    $record = [ordered]@{
        name = $Name
        path = $Path
        url = $uri.AbsoluteUri
        status_code = $null
        classification = "not_checked"
        json_parse = "not_attempted"
        ok = $null
        runtime_env_present = $null
        site_id_count = $null
        safe_validation_posture = $null
        write_tools_enabled = $null
        dry_run_default = $null
        operator_approval_required = $null
        error = $null
    }

    try {
        $response = Invoke-WebRequest `
            -Uri $uri.AbsoluteUri `
            -Method GET `
            -TimeoutSec 30 `
            -UseBasicParsing `
            -MaximumRedirection 5 `
            -Headers $Headers

        $record.status_code = [int]$response.StatusCode
        $body = [string]$response.Content

        try {
            $json = $body | ConvertFrom-Json -ErrorAction Stop
            $record.json_parse = "parsed"

            if ($json.PSObject.Properties.Name -contains "ok") {
                $record.ok = $json.ok
            }
            if ($json.PSObject.Properties.Name -contains "runtime_env_present") {
                $record.runtime_env_present = $json.runtime_env_present
            }
            if ($json.PSObject.Properties.Name -contains "site_id_count") {
                $record.site_id_count = $json.site_id_count
            }
            if ($json.PSObject.Properties.Name -contains "safe_validation_posture") {
                $record.safe_validation_posture = $json.safe_validation_posture
            }
            if ($json.PSObject.Properties.Name -contains "write_tools_enabled") {
                $record.write_tools_enabled = $json.write_tools_enabled
            }
            if ($json.PSObject.Properties.Name -contains "dry_run_default") {
                $record.dry_run_default = $json.dry_run_default
            }
            if ($json.PSObject.Properties.Name -contains "operator_approval_required") {
                $record.operator_approval_required = $json.operator_approval_required
            }
            if ($json.PSObject.Properties.Name -contains "error") {
                $record.error = $json.error
            }
        }
        catch {
            $record.json_parse = "failed"
            $record.error = $_.Exception.Message
        }

        if ($record.status_code -ge 200 -and $record.status_code -lt 400) {
            $record.classification = "reachable"
        }
        else {
            $record.classification = "degraded"
        }
    }
    catch {
        if ($_.Exception.Response -and $_.Exception.Response.StatusCode) {
            $record.status_code = [int]$_.Exception.Response.StatusCode
        }
        $record.classification = "failed"
        $record.error = $_.Exception.Message
    }

    return [pscustomobject]$record
}

New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null

$startedUtc = (Get-Date).ToUniversalTime()
$headers = @{ "User-Agent" = "AtlasAI-DomeneshopMcpValidation/1.0" }
$results = @()

$results += Test-JsonEndpoint -Name "index" -Path "/" -Headers $headers
$results += Test-JsonEndpoint -Name "health" -Path "/health.php" -Headers $headers
$results += Test-JsonEndpoint -Name "config-check" -Path "/config-check.php" -Headers $headers

if ($IncludeStatusEndpoint) {
    if ([string]::IsNullOrWhiteSpace($BearerToken)) {
        $results += [pscustomobject][ordered]@{
            name = "status"
            path = "/status.php"
            url = (Resolve-EndpointUri -RootUrl $BaseUrl -Path "/status.php").AbsoluteUri
            status_code = $null
            classification = "skipped_missing_bearer_token"
            json_parse = "not_attempted"
            ok = $null
            runtime_env_present = $null
            site_id_count = $null
            safe_validation_posture = $null
            write_tools_enabled = $null
            dry_run_default = $null
            operator_approval_required = $null
            error = "DOMENESHOP_MCP_BEARER_TOKEN was not provided."
        }
    }
    else {
        $statusHeaders = $headers.Clone()
        $statusHeaders["Authorization"] = "Bearer $BearerToken"
        $results += Test-JsonEndpoint -Name "status" -Path "/status.php" -Headers $statusHeaders
    }
}

$publicResults = $results | Where-Object { $_.name -in @("index", "health", "config-check") }
$failedPublic = @($publicResults | Where-Object { $_.classification -notin @("reachable") })
$configCheck = $results | Where-Object { $_.name -eq "config-check" } | Select-Object -First 1

$findings = @()
if ($failedPublic.Count -gt 0) {
    $findings += "One or more public read-only endpoints were not reachable."
}

if ($configCheck) {
    if ($null -ne $configCheck.site_id_count -and [int]$configCheck.site_id_count -ne $ExpectedSiteIdCount) {
        $findings += "config-check site_id_count was $($configCheck.site_id_count), expected $ExpectedSiteIdCount."
    }
    if ($null -ne $configCheck.write_tools_enabled -and [string]$configCheck.write_tools_enabled -ne "False" -and [string]$configCheck.write_tools_enabled -ne "false") {
        $findings += "config-check reported write_tools_enabled=$($configCheck.write_tools_enabled)."
    }
    if ($null -ne $configCheck.dry_run_default -and [string]$configCheck.dry_run_default -ne "True" -and [string]$configCheck.dry_run_default -ne "true") {
        $findings += "config-check reported dry_run_default=$($configCheck.dry_run_default)."
    }
    if ($null -ne $configCheck.operator_approval_required -and [string]$configCheck.operator_approval_required -ne "True" -and [string]$configCheck.operator_approval_required -ne "true") {
        $findings += "config-check reported operator_approval_required=$($configCheck.operator_approval_required)."
    }
}

$classification = if ($findings.Count -eq 0) { "healthy" } else { "degraded" }

$summary = [ordered]@{
    schema_version = "1.0"
    script = "Test-DomeneshopMcpEndpoint.ps1"
    base_url = $BaseUrl
    expected_site_id_count = $ExpectedSiteIdCount
    include_status_endpoint = [bool]$IncludeStatusEndpoint
    write_mode = "read_only"
    classification = $classification
    started_utc = $startedUtc.ToString("o")
    completed_utc = (Get-Date).ToUniversalTime().ToString("o")
    findings = $findings
    endpoints = $results
}

$summaryPath = Join-Path $OutputDirectory "domeneshop-mcp-endpoint-validation.json"
$markdownPath = Join-Path $OutputDirectory "domeneshop-mcp-endpoint-validation.md"

$summary | ConvertTo-Json -Depth 8 | Set-Content -Path $summaryPath -Encoding utf8

$lines = @()
$lines += "# Domeneshop MCP Endpoint Validation"
$lines += ""
$lines += "Base URL: ``$BaseUrl``"
$lines += "Classification: ``$classification``"
$lines += "Write mode: ``read_only``"
$lines += "Expected SiteID count: ``$ExpectedSiteIdCount``"
$lines += ""
$lines += "| Endpoint | URL | Status | Classification | ok | site_id_count | write_tools_enabled | dry_run_default | operator_approval_required |"
$lines += "|---|---|---:|---|---|---:|---|---|---|"
foreach ($result in $results) {
    $lines += "| $($result.name) | $($result.url) | $($result.status_code) | $($result.classification) | $(ConvertTo-BooleanText $result.ok) | $($result.site_id_count) | $(ConvertTo-BooleanText $result.write_tools_enabled) | $(ConvertTo-BooleanText $result.dry_run_default) | $(ConvertTo-BooleanText $result.operator_approval_required) |"
}

if ($findings.Count -gt 0) {
    $lines += ""
    $lines += "## Findings"
    foreach ($finding in $findings) {
        $lines += "- $finding"
    }
}

$lines | Set-Content -Path $markdownPath -Encoding utf8

Write-Host "Domeneshop MCP endpoint validation completed."
Write-Host "Classification: $classification"
Write-Host "JSON report: $summaryPath"
Write-Host "Markdown report: $markdownPath"

if ($FailOnUnhealthy -and $classification -ne "healthy") {
    throw "Domeneshop MCP endpoint validation was not healthy."
}
