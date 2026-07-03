param(
    [Parameter(Mandatory = $false)]
    [string]$HostName = "ds.atlas-ai.no",

    [Parameter(Mandatory = $false)]
    [int]$Port = 443,

    [Parameter(Mandatory = $false)]
    [string]$HttpUrl = "http://ds.atlas-ai.no/health.php",

    [Parameter(Mandatory = $false)]
    [string]$HttpsUrl = "https://ds.atlas-ai.no/health.php",

    [Parameter(Mandatory = $false)]
    [string]$OutputDirectory = "domeneshop-mcp-tls-readiness-report",

    [Parameter(Mandatory = $false)]
    [switch]$FailOnTlsNotReady
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function New-EndpointProbe {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$Uri
    )

    $record = [ordered]@{
        name = $Name
        uri = $Uri
        status_code = $null
        classification = "not_checked"
        error_summary = $null
    }

    try {
        $response = Invoke-WebRequest -Uri $Uri -Method GET -TimeoutSec 30 -UseBasicParsing -MaximumRedirection 5 -Headers @{ "User-Agent" = "AtlasAI-DomeneshopMcpTlsReadiness/1.0" }
        $record.status_code = [int]$response.StatusCode
        if ($record.status_code -ge 200 -and $record.status_code -lt 400) {
            $record.classification = "healthy"
        }
        else {
            $record.classification = "degraded"
        }
    }
    catch {
        if ($_.Exception.Response -and $_.Exception.Response.StatusCode) {
            $record.status_code = [int]$_.Exception.Response.StatusCode
        }
        $record.classification = "failed"
        $record.error_summary = $_.Exception.Message
    }

    return [pscustomobject]$record
}

function Get-TlsCertificateProbe {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ServerName,

        [Parameter(Mandatory = $true)]
        [int]$ServerPort
    )

    $probe = [ordered]@{
        host = $ServerName
        port = $ServerPort
        tcp_connected = $false
        tls_handshake = "not_attempted"
        certificate_subject = $null
        certificate_issuer = $null
        certificate_not_before_utc = $null
        certificate_not_after_utc = $null
        certificate_names = @()
        hostname_match = $false
        chain_policy_errors = @()
        ssl_policy_errors = $null
        classification = "not_checked"
        error_summary = $null
    }

    $tcpClient = $null
    $sslStream = $null

    try {
        $tcpClient = [System.Net.Sockets.TcpClient]::new()
        $connectTask = $tcpClient.ConnectAsync($ServerName, $ServerPort)
        if (-not $connectTask.Wait([TimeSpan]::FromSeconds(15))) {
            throw "TCP connection timed out."
        }
        $probe.tcp_connected = $tcpClient.Connected

        $callback = {
            param($sender, $certificate, $chain, $sslPolicyErrors)

            $script:LastTlsPolicyErrors = [string]$sslPolicyErrors
            $script:LastTlsChainErrors = @()
            if ($chain -and $chain.ChainStatus) {
                $script:LastTlsChainErrors = @($chain.ChainStatus | ForEach-Object { $_.Status.ToString() })
            }

            return $true
        }

        $sslStream = [System.Net.Security.SslStream]::new($tcpClient.GetStream(), $false, $callback)
        $sslStream.AuthenticateAsClient($ServerName)
        $probe.tls_handshake = "completed"

        $cert = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($sslStream.RemoteCertificate)
        $probe.certificate_subject = $cert.Subject
        $probe.certificate_issuer = $cert.Issuer
        $probe.certificate_not_before_utc = $cert.NotBefore.ToUniversalTime().ToString("o")
        $probe.certificate_not_after_utc = $cert.NotAfter.ToUniversalTime().ToString("o")
        $probe.ssl_policy_errors = $script:LastTlsPolicyErrors
        $probe.chain_policy_errors = @($script:LastTlsChainErrors)

        $names = @()
        foreach ($extension in $cert.Extensions) {
            if ($extension.Oid.FriendlyName -eq "Subject Alternative Name") {
                $formatted = $extension.Format($true)
                $names += ($formatted -split "`r?`n") |
                    ForEach-Object { $_.Trim() } |
                    Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
            }
        }
        $probe.certificate_names = $names

        $normalizedHost = $ServerName.ToLowerInvariant()
        $probe.hostname_match = ($cert.Subject.ToLowerInvariant() -like "*cn=$normalizedHost*") -or (($names -join "`n").ToLowerInvariant() -like "*$normalizedHost*")

        if ($probe.hostname_match -and $probe.ssl_policy_errors -eq "None") {
            $probe.classification = "tls_ready"
        }
        elseif (-not $probe.hostname_match) {
            $probe.classification = "certificate_name_mismatch"
        }
        elseif ($probe.chain_policy_errors.Count -gt 0 -or $probe.ssl_policy_errors -ne "None") {
            $probe.classification = "certificate_chain_or_policy_error"
        }
        else {
            $probe.classification = "tls_degraded"
        }
    }
    catch {
        $probe.classification = "tls_failed"
        $probe.error_summary = $_.Exception.Message
    }
    finally {
        if ($sslStream) {
            $sslStream.Dispose()
        }
        if ($tcpClient) {
            $tcpClient.Dispose()
        }
    }

    return [pscustomobject]$probe
}

