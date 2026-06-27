<#
.SYNOPSIS
Audits GitHub Actions workflow files for read-only write posture.
#>
param(
    [Parameter(Mandatory = $false)]
    [string]$WorkflowDirectory = ".github/workflows",

    [Parameter(Mandatory = $false)]
    [string]$OutputDirectory = "governance-report",

    [Parameter(Mandatory = $false)]
    [switch]$FailOnFinding
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Add-GovernanceFinding {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Collections.ArrayList]$Findings,

        [Parameter(Mandatory = $true)]
        [string]$File,

        [Parameter(Mandatory = $true)]
        [string]$Severity,

        [Parameter(Mandatory = $true)]
        [string]$Rule,

        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    [void]$Findings.Add([pscustomobject]@{
        file = $File
        severity = $Severity
        rule = $Rule
        message = $Message
    })
}

New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null

if (-not (Test-Path $WorkflowDirectory)) {
    throw "Workflow directory not found: $WorkflowDirectory"
}

$workflowFiles = Get-ChildItem -Path $WorkflowDirectory -Filter "*.yml" -File | Sort-Object Name
$findings = [System.Collections.ArrayList]::new()

foreach ($workflowFile in $workflowFiles) {
    $content = Get-Content -Path $workflowFile.FullName -Raw
    $relativeName = $workflowFile.Name

    if ($content -notmatch '(?im)^permissions:\s*$') {
        Add-GovernanceFinding -Findings $findings -File $relativeName -Severity "medium" -Rule "permissions_missing" -Message "Workflow does not declare an explicit top-level permissions block."
    }

    if ($content -match '(?im)^\s*contents:\s*write\s*$') {
        Add-GovernanceFinding -Findings $findings -File $relativeName -Severity "high" -Rule "contents_write" -Message "Workflow grants contents write permission."
    }

    if ($content -match '(?im)^\s*actions:\s*write\s*$') {
        Add-GovernanceFinding -Findings $findings -File $relativeName -Severity "high" -Rule "actions_write" -Message "Workflow grants actions write permission."
    }

    if ($content -match '(?im)WRITE_TOOLS_ENABLED\s*[:=]\s*(true|"true"|''true'')') {
        Add-GovernanceFinding -Findings $findings -File $relativeName -Severity "critical" -Rule "write_tools_enabled" -Message "Workflow appears to enable write tools."
    }

    if ($content -match '(?im)production_write_enabled') {
        Add-GovernanceFinding -Findings $findings -File $relativeName -Severity "high" -Rule "production_write_mode" -Message "Workflow references production write mode."
    }
}

$criticalFindings = @($findings | Where-Object { $_.severity -eq "critical" })
$highFindings = @($findings | Where-Object { $_.severity -eq "high" })
$overallClassification = if ($criticalFindings.Count -gt 0) { "critical_review_required" } elseif ($highFindings.Count -gt 0) { "manual_review_required" } elseif ($findings.Count -gt 0) { "minor_review_required" } else { "healthy" }

$timestamp = (Get-Date).ToUniversalTime().ToString("yyyyMMdd-HHmmss")
$jsonPath = Join-Path $OutputDirectory "workflow-write-posture-$timestamp.json"
$mdPath = Join-Path $OutputDirectory "workflow-write-posture-$timestamp.md"

$summary = [ordered]@{
    schema_version = "1.0"
    generated_utc = (Get-Date).ToUniversalTime().ToString("o")
    workflow_directory = $WorkflowDirectory
    workflow_count = $workflowFiles.Count
    finding_count = $findings.Count
    critical_count = $criticalFindings.Count
    high_count = $highFindings.Count
    overall_classification = $overallClassification
    findings = $findings
}

$summary | ConvertTo-Json -Depth 8 | Set-Content -Path $jsonPath -Encoding UTF8

$lines = @()
$lines += "# Workflow Write-Posture Audit"
$lines += ""
$lines += "Generated UTC: $($summary.generated_utc)"
$lines += ""
$lines += "| Metric | Value |"
$lines += "|---|---:|"
$lines += "| Workflows checked | $($summary.workflow_count) |"
$lines += "| Findings | $($summary.finding_count) |"
$lines += "| Critical | $($summary.critical_count) |"
$lines += "| High | $($summary.high_count) |"
$lines += "| Overall classification | $($summary.overall_classification) |"
$lines += ""
$lines += "| File | Severity | Rule | Message |"
$lines += "|---|---|---|---|"
if ($findings.Count -eq 0) {
    $lines += "| none | none | none | No write-posture findings. |"
}
else {
    foreach ($finding in $findings) {
        $lines += "| $($finding.file) | $($finding.severity) | $($finding.rule) | $($finding.message) |"
    }
}

$lines | Set-Content -Path $mdPath -Encoding UTF8

if (-not [string]::IsNullOrWhiteSpace($env:GITHUB_STEP_SUMMARY)) {
    $lines | Add-Content -Path $env:GITHUB_STEP_SUMMARY -Encoding UTF8
}

Write-Host "Workflow write-posture JSON: $jsonPath"
Write-Host "Workflow write-posture Markdown: $mdPath"
Write-Host "Overall classification: $overallClassification"

if ($FailOnFinding -and ($criticalFindings.Count -gt 0 -or $highFindings.Count -gt 0)) {
    throw "Workflow write-posture audit found high or critical findings."
}

[pscustomobject]@{
    JsonPath = $jsonPath
    MarkdownPath = $mdPath
    OverallClassification = $overallClassification
    WorkflowCount = $workflowFiles.Count
    FindingCount = $findings.Count
}
