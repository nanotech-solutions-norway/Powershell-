<#
.SYNOPSIS
Creates JSON and Markdown summaries from project diagnostics evidence files.
#>
param(
    [Parameter(Mandatory = $false)]
    [string]$EvidenceDirectory = "evidence",

    [Parameter(Mandatory = $false)]
    [string]$OutputDirectory = "diagnostics-summary",

    [Parameter(Mandatory = $false)]
    [string]$Prefix = "project-diagnostics-summary"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null

$items = @()
if (Test-Path $EvidenceDirectory) {
    $files = Get-ChildItem -Path $EvidenceDirectory -Filter "project-diagnostics-*.json" -File | Sort-Object Name
}
else {
    $files = @()
}

foreach ($file in $files) {
    try {
        $json = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
        $items += [pscustomobject]@{
            file = $file.Name
            project = $json.project
            host = $json.host
            resolved_url = $json.resolved_url
            dns_classification = $json.dns_classification
            dns_address_count = @($json.dns_addresses).Count
            http_status = $json.http_status
            http_classification = $json.http_classification
            server_header = $json.server_header
            content_type = $json.content_type
            error_summary = $json.error_summary
        }
    }
    catch {
        $items += [pscustomobject]@{
            file = $file.Name
            project = "unknown"
            host = "unknown"
            resolved_url = "unknown"
            dns_classification = "parse_error"
            dns_address_count = 0
            http_status = $null
            http_classification = "parse_error"
            server_header = $null
            content_type = $null
            error_summary = $_.Exception.Message
        }
    }
}

$reviewItems = @($items | Where-Object { $_.dns_classification -ne "resolved" -or $_.http_classification -ne "healthy" })
$overallClassification = if ($items.Count -eq 0) { "no_evidence" } elseif ($reviewItems.Count -eq 0) { "healthy" } else { "manual_review_required" }
$timestamp = (Get-Date).ToUniversalTime().ToString("yyyyMMdd-HHmmss")
$jsonPath = Join-Path $OutputDirectory "$Prefix-$timestamp.json"
$mdPath = Join-Path $OutputDirectory "$Prefix-$timestamp.md"

$summary = [ordered]@{
    schema_version = "1.0"
    generated_utc = (Get-Date).ToUniversalTime().ToString("o")
    evidence_directory = $EvidenceDirectory
    total_items = $items.Count
    review_count = $reviewItems.Count
    overall_classification = $overallClassification
    items = $items
}

$summary | ConvertTo-Json -Depth 8 | Set-Content -Path $jsonPath -Encoding UTF8

$lines = @()
$lines += "# Project Diagnostics Summary"
$lines += ""
$lines += "Generated UTC: $($summary.generated_utc)"
$lines += ""
$lines += "| Metric | Value |"
$lines += "|---|---:|"
$lines += "| Total diagnostics files | $($summary.total_items) |"
$lines += "| Review required | $($summary.review_count) |"
$lines += "| Overall classification | $($summary.overall_classification) |"
$lines += ""
$lines += "| Project | DNS | DNS addresses | HTTP | Status | Host | Content-Type |"
$lines += "|---|---|---:|---|---:|---|---|"
if ($items.Count -eq 0) {
    $lines += "| none | no_evidence | 0 | no_evidence |  |  |  |"
}
else {
    foreach ($item in $items) {
        $lines += "| $($item.project) | $($item.dns_classification) | $($item.dns_address_count) | $($item.http_classification) | $($item.http_status) | $($item.host) | $($item.content_type) |"
    }
}

$lines | Set-Content -Path $mdPath -Encoding UTF8

if (-not [string]::IsNullOrWhiteSpace($env:GITHUB_STEP_SUMMARY)) {
    $lines | Add-Content -Path $env:GITHUB_STEP_SUMMARY -Encoding UTF8
}

Write-Host "Diagnostics summary JSON: $jsonPath"
Write-Host "Diagnostics summary Markdown: $mdPath"
Write-Host "Overall classification: $($summary.overall_classification)"

[pscustomobject]@{
    JsonPath = $jsonPath
    MarkdownPath = $mdPath
    OverallClassification = $summary.overall_classification
    TotalItems = $summary.total_items
    ReviewCount = $summary.review_count
}
