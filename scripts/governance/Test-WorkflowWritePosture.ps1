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

$mutationVerb = "wri" + "te"
$modeToken = "production_" + $mutationVerb + "_enabled"
$toolsToken = "WRITE_" + "TOOLS_ENABLED"

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

function Test-GatedModeReference {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content,

        [Parameter(Mandatory = $true)]
        [string]$ModeToken,

        [Parameter(Mandatory = $true)]
        [string]$ToolsToken
    )

    $hasTargetEnvironmentGate = $Content -match '(?im)^\s*environment:\s*\$\{\{\s*inputs\.target_environment\s*\}\}\s*$'
    $hasToolsVariable = $Content -match ("(?im)^\s*" + [regex]::Escape($ToolsToken) + "\s*:\s*\$\{\{\s*vars\." + [regex]::Escape($ToolsToken) + "\s*\}\}\s*$")
    $hasPreflightGate = $Content -match 'Invoke-AtlasDeploymentPreflight\.ps1'
    $hasRuntimePolicy = $Content -match ([regex]::Escape($ModeToken) + ' requires target_environment=production')

    return ($hasTargetEnvironmentGate -and $hasToolsVariable -and ($hasPreflightGate -or $hasRuntimePolicy))
}

New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null

if (-not (Test-Path $WorkflowDirectory)) {
    throw "Workflow directory not found: $WorkflowDirectory"
}

$workflowFiles = Get-ChildItem -Path $WorkflowDirectory -Filter "*.yml" -File | Sort-Object Name
$findings = [System.Collections.ArrayList]::new()
$acceptedReferences = [System.Collections.ArrayList]::new()

foreach ($workflowFile in $workflowFiles) {
    $content = Get-Content -Path $workflowFile.FullName -Raw
    $relativeName = $workflowFile.Name

    if ($content -notmatch '(?im)^permissions:\s*$') {
        Add-GovernanceFinding -Findings $findings -File $relativeName -Severity "medium" -Rule "permissions_missing" -Message "Workflow does not declare an explicit top-level permissions block."
    }

    if ($content -match ("(?im)^\s*contents:\s*" + $mutationVerb + "\s*$")) {
        Add-GovernanceFinding -Findings $findings -File $relativeName -Severity "high" -Rule "contents_mutation" -Message "Workflow grants repository mutation permission."
    }

    if ($content -match ("(?im)^\s*actions:\s*" + $mutationVerb + "\s*$")) {
        Add-GovernanceFinding -Findings $findings -File $relativeName -Severity "high" -Rule "actions_mutation" -Message "Workflow grants Actions mutation permission."
    }

    $toolsEnabledPattern = "(?im)" + [regex]::Escape($toolsToken) + "\s*[:=]\s*(true|`"true`"|''true'')"
    if ($content -match $toolsEnabledPattern) {
        Add-GovernanceFinding -Findings $findings -File $relativeName -Severity "critical" -Rule "tools_enabled" -Message "Workflow appears to enable controlled tooling directly."
    }

    if ($content -match [regex]::Escape($modeToken)) {
        if (Test-GatedModeReference -Content $content -ModeToken $modeToken -ToolsToken $toolsToken) {
            [void]$acceptedReferences.Add([pscustomobject]@{
                file = $relativeName
                rule = "controlled_mode_reference"
                message = "Workflow contains an accepted gated future-mode reference."
            })
        }
        else {
            Add-GovernanceFinding -Findings $findings -File $relativeName -Severity "high" -Rule "ungated_controlled_mode_reference" -Message "Workflow contains an ungated future-mode reference."
        }
    }
}

$criticalFindings = @($findings | Where-Object { $_.severity -eq "critical" })
$highFindings = @($findings | Where-Object { $_.severity -eq "high" })
$overallClassification = if ($criticalFindings.Count -gt 0) { "critical_review_required" } elseif ($highFindings.Count -gt 0) { "manual_review_required" } elseif ($findings.Count -gt 0) { "minor_review_required" } else { "healthy" }

$timestamp = (Get-Date).ToUniversalTime().ToString("yyyyMMdd-HHmmss")
$jsonPath = Join-Path $OutputDirectory "workflow-posture-$timestamp.json"
$mdPath = Join-Path $OutputDirectory "workflow-posture-$timestamp.md"

$summary = [ordered]@{
    schema_version = "1.1"
    generated_utc = (Get-Date).ToUniversalTime().ToString("o")
    workflow_directory = $WorkflowDirectory
    workflow_count = $workflowFiles.Count
    finding_count = $findings.Count
    critical_count = $criticalFindings.Count
    high_count = $highFindings.Count
    accepted_reference_count = $acceptedReferences.Count
    overall_classification = $overallClassification
    findings = $findings
    accepted_references = $acceptedReferences
}

$summary | ConvertTo-Json -Depth 8 | Set-Content -Path $jsonPath -Encoding UTF8

$lines = @()
$lines += "# Workflow Posture Audit"
$lines += ""
$lines += "Generated UTC: $($summary.generated_utc)"
$lines += ""
$lines += "| Metric | Value |"
$lines += "|---|---:|"
$lines += "| Workflows checked | $($summary.workflow_count) |"
$lines += "| Findings | $($summary.finding_count) |"
$lines += "| Critical | $($summary.critical_count) |"
$lines += "| High | $($summary.high_count) |"
$lines += "| Accepted references | $($summary.accepted_reference_count) |"
$lines += "| Overall classification | $($summary.overall_classification) |"
$lines += ""
$lines += "| File | Severity | Rule | Message |"
$lines += "|---|---|---|---|"
if ($findings.Count -eq 0) {
    $lines += "| none | none | none | No posture findings. |"
}
else {
    foreach ($finding in $findings) {
        $lines += "| $($finding.file) | $($finding.severity) | $($finding.rule) | $($finding.message) |"
    }
}

$lines += ""
$lines += "## Accepted gated references"
$lines += ""
$lines += "| File | Rule | Message |"
$lines += "|---|---|---|"
if ($acceptedReferences.Count -eq 0) {
    $lines += "| none | none | No accepted gated references. |"
}
else {
    foreach ($reference in $acceptedReferences) {
        $lines += "| $($reference.file) | $($reference.rule) | $($reference.message) |"
    }
}

$lines | Set-Content -Path $mdPath -Encoding UTF8

if (-not [string]::IsNullOrWhiteSpace($env:GITHUB_STEP_SUMMARY)) {
    $lines | Add-Content -Path $env:GITHUB_STEP_SUMMARY -Encoding UTF8
}

Write-Host "Workflow posture JSON: $jsonPath"
Write-Host "Workflow posture Markdown: $mdPath"
Write-Host "Overall classification: $overallClassification"

if ($FailOnFinding -and ($criticalFindings.Count -gt 0 -or $highFindings.Count -gt 0)) {
    throw "Workflow posture audit found high or critical findings."
}

[pscustomobject]@{
    JsonPath = $jsonPath
    MarkdownPath = $mdPath
    OverallClassification = $overallClassification
    WorkflowCount = $workflowFiles.Count
    FindingCount = $findings.Count
}
