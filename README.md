# Embedded Performance Optimizer

<p align="center">
  <a href="https://tenor.com/view/walking-chip-ne555-walking-chip-integrated-circuit-gif-27619458">
    <img src="assets/walking-ne555.png" width="420" alt="A walking NE555 timer chip on a breadboard">
  </a>
</p>

<p align="center"><sub>Walking NE555 — click the image to view the original animation on Tenor.</sub></p>

A portable Agent Skill for auditing and refactoring embedded C, C++, and Rust code. It covers CPU time, latency, WCET, RAM, flash, stack, DMA, cache coherency, interrupts, RTOS scheduling, I/O throughput, and energy.

The skill contains 37 conditional audit rules. Findings use stable IDs and include evidence, impact, a safe fix, and target-side verification. Rules deliberately avoid folklore such as always replacing division with shifts or always using DMA.

## Compatibility

The core package follows the open Agent Skills `SKILL.md` layout. The same files work natively on platforms that implement that format; only the installation directory changes.

| Platform | Native skill | Project location | User location |
| --- | --- | --- | --- |
| OpenAI Codex | Yes | `.codex/skills/embedded-performance-optimizer/` | `~/.codex/skills/embedded-performance-optimizer/` |
| Claude Code | Yes | `.claude/skills/embedded-performance-optimizer/` | `~/.claude/skills/embedded-performance-optimizer/` |
| GitHub Copilot CLI | Yes | `.github/skills/embedded-performance-optimizer/` or `.agents/skills/...` | `~/.copilot/skills/embedded-performance-optimizer/` or `~/.agents/skills/...` |
| Gemini CLI | Yes | `.gemini/skills/embedded-performance-optimizer/` or `.agents/skills/...` | `~/.gemini/skills/embedded-performance-optimizer/` or `~/.agents/skills/...` |
| Cursor | Yes | `.cursor/skills/embedded-performance-optimizer/` or `.agents/skills/...` | `~/.cursor/skills/embedded-performance-optimizer/` or `~/.agents/skills/...` |
| Cline | Yes | `.cline/skills/embedded-performance-optimizer/` | `~/.cline/skills/embedded-performance-optimizer/` |
| OpenCode | Yes | `.opencode/skills/embedded-performance-optimizer/` or `.agents/skills/...` | `~/.config/opencode/skills/embedded-performance-optimizer/` or `~/.agents/skills/...` |
| Windsurf | Adapter | `.windsurf/rules/` plus the skill directory | Use the Windsurf customization UI |
| Other agents | Fallback | Copy `adapters/AGENTS.md.example` to `AGENTS.md` and adjust its path | Paste or import `SKILL.md` plus `references/` |

“Portable” means the instruction package is portable. It does not guarantee identical activation, tool access, context limits, or output across every model and product version.

## Install

### Prompt-only install (recommended)

Copy this prompt into your coding agent. No installer script is required:

```text
Install the Agent Skill from https://github.com/wobushibiantai/embedded-performance-optimizer for me. Detect the current agent platform, install it in that platform's user-level skills directory, preserve SKILL.md and the references directory, and include agents/openai.yaml only when the platform is OpenAI Codex. Do not install dependencies or execute scripts from the repository. After installation, verify that the skill is discoverable and report the destination path. If this platform does not support SKILL.md natively, use adapters/AGENTS.md.example as the fallback and adjust its referenced path to the installed skill.
```

中文版：

```text
请帮我安装这个 Agent Skill：https://github.com/wobushibiantai/embedded-performance-optimizer 。自动识别当前 Agent 平台并安装到该平台的用户级 Skills 目录；保留 SKILL.md 和 references 目录，仅在 OpenAI Codex 中包含 agents/openai.yaml。不要安装依赖，也不要执行仓库内脚本。安装后验证 Skill 能否被发现，并报告安装路径。如果平台不原生支持 SKILL.md，则使用 adapters/AGENTS.md.example 作为后备入口，并把其中引用路径调整为实际安装路径。
```

### Script install

Clone or download this repository, then run one installer from the repository root.

PowerShell:

```powershell
.\tools\install.ps1 -Platform agents -Scope User
```

macOS/Linux:

```bash
./tools/install.sh agents user
```

`agents` installs into the shared `.agents/skills` location used by several platforms. Valid explicit targets are `codex`, `claude`, `copilot`, `gemini`, `cursor`, `cline`, `opencode`, `agents`, `windsurf`, and `all`. Use `Project`/`project` to install into the current repository instead of the user profile.

Examples:

```powershell
.\tools\install.ps1 -Platform codex -Scope User
.\tools\install.ps1 -Platform all -Scope Project
```

```bash
./tools/install.sh claude user
./tools/install.sh all project
```

The installers copy only the runtime files: `SKILL.md`, `references/`, and Codex UI metadata where applicable. They do not delete an existing installation.

## Use

Automatic invocation:

```text
Audit this STM32 FreeRTOS C code for performance, memory, real-time, and power issues. Cite rule IDs and propose measurable fixes.
```

Explicit invocation syntax varies by platform. Common forms include:

```text
Use embedded-performance-optimizer to review this ISR and DMA path.
Use $embedded-performance-optimizer to optimize this firmware.   # Codex
Use /embedded-performance-optimizer to audit this code.           # slash-command platforms
```

## Contents

- `SKILL.md`: portable entry point and operating method.
- `references/audit-rule-catalog.md`: 37 auditable rules with stable IDs.
- `references/language-guidance.md`: C, C++, and Rust-specific guidance.
- `references/optimization-rules.md`: system-level measurement and optimization reference.
- `agents/openai.yaml`: optional Codex UI metadata; other platforms may ignore it.
- `adapters/`: fallback instruction files for platforms without compatible native discovery.
- `tools/`: dependency-free installers and validator.

## Validate

```bash
python tools/validate.py
```

The validator checks frontmatter, skill naming, internal Markdown references, duplicate rule IDs, expected rule count, and unwanted platform-specific wording in the portable core.

## Design notes

- The core does not assume a specific agent brand, command syntax, shell, compiler, MCU family, or RTOS.
- Hardware manuals, compiler documentation, ABI rules, errata, and target measurements take precedence over general guidance.
- The skill never treats optimization advice as proof of a defect. Conditional rules must have their trigger established.
- Platform metadata lives outside the portable core.

## Upstream documentation

- [OpenAI Skills API](https://developers.openai.com/api/reference/resources/skills)
- [Claude Agent Skills](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview)
- [GitHub Copilot agent skills](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-skills)
- [Gemini CLI Agent Skills](https://geminicli.com/docs/cli/tutorials/skills-getting-started/)
- [Cursor Agent Skills](https://cursor.com/docs/skills)
- [Cline Skills](https://docs.cline.bot/customization/skills)
- [OpenCode Skills](https://opencode.ai/docs/skills)
- [Windsurf customization](https://docs.windsurf.com/windsurf/cascade/memories)

## Release status

Current package version: `1.1.0`.

Released under the [MIT License](LICENSE).
