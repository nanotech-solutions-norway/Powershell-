param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("atlas","solarex","domeneshop","conta","wix")]
    [string]$Project,

    [Parameter(Mandatory = $false)]
    [string]$BaseUrl = "",

    [Parameter(Mandatory = $false)]
    [string]$Path = "",

    [Parameter(Mandatory = $false)]
    [ValidateSet("dns","http")]
    [string]$CheckMode = "",

    [Parameter(Mandatory = $false)]
    [ValidateSet("development","staging","production")]
    [string]$TargetEnvironment = "development",

    [Parameter(Mandatory = $false)]
    [switch]$FailOnUnhealthy
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "../..")
$healthScriptPath = Join-Path $repoRoot "scripts/atlas/Get-AtlasEndpointHealth.ps1"

if (-not (Test-Path $healthScriptPath)) {
    throw "Required health script not found: $healthScriptPath"
}

$defaults = @{
    atlas = @{
        BaseUrl = "https://www.atlas-ai.no"
        Path = "/"
        CheckMode = "dns"
        ProjectLabel = "Atlas AI"
    }
    solarex = @{
        BaseUrl = "https://nanotech-solutions-norway.github.io/SolarEX-Final-recreate/"
        Path = "/"
        CheckMode = "http"
        ProjectLabel = "SolarEX"
    }
    domeneshop = @{
        BaseUrl = "https://forms.nanotech-solutions.com"
        Path = "/solarex_forms/health.php"
        CheckMode = "http"
        ProjectLabel = "Domeneshop Forms"
    }
    conta = @{
        BaseUrl = "https://mcp.atlas-ai.no"
        Path = "/health"
        CheckMode = "http"
        ProjectLabel = "Conta MCP"
    }
    wix = @{
        BaseUrl = "https://www.atlas-ai.no"
        Path = "/"
        CheckMode = "dns"
        ProjectLabel = "Wix Atlas"
    }
}

$selected = $defaults[$Project]

if ([string]::IsNullOrWhiteSpace($BaseUrl)) {
    $BaseUrl = $selected.BaseUrl
}

if ([string]::IsNullOrWhiteSpace($Path)) {
    $Path = $selected.Path
}

if ([string]::IsNullOrWhiteSpace($CheckMode)) {
    $CheckMode = $selected.CheckMode
}

Write-Host "Project health check"
Write-Host "Project: $Project"
Write-Host "ProjectLabel: $($selected.ProjectLabel)"
Write-Host "BaseUrl: $BaseUrl"
Write-Host "Path: $Path"
Write-Host "CheckMode: $CheckMode"
Write-Host "TargetEnvironment: $TargetEnvironment"

$params = @{
    BaseUrl = $BaseUrl
    Path = $Path
    ProjectKey = $Project
    ProjectLabel = $selected.ProjectLabel
    CheckMode = $CheckMode
    TargetEnvironment = $TargetEnvironment
    WriteMode = "read_only"
}

if ($FailOnUnhealthy) {
    $params.FailOnUnhealthy = $true
}

& $healthScriptPath @params
