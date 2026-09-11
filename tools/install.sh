#!/usr/bin/env sh
set -eu

platform="${1:-agents}"
scope="${2:-user}"
skill_name="embedded-performance-optimizer"
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(dirname "$script_dir")

case "$platform" in
  agents|codex|claude|copilot|gemini|cursor|cline|opencode|windsurf|all) ;;
  *) echo "Unsupported platform: $platform" >&2; exit 2 ;;
esac

case "$scope" in
  user|project) ;;
  *) echo "Scope must be user or project" >&2; exit 2 ;;
esac

skills_root() {
  target="$1"
  if [ "$scope" = "project" ]; then
    case "$target" in
      agents|windsurf) printf '%s/.agents/skills' "$PWD" ;;
      codex) printf '%s/.codex/skills' "$PWD" ;;
      claude) printf '%s/.claude/skills' "$PWD" ;;
      copilot) printf '%s/.github/skills' "$PWD" ;;
      gemini) printf '%s/.gemini/skills' "$PWD" ;;
      cursor) printf '%s/.cursor/skills' "$PWD" ;;
      cline) printf '%s/.cline/skills' "$PWD" ;;
      opencode) printf '%s/.opencode/skills' "$PWD" ;;
    esac
  else
    case "$target" in
      agents|windsurf) printf '%s/.agents/skills' "$HOME" ;;
      codex) printf '%s/.codex/skills' "$HOME" ;;
      claude) printf '%s/.claude/skills' "$HOME" ;;
      copilot) printf '%s/.copilot/skills' "$HOME" ;;
      gemini) printf '%s/.gemini/skills' "$HOME" ;;
      cursor) printf '%s/.cursor/skills' "$HOME" ;;
      cline) printf '%s/.cline/skills' "$HOME" ;;
      opencode) printf '%s/.config/opencode/skills' "$HOME" ;;
    esac
  fi
}

install_one() {
  target="$1"
  root=$(skills_root "$target")
  destination="$root/$skill_name"
  mkdir -p "$destination"
  cp "$repo_root/SKILL.md" "$destination/SKILL.md"
  mkdir -p "$destination/references"
  cp "$repo_root"/references/*.md "$destination/references/"

  if [ "$target" = "codex" ]; then
    mkdir -p "$destination/agents"
    cp "$repo_root/agents/openai.yaml" "$destination/agents/openai.yaml"
  fi

  if [ "$target" = "windsurf" ] && [ "$scope" = "project" ]; then
    mkdir -p "$PWD/.windsurf/rules"
    cp "$repo_root/adapters/windsurf-embedded-performance.md" "$PWD/.windsurf/rules/embedded-performance.md"
  fi

  printf 'Installed %s skill at %s\n' "$target" "$destination"
}

if [ "$platform" = "all" ]; then
  for target in agents codex claude copilot gemini cursor cline opencode; do
    install_one "$target"
  done
else
  install_one "$platform"
fi

if [ "$platform" = "windsurf" ] && [ "$scope" = "user" ]; then
  echo 'The skill was placed under ~/.agents/skills. Import adapters/windsurf-embedded-performance.md in Windsurf if your version does not discover it natively.' >&2
fi
