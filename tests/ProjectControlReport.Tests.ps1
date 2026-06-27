BeforeAll {
    $RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
}

Describe "Project control report" {
    It "has control report workflow and converter" {
        Test-Path (Join-Path $RepoRoot ".github/workflows/manual-project-control-report.yml") | Should -BeTrue
        Test-Path (Join-Path $RepoRoot "scripts/projects/Convert-ProjectControlReport.ps1") | Should -BeTrue
    }

    It "classifies mixed-mode project operations from primary health evidence" {
        $tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("project-control-" + [guid]::NewGuid().ToString("N"))
        $evidenceDir = Join-Path $tempRoot "evidence"
        $outputDir = Join-Path $tempRoot "operations-report"

        try {
            New-Item -ItemType Directory -Path $evidenceDir -Force | Out-Null

            $items = @(
                @{ project = "atlas"; mode = "dns"; dns = "resolved"; http = "not_found"; status = 404; host = "www.atlas-ai.no" },
                @{ project = "solarex"; mode = "http"; dns = "resolved"; http = "healthy"; status = 200; host = "nanotech-solutions-norway.github.io" },
                @{ project = "domeneshop"; mode = "http"; dns = "unresolved"; http = "healthy"; status = 200; host = "forms.nanotech-solutions.com" },
                @{ project = "conta"; mode = "http"; dns = "unresolved"; http = "healthy"; status = 200; host = "mcp.atlas-ai.no" },
                @{ project = "wix"; mode = "dns"; dns = "resolved"; http = "not_found"; status = 404; host = "www.atlas-ai.no" }
            )

            foreach ($item in $items) {
                $health = [ordered]@{
                    schema_version = "1.1"
                    project = $item.project
                    script = "Get-AtlasEndpointHealth.ps1"
                    classification = "healthy"
                    check_mode = $item.mode
                    http_status = if ($item.mode -eq "http") { $item.status } else { $null }
                    host = $item.host
                }

                $diagnostics = [ordered]@{
                    schema_version = "1.1"
                    project = $item.project
                    script = "Invoke-ProjectDiagnostics.ps1"
                    dns_classification = $item.dns
                    http_classification = $item.http
                    http_status = $item.status
                    host = $item.host
                }

                $health | ConvertTo-Json -Depth 8 | Set-Content -Path (Join-Path $evidenceDir "project-health-$($item.project).json") -Encoding UTF8
                $diagnostics | ConvertTo-Json -Depth 8 | Set-Content -Path (Join-Path $evidenceDir "project-diagnostics-$($item.project).json") -Encoding UTF8
            }

            $result = & (Join-Path $RepoRoot "scripts/projects/Convert-ProjectOperationsReport.ps1") -EvidenceDirectory $evidenceDir -OutputDirectory $outputDir
            $result.OverallClassification | Should -Be "healthy"
            $result.ReviewCount | Should -Be 0

            $summary = Get-Content -Path $result.JsonPath -Raw | ConvertFrom-Json
            foreach ($row in $summary.rows) {
                $row.status | Should -Be "healthy"
                $row.review_required | Should -BeFalse
                $row.review_reason | Should -Be "none"
            }
        }
        finally {
            if (Test-Path $tempRoot) {
                Remove-Item -Path $tempRoot -Recurse -Force
            }
        }
    }
}
