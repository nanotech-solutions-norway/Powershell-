BeforeAll {
    $RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
}

Describe "Reserved variable regression checks" {
    It "does not assign to the Host automatic variable" {
        $scripts = Get-ChildItem (Join-Path $RepoRoot "scripts") -Recurse -Filter "*.ps1"
        foreach ($script in $scripts) {
            $content = Get-Content -Path $script.FullName -Raw
            $content | Should -Not -Match '(?im)^\s*\$host\s*='
        }
    }
}
