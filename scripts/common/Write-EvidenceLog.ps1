<#
.SYNOPSIS
Writes redacted JSON evidence for GitHub Actions artifacts.
#>
param(
    [Parameter(Mandatory = $true)]
    [hashtable]$Evidence,

    [Parameter(Mandatory = $false)]
    [string]$Directory = "evidence",

    [Parameter(Mandatory = $false)]
    [string]$Prefix = "atlas-evidence"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not (Test-Path $Directory)) {
    New-Item -ItemType Directory -Path $Directory -Force | Out-Null
}

$Evidence["timestamp_utc"] = (Get-Date).ToUniversalTime().ToString("o")
$Evidence["secrets_exposed"] = $false

foreach ($key in @("authorization","Authorization","token","Token","password","Password","api_key","ApiKey","secret","Secret","headers","Headers")) {
    if ($Evidence.ContainsKey($key)) {
        $Evidence[$key] = "[REDACTED]"
    }
}

$stamp = (Get-Date).ToUniversalTime().ToString("yyyyMMdd-HHmmss")
$path = Join-Path $Directory "$Prefix-$stamp.json"

$Evidence | ConvertTo-Json -Depth 10 | Set-Content -Path $path -Encoding UTF8
Write-Host "Evidence written: $path"
return $path