New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null

$startedUtc = (Get-Date).ToUniversalTime()
$addresses = @()
$dnsClassification = "unresolved"
$dnsError = $null

try {
    $addresses = [System.Net.Dns]::GetHostAddresses($HostName) | ForEach-Object { $_.IPAddressToString }
    if ($addresses.Count -gt 0) {
        $dnsClassification = "resolved"
    }
}
catch {
    $dnsError = $_.Exception.Message
}

$httpProbe = New-EndpointProbe -Name "http-health" -Uri $HttpUrl
$httpsProbe = New-EndpointProbe -Name "https-health" -Uri $HttpsUrl
$tlsProbe = Get-TlsCertificateProbe -ServerName $HostName -ServerPort $Port

$findings = @()
if ($dnsClassification -ne "resolved") {
    $findings += "DNS did not resolve for $HostName."
}
if ($httpProbe.classification -ne "healthy") {
    $findings += "HTTP health endpoint is not healthy."
}
if ($tlsProbe.classification -ne "tls_ready") {
    $findings += "TLS is not ready: $($tlsProbe.classification)."
}
if ($httpsProbe.classification -ne "healthy") {
    $findings += "HTTPS health endpoint is not healthy."
}

$classification = if ($dnsClassification -eq "resolved" -and $httpProbe.classification -eq "healthy" -and $tlsProbe.classification -eq "tls_ready" -and $httpsProbe.classification -eq "healthy") {
    "tls_ready"
}
elseif ($dnsClassification -eq "resolved" -and $httpProbe.classification -eq "healthy") {
    "http_ready_tls_pending"
}
else {
    "not_ready"
}

$summary = [ordered]@{
    schema_version = "1.0"
    script = "Test-DomeneshopMcpTlsReadiness.ps1"
    host = $HostName
    port = $Port
    http_url = $HttpUrl
    https_url = $HttpsUrl
    write_mode = "read_only"
    dns_classification = $dnsClassification
    dns_addresses = $addresses
    dns_error = $dnsError
    classification = $classification
    findings = $findings
    http_probe = $httpProbe
    https_probe = $httpsProbe
    tls_probe = $tlsProbe
    started_utc = $startedUtc.ToString("o")
    completed_utc = (Get-Date).ToUniversalTime().ToString("o")
}

$jsonPath = Join-Path $OutputDirectory "domeneshop-mcp-tls-readiness.json"
$markdownPath = Join-Path $OutputDirectory "domeneshop-mcp-tls-readiness.md"
$summary | ConvertTo-Json -Depth 8 | Set-Content -Path $jsonPath -Encoding utf8

$lines = @()
$lines += "# Domeneshop MCP TLS Readiness"
$lines += ""
$lines += "Host: ``$HostName``"
$lines += "Classification: ``$classification``"
$lines += "Write mode: ``read_only``"
$lines += ""
$lines += "## DNS"
$lines += ""
$lines += "Classification: ``$dnsClassification``"
$lines += "Addresses: ``$($addresses -join ', ')``"
$lines += ""
$lines += "## Endpoint probes"
$lines += ""
$lines += "| Probe | URL | Status | Classification | Error |"
$lines += "|---|---|---:|---|---|"
$lines += "| HTTP health | $HttpUrl | $($httpProbe.status_code) | $($httpProbe.classification) | $($httpProbe.error_summary) |"
$lines += "| HTTPS health | $HttpsUrl | $($httpsProbe.status_code) | $($httpsProbe.classification) | $($httpsProbe.error_summary) |"
$lines += ""
$lines += "## TLS certificate"
$lines += ""
$lines += "| Field | Value |"
$lines += "|---|---|"
$lines += "| Classification | ``$($tlsProbe.classification)`` |"
$lines += "| TCP connected | ``$($tlsProbe.tcp_connected)`` |"
$lines += "| TLS handshake | ``$($tlsProbe.tls_handshake)`` |"
$lines += "| Hostname match | ``$($tlsProbe.hostname_match)`` |"
$lines += "| Policy errors | ``$($tlsProbe.ssl_policy_errors)`` |"
$lines += "| Chain errors | ``$($tlsProbe.chain_policy_errors -join ', ')`` |"
$lines += "| Subject | ``$($tlsProbe.certificate_subject)`` |"
$lines += "| Issuer | ``$($tlsProbe.certificate_issuer)`` |"
$lines += "| Not after UTC | ``$($tlsProbe.certificate_not_after_utc)`` |"

if ($findings.Count -gt 0) {
    $lines += ""
    $lines += "## Findings"
    foreach ($finding in $findings) {
        $lines += "- $finding"
    }
}

$lines | Set-Content -Path $markdownPath -Encoding utf8

Write-Host "Domeneshop MCP TLS readiness completed."
Write-Host "Classification: $classification"
Write-Host "JSON report: $jsonPath"
Write-Host "Markdown report: $markdownPath"

if ($FailOnTlsNotReady -and $classification -ne "tls_ready") {
    throw "Domeneshop MCP TLS readiness is not complete. Classification: $classification"
}
