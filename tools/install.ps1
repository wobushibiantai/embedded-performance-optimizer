param(
    [ValidateSet('agents', 'codex', 'claude', 'copilot', 'gemini', 'cursor', 'cline', 'opencode', 'windsurf', 'all')]
    [string]$Platform = 'agents',
    [ValidateSet('User', 'Project')]
    [string]$Scope = 'User'
)

$ErrorActionPreference = 'Stop'
$skillName = 'embedded-performance-optimizer'
$repoRoot = Split-Path -Parent $PSScriptRoot

function Get-SkillsRoot([string]$Target) {
    if ($Scope -eq 'Project') {
        $base = (Get-Location).Path
        switch ($Target) {
            'agents'   { return Join-Path $base '.agents\skills' }
            'codex'    { return Join-Path $base '.codex\skills' }
            'claude'   { return Join-Path $base '.claude\skills' }
            'copilot'  { return Join-Path $base '.github\skills' }
            'gemini'   { return Join-Path $base '.gemini\skills' }
            'cursor'   { return Join-Path $base '.cursor\skills' }
            'cline'    { return Join-Path $base '.cline\skills' }
            'opencode' { return Join-Path $base '.opencode\skills' }
            'windsurf' { return Join-Path $base '.agents\skills' }
        }
    }

    switch ($Target) {
        'agents'   { return Join-Path $HOME '.agents\skills' }
        'codex'    { return Join-Path $HOME '.codex\skills' }
        'claude'   { return Join-Path $HOME '.claude\skills' }
        'copilot'  { return Join-Path $HOME '.copilot\skills' }
        'gemini'   { return Join-Path $HOME '.gemini\skills' }
        'cursor'   { return Join-Path $HOME '.cursor\skills' }
        'cline'    { return Join-Path $HOME '.cline\skills' }
        'opencode' { return Join-Path $HOME '.config\opencode\skills' }
        'windsurf' { return Join-Path $HOME '.agents\skills' }
    }
}

function Install-Skill([string]$Target) {
    $skillsRoot = Get-SkillsRoot $Target
    $destination = Join-Path $skillsRoot $skillName
    New-Item -ItemType Directory -Force -Path $destination | Out-Null
    Copy-Item -LiteralPath (Join-Path $repoRoot 'SKILL.md') -Destination (Join-Path $destination 'SKILL.md') -Force
    Copy-Item -LiteralPath (Join-Path $repoRoot 'references') -Destination $destination -Recurse -Force

    if ($Target -eq 'codex') {
        Copy-Item -LiteralPath (Join-Path $repoRoot 'agents') -Destination $destination -Recurse -Force
    }

    if ($Target -eq 'windsurf' -and $Scope -eq 'Project') {
        $ruleRoot = Join-Path (Get-Location).Path '.windsurf\rules'
        New-Item -ItemType Directory -Force -Path $ruleRoot | Out-Null
        Copy-Item -LiteralPath (Join-Path $repoRoot 'adapters\windsurf-embedded-performance.md') -Destination (Join-Path $ruleRoot 'embedded-performance.md') -Force
    }

    Write-Host "Installed $Target skill at $destination"
}

$targets = if ($Platform -eq 'all') {
    @('agents', 'codex', 'claude', 'copilot', 'gemini', 'cursor', 'cline', 'opencode')
} else {
    @($Platform)
}

foreach ($target in $targets) {
    Install-Skill $target
}

if ($Platform -eq 'windsurf' -and $Scope -eq 'User') {
    Write-Warning 'The skill was placed under ~/.agents/skills. Import adapters/windsurf-embedded-performance.md in Windsurf if your version does not discover it natively.'
}
