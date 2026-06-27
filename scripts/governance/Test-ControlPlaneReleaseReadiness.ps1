<#
.SYNOPSIS
Checks that the PowerShell control-plane release file set is present.
#>
param(
    [Parameter(Mandatory = $false)]
    [string]$RepoRoot = ".",

    [Parameter(Mandatory = $false)]
    [string]$OutputDirectory = "release-readiness-report"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null

$requiredPaths = @(
    ".github/workflows/ci-powershell-quality.yml",
    ".github/workflows/manual-project-control-report.yml",
    ".github/workflows/scheduled-project-control-report.yml",
    ".github/workflows/manual-workflow-governance-audit.yml",
    ".github/workflows/scheduled-workflow-governance-audit.yml",
    "scripts/projects/Invoke-ProjectHealthCheck.ps1",
    "scripts/projects/Invoke-ProjectDiagnostics.ps1",
    "scripts/projects/Convert-ProjectOperationsReport.ps1",
    "scripts/projects/Convert-ProjectControlReport.ps1",
    "scripts/governance/Test-WorkflowWritePosture.ps1",
    "tests/ProjectControlReport.Tests.ps1",
    "tests/ScheduledControlReport.Tests.ps1",
    "tests/ScheduledAudit.Tests.ps1"
)

$items = @()
foreach ($path in $requiredPaths) {
    $fullPath = Join-Path $RepoRoot $path
    $exists = Test-Path $fullPath
    $items += [pscustomobject]@{
        path = $path
        exists = $exists
    }
}

$missingItems = @($items | Where-Object { -not $_.exists })
$overallClassification = if ($missingItems.Count -eq 0) { "ready" } else { "incomplete" }
$timestamp = (Get-Date).ToUniversalTime().ToString("yyyyMMdd-HHmmss")
$jsonPath = Join-Path $OutputDirectory "control-plane-release-readiness-$timestamp.json"
$mdPath = Join-Path $OutputDirectory "control-plane-release-readiness-$timestamp.md"

$summary = [ordered]@{
    schema_version = "1.0"
    generated_utc = (Get-Date).ToUniversalTime().ToString("o")
    total_required = $items.Count
    missing_count = $missingItems.Count
    overall_classification = $overallClassification
    items = $items
}

$summary | ConvertTo-Json -Depth 8 | Set-Content -Path $jsonPath -Encoding UTF8

$lines = @()
$lines += "# Control Plane Release Readiness"
$lines += ""
$lines += "Generated UTC: $($summary.generated_utc)"
$lines += ""
$lines += "| Metric | Value |"
$lines += "|---|---:|"
$lines += "| Required paths | $($summary.total_required) |"
$lines += "| Missing paths | $($summary.missing_count) |"
$lines += "| Overall classification | $($summary.overall_classification) |"
$lines += ""
$lines += "| Path | Exists |"
$lines += "|---|---:|"
foreach ($item in $items) {
    $lines += "| $($item.path) | $($item.exists) |"
}

$lines | Set-Content -Path $mdPath -Encoding UTF8

if (-not [string]::IsNullOrWhiteSpace($env:GITHUB_STEP_SUMMARY)) {
    $lines | Add-Content -Path $env:GITHUB_STEP_SUMMARY -Encoding UTF8
}

Write-Host "Release readiness JSON: $jsonPath"
Write-Host "Release readiness Markdown: $mdPath"
Write-Host "Overall classification: $overallClassification"

if ($missingItems.Count -gt 0) {
    throw "Control plane release readiness is incomplete."
}

[pscustomobject]@{
    JsonPath = $jsonPath
    MarkdownPath = $mdPath
    OverallClassification = $overallClassification
    MissingCount = $missingItems.Count
}
