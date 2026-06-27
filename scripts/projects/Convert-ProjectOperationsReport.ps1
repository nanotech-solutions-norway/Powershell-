<#
.SYNOPSIS
Creates a consolidated operations report from project health and diagnostics evidence.
#>
param(
    [Parameter(Mandatory = $false)]
    [string]$EvidenceDirectory = "evidence",

    [Parameter(Mandatory = $false)]
    [string]$OutputDirectory = "operations-report",

    [Parameter(Mandatory = $false)]
    [string]$Prefix = "project-operations-report"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null

$projects = @("atlas", "solarex", "domeneshop", "conta", "wix")
$healthItems = @{}
$diagnosticItems = @{}

if (Test-Path $EvidenceDirectory) {
    $files = Get-ChildItem -Path $EvidenceDirectory -Filter "*.json" -File | Sort-Object Name
}
else {
    $files = @()
}

foreach ($file in $files) {
    try {
        $json = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
        $project = [string]$json.project
        if ([string]::IsNullOrWhiteSpace($project)) {
            continue
        }

        if ([string]$json.script -eq "Invoke-ProjectDiagnostics.ps1") {
            $diagnosticItems[$project] = $json
        }
        elseif ($null -ne $json.classification) {
            $healthItems[$project] = $json
        }
    }
    catch {
        Write-Warning "Could not parse evidence file $($file.Name): $($_.Exception.Message)"
    }
}

$rows = @()
foreach ($project in $projects) {
    $health = $healthItems[$project]
    $diagnostics = $diagnosticItems[$project]

    $healthClassification = if ($health) { [string]$health.classification } else { "missing" }
    $dnsClassification = if ($diagnostics) { [string]$diagnostics.dns_classification } else { "missing" }
    $httpClassification = if ($diagnostics) { [string]$diagnostics.http_classification } else { "missing" }
    $httpStatus = if ($diagnostics) { $diagnostics.http_status } elseif ($health) { $health.http_status } else { $null }
    $host = if ($diagnostics) { $diagnostics.host } elseif ($health) { $health.host } else { "" }

    $reviewRequired = $healthClassification -ne "healthy" -or $dnsClassification -ne "resolved" -or $httpClassification -ne "healthy"
    $status = if (-not $reviewRequired) { "healthy" } else { "review_required" }

    $rows += [pscustomobject]@{
        project = $project
        status = $status
        health_classification = $healthClassification
        dns_classification = $dnsClassification
        http_classification = $httpClassification
        http_status = $httpStatus
        host = $host
        review_required = $reviewRequired
    }
}

$reviewRows = @($rows | Where-Object { $_.review_required })
$overallClassification = if ($reviewRows.Count -eq 0) { "healthy" } else { "manual_review_required" }
$timestamp = (Get-Date).ToUniversalTime().ToString("yyyyMMdd-HHmmss")
$jsonPath = Join-Path $OutputDirectory "$Prefix-$timestamp.json"
$mdPath = Join-Path $OutputDirectory "$Prefix-$timestamp.md"

$summary = [ordered]@{
    schema_version = "1.0"
    generated_utc = (Get-Date).ToUniversalTime().ToString("o")
    evidence_directory = $EvidenceDirectory
    total_projects = $rows.Count
    review_count = $reviewRows.Count
    overall_classification = $overallClassification
    rows = $rows
}

$summary | ConvertTo-Json -Depth 8 | Set-Content -Path $jsonPath -Encoding UTF8

$lines = @()
$lines += "# Project Operations Report"
$lines += ""
$lines += "Generated UTC: $($summary.generated_utc)"
$lines += ""
$lines += "| Metric | Value |"
$lines += "|---|---:|"
$lines += "| Projects | $($summary.total_projects) |"
$lines += "| Review required | $($summary.review_count) |"
$lines += "| Overall classification | $($summary.overall_classification) |"
$lines += ""
$lines += "| Project | Status | Health | DNS | HTTP | HTTP status | Host |"
$lines += "|---|---|---|---|---|---:|---|"
foreach ($row in $rows) {
    $lines += "| $($row.project) | $($row.status) | $($row.health_classification) | $($row.dns_classification) | $($row.http_classification) | $($row.http_status) | $($row.host) |"
}

$lines | Set-Content -Path $mdPath -Encoding UTF8

if (-not [string]::IsNullOrWhiteSpace($env:GITHUB_STEP_SUMMARY)) {
    $lines | Add-Content -Path $env:GITHUB_STEP_SUMMARY -Encoding UTF8
}

Write-Host "Operations report JSON: $jsonPath"
Write-Host "Operations report Markdown: $mdPath"
Write-Host "Overall classification: $overallClassification"

[pscustomobject]@{
    JsonPath = $jsonPath
    MarkdownPath = $mdPath
    OverallClassification = $overallClassification
    TotalProjects = $rows.Count
    ReviewCount = $reviewRows.Count
}
