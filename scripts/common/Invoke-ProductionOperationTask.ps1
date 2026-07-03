<#
.SYNOPSIS
Runs approved production-gated control-plane operations.
.DESCRIPTION
This script is intended for GitHub Actions workflow_dispatch use only. It supports approved production operations behind the GitHub production environment.
It can record production/deployment operation markers in repository documentation and can call one approved external endpoint when configured by environment secrets.
#>
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("append_production_log","record_deployment_marker","call_approved_external_endpoint")]
    [string]$TaskName,

    [Parameter(Mandatory = $true)]
    [ValidateSet("production")]
    [string]$TargetEnvironment,

    [Parameter(Mandatory = $true)]
    [ValidateSet("production_change_enabled")]
    [string]$ExecutionMode,

    [Parameter(Mandatory = $false)]
    [ValidateSet("primary_external_endpoint")]
    [string]$EndpointAlias = "primary_external_endpoint",

    [Parameter(Mandatory = $false)]
    [string]$Message = "Production operation executed.",

    [Parameter(Mandatory = $false)]
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if ($env:GITHUB_ACTIONS -ne "true") {
    throw "Production operations must run inside GitHub Actions."
}

if ($TargetEnvironment -ne "production") {
    throw "Only production target environment is allowed."
}

if ($ExecutionMode -ne "production_change_enabled") {
    throw "Only production_change_enabled execution mode is allowed."
}

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "../..")
$logPath = Join-Path $repoRoot "docs/PRODUCTION_OPERATIONS_LOG.md"
$evidenceDir = Join-Path $repoRoot "evidence"
New-Item -ItemType Directory -Path (Split-Path $logPath -Parent) -Force | Out-Null
New-Item -ItemType Directory -Path $evidenceDir -Force | Out-Null

$timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$evidence = [ordered]@{
    schema_version = "1.0"
    timestamp_utc = $timestamp
    task = $TaskName
    target_environment = $TargetEnvironment
    execution_mode = $ExecutionMode
    dry_run = [bool]$DryRun
    endpoint_alias = $EndpointAlias
    classification = "pending"
    external_endpoint_called = $false
}

function Add-ProductionLogEntry {
    param(
        [Parameter(Mandatory = $true)]
        [string]$EntryType
    )

    if (-not (Test-Path $logPath)) {
        Set-Content -Path $logPath -Value "# Production Operations Log`n" -Encoding UTF8
    }

    $entry = @"

## $EntryType — $timestamp

- task: `$TaskName`
- target_environment: `$TargetEnvironment`
- execution_mode: `$ExecutionMode`
- dry_run: `$([bool]$DryRun)`
- message: $Message
"@

    Add-Content -Path $logPath -Value $entry -Encoding UTF8
}

if ($DryRun) {
    Write-Host "Dry run only. Task: $TaskName"
    $evidence.classification = "dry_run_validated"
}
elseif ($TaskName -eq "append_production_log") {
    Add-ProductionLogEntry -EntryType "Production operation entry"
    $evidence.classification = "production_log_recorded"
}
elseif ($TaskName -eq "record_deployment_marker") {
    Add-ProductionLogEntry -EntryType "Deployment marker"
    $evidence.classification = "deployment_marker_recorded"
}
elseif ($TaskName -eq "call_approved_external_endpoint") {
    $endpointUrl = $env:PRODUCTION_EXTERNAL_ENDPOINT_URL
    $bearerToken = $env:PRODUCTION_EXTERNAL_ENDPOINT_BEARER_TOKEN

    if ([string]::IsNullOrWhiteSpace($endpointUrl)) {
        throw "PRODUCTION_EXTERNAL_ENDPOINT_URL is required for call_approved_external_endpoint."
    }

    if ($endpointUrl -notmatch '^https://') {
        throw "Approved external endpoint URL must use https."
    }

    $headers = @{
        "Content-Type" = "application/json"
        "User-Agent" = "NTSN-PowerShell-Control-Plane/1.0"
    }

    if (-not [string]::IsNullOrWhiteSpace($bearerToken)) {
        $headers["Authorization"] = "Bearer $bearerToken"
    }

    $payload = @{
        timestamp_utc = $timestamp
        source = "nanotech-solutions-norway/Powershell-"
        task = $TaskName
        target_environment = $TargetEnvironment
        endpoint_alias = $EndpointAlias
        message = $Message
    } | ConvertTo-Json -Depth 4

    $response = Invoke-WebRequest -Uri $endpointUrl -Method POST -Headers $headers -Body $payload -TimeoutSec 30 -UseBasicParsing
    $evidence.classification = "external_endpoint_called"
    $evidence.external_endpoint_called = $true
    $evidence.http_status = [int]$response.StatusCode
}
else {
    throw "Unsupported production operation task."
}

$evidencePath = Join-Path $evidenceDir ("production-operation-" + $timestamp.Replace(":", "") + ".json")
$evidence | ConvertTo-Json -Depth 6 | Set-Content -Path $evidencePath -Encoding UTF8
Write-Host "Production operation completed with classification: $($evidence.classification)"
