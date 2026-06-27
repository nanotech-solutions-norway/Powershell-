<#
.SYNOPSIS
Creates a consolidated control report from project operations and workflow governance outputs.
#>
param(
    [Parameter(Mandatory = $false)]
    [string]$OperationsReportDirectory = "operations-report",

    [Parameter(Mandatory = $false)]
    [string]$GovernanceReportDirectory = "governance-report",

    [Parameter(Mandatory = $false)]
    [string]$OutputDirectory = "control-report",

    [Parameter(Mandatory = $false)]
    [string]$Prefix = "project-control-report"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-LatestJson {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Directory,

        [Parameter(Mandatory = $true)]
        [string]$Filter
    )

    if (-not (Test-Path $Directory)) {
        return $null
    }

    return Get-ChildItem -Path $Directory -Filter $Filter -File | Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 1
}

New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null

$operationsFile = Get-LatestJson -Directory $OperationsReportDirectory -Filter "*.json"
$governanceFile = Get-LatestJson -Directory $GovernanceReportDirectory -Filter "*.json"

$operations = if ($operationsFile) { Get-Content -Path $operationsFile.FullName -Raw | ConvertFrom-Json } else { $null }
$governance = if ($governanceFile) { Get-Content -Path $governanceFile.FullName -Raw | ConvertFrom-Json } else { $null }

$operationsClassification = if ($operations) { [string]$operations.overall_classification } else { "missing" }
$governanceClassification = if ($governance) { [string]$governance.overall_classification } else { "missing" }
$operationsReviewCount = if ($operations) { [int]$operations.review_count } else { 0 }
$governanceFindingCount = if ($governance) { [int]$governance.finding_count } else { 0 }

$reviewRequired = $operationsClassification -ne "healthy" -or $governanceClassification -ne "healthy"
$overallClassification = if ($reviewRequired) { "manual_review_required" } else { "healthy" }

$timestamp = (Get-Date).ToUniversalTime().ToString("yyyyMMdd-HHmmss")
$jsonPath = Join-Path $OutputDirectory "$Prefix-$timestamp.json"
$mdPath = Join-Path $OutputDirectory "$Prefix-$timestamp.md"

$summary = [ordered]@{
    schema_version = "1.0"
    generated_utc = (Get-Date).ToUniversalTime().ToString("o")
    overall_classification = $overallClassification
    operations_report = if ($operationsFile) { $operationsFile.Name } else { $null }
    governance_report = if ($governanceFile) { $governanceFile.Name } else { $null }
    operations_classification = $operationsClassification
    operations_review_count = $operationsReviewCount
    governance_classification = $governanceClassification
    governance_finding_count = $governanceFindingCount
}

$summary | ConvertTo-Json -Depth 8 | Set-Content -Path $jsonPath -Encoding UTF8

$lines = @()
$lines += "# Project Control Report"
$lines += ""
$lines += "Generated UTC: $($summary.generated_utc)"
$lines += ""
$lines += "| Metric | Value |"
$lines += "|---|---:|"
$lines += "| Overall classification | $($summary.overall_classification) |"
$lines += "| Operations classification | $($summary.operations_classification) |"
$lines += "| Operations review count | $($summary.operations_review_count) |"
$lines += "| Governance classification | $($summary.governance_classification) |"
$lines += "| Governance finding count | $($summary.governance_finding_count) |"
$lines += ""
$lines += "| Source | File |"
$lines += "|---|---|"
$lines += "| Operations report | $($summary.operations_report) |"
$lines += "| Governance report | $($summary.governance_report) |"

$lines | Set-Content -Path $mdPath -Encoding UTF8

if (-not [string]::IsNullOrWhiteSpace($env:GITHUB_STEP_SUMMARY)) {
    $lines | Add-Content -Path $env:GITHUB_STEP_SUMMARY -Encoding UTF8
}

Write-Host "Control report JSON: $jsonPath"
Write-Host "Control report Markdown: $mdPath"
Write-Host "Overall classification: $overallClassification"

[pscustomobject]@{
    JsonPath = $jsonPath
    MarkdownPath = $mdPath
    OverallClassification = $overallClassification
    OperationsClassification = $operationsClassification
    GovernanceClassification = $governanceClassification
}
