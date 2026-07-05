param(
    [Parameter(Mandatory = $false)]
    [string]$BaseUrl = "http://ds.atlas-ai.no",

    [Parameter(Mandatory = $false)]
    [string]$CredentialValue = $env:DOMENESHOP_MCP_STATUS_CREDENTIAL,

    [Parameter(Mandatory = $false)]
    [string]$OutputDirectory = "domeneshop-mcp-protected-status-validation-report",

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

function Remove-SensitiveText {
    param(
        [Parameter(Mandatory = $false)]
        [string]$Text,

        [Parameter(Mandatory = $false)]
        [string]$SensitiveValue
    )

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return $Text
    }

    if (-not [string]::IsNullOrWhiteSpace($SensitiveValue)) {
        return $Text.Replace($SensitiveValue, "[redacted]")
    }

    return $Text
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

New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null

$startedUtc = (Get-Date).ToUniversalTime()
$statusUri = Resolve-EndpointUri -RootUrl $BaseUrl -Path "/status.php"
$classification = "not_checked"
$errorSummary = $null
$httpStatus = $null
$sanitized = [ordered]@{
    ok = $null
    runtime_env_resolved = $null
    config_dir_resolved = $null
    site_id_count = $null
    safe_validation_posture = $null
    api_base_url_present = $null
    auth_user_present = $null
    auth_value_present = $null
    write_tools_enabled = $null
    dry_run_default = $null
    operator_approval_required = $null
}

if ([string]::IsNullOrWhiteSpace($CredentialValue)) {
    $classification = "missing_credential"
    $errorSummary = "Credential value was not provided by the runtime environment."
}
else {
    $headers = @{
        Authorization = "Bearer $CredentialValue"
        "User-Agent" = "AtlasAI-DomeneshopMcpProtectedStatus/1.0"
    }

    try {
        $response = Invoke-RestMethod -Method GET -Uri $statusUri.AbsoluteUri -Headers $headers -TimeoutSec 30
        $httpStatus = 200

        foreach ($field in @($sanitized.Keys)) {
            if ($response.PSObject.Properties.Name -contains $field) {
                $sanitized[$field] = $response.$field
            }
        }

        if ($sanitized.ok -eq $true -and $sanitized.safe_validation_posture -eq $true) {
            $classification = "healthy"
        }
        else {
            $classification = "degraded"
        }
    }
    catch {
        if ($_.Exception.Response -and $_.Exception.Response.StatusCode) {
            $httpStatus = [int]$_.Exception.Response.StatusCode
        }
        $classification = "failed"
        $errorSummary = Remove-SensitiveText -Text $_.Exception.Message -SensitiveValue $CredentialValue
    }
    finally {
        Remove-Variable headers -ErrorAction SilentlyContinue
    }
}

$findings = @()
if ($classification -ne "healthy") {
    $findings += "Status endpoint validation classification was $classification."
}
if ($null -ne $sanitized.site_id_count -and [int]$sanitized.site_id_count -ne 40) {
    $findings += "site_id_count was $($sanitized.site_id_count), expected 40."
}
if ($null -ne $sanitized.write_tools_enabled -and [string]$sanitized.write_tools_enabled -notin @("False", "false")) {
    $findings += "write_tools_enabled was $($sanitized.write_tools_enabled)."
}

$summary = [ordered]@{
    schema_version = "1.0"
    script = "Test-DomeneshopMcpProtectedStatus.ps1"
    base_url = $BaseUrl
    endpoint_path = "/status.php"
    resolved_url = $statusUri.AbsoluteUri
    write_mode = "read_only"
    classification = $classification
    http_status = $httpStatus
    error_summary = $errorSummary
    findings = $findings
    sanitized_status = $sanitized
    started_utc = $startedUtc.ToString("o")
    completed_utc = (Get-Date).ToUniversalTime().ToString("o")
}

$jsonPath = Join-Path $OutputDirectory "domeneshop-mcp-protected-status-validation.json"
$markdownPath = Join-Path $OutputDirectory "domeneshop-mcp-protected-status-validation.md"

$summary | ConvertTo-Json -Depth 8 | Set-Content -Path $jsonPath -Encoding utf8

$lines = @()
$lines += "# Domeneshop MCP Protected Status Validation"
$lines += ""
$lines += "Base URL: ``$BaseUrl``"
$lines += "Endpoint path: ``/status.php``"
$lines += "Classification: ``$classification``"
$lines += "Write mode: ``read_only``"
$lines += ""
$lines += "| Field | Value |"
$lines += "|---|---|"
foreach ($field in $sanitized.Keys) {
    $lines += "| $field | ``$(ConvertTo-BooleanText $sanitized[$field])`` |"
}

if ($findings.Count -gt 0) {
    $lines += ""
    $lines += "## Findings"
    foreach ($finding in $findings) {
        $lines += "- $finding"
    }
}

$lines | Set-Content -Path $markdownPath -Encoding utf8

Write-Host "Domeneshop MCP protected status validation completed."
Write-Host "Classification: $classification"
Write-Host "JSON report: $jsonPath"
Write-Host "Markdown report: $markdownPath"

Remove-Variable CredentialValue -ErrorAction SilentlyContinue

if ($FailOnUnhealthy -and $classification -ne "healthy") {
    throw "Domeneshop MCP protected status validation was not healthy."
}
