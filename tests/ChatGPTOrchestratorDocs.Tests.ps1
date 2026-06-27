BeforeAll {
    $RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
}

Describe "ChatGPT orchestrator docs" {
    It "has ChatGPT orchestrator instructions" {
        Test-Path (Join-Path $RepoRoot "docs/CHATGPT_ORCHESTRATOR_COMMANDS.md") | Should -BeTrue
        Test-Path (Join-Path $RepoRoot "docs/CHATGPT_PROJECT_FOLDER_INSTRUCTIONS.md") | Should -BeTrue
    }
}
