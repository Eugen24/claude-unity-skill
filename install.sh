#!/usr/bin/env bash
# unity-safe install script — macOS / Linux / WSL
# Usage:
#   Global install:      ./install.sh
#   Per-project install: ./install.sh /path/to/your/unity/project

set -e

SKILL_FILE="commands/unity-safe.md"
SKILL_NAME="unity-safe.md"

# ── helpers ──────────────────────────────────────────────────────────────────

green()  { printf "\033[32m%s\033[0m\n" "$*"; }
yellow() { printf "\033[33m%s\033[0m\n" "$*"; }
red()    { printf "\033[31m%s\033[0m\n" "$*"; }
bold()   { printf "\033[1m%s\033[0m\n"  "$*"; }

# ── resolve source file ───────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE="$SCRIPT_DIR/$SKILL_FILE"

if [ ! -f "$SOURCE" ]; then
  red "Error: $SKILL_FILE not found in $SCRIPT_DIR"
  exit 1
fi

# ── determine install target ──────────────────────────────────────────────────

if [ -n "$1" ]; then
  # Per-project install
  PROJECT_DIR="$1"
  if [ ! -d "$PROJECT_DIR" ]; then
    red "Error: directory '$PROJECT_DIR' does not exist"
    exit 1
  fi
  DEST_DIR="$PROJECT_DIR/.claude/commands"
  MODE="project"
else
  # Global install
  DEST_DIR="${HOME}/.claude/commands"
  MODE="global"
fi

DEST="$DEST_DIR/$SKILL_NAME"

# ── install ───────────────────────────────────────────────────────────────────

bold "unity-safe skill installer"
echo ""

if [ "$MODE" = "global" ]; then
  yellow "Installing globally → $DEST"
  yellow "This skill will be available in every Claude Code session on this machine."
else
  yellow "Installing into project → $DEST"
  yellow "This skill will only be available inside: $PROJECT_DIR"
fi

echo ""

mkdir -p "$DEST_DIR"

if [ -f "$DEST" ]; then
  yellow "Existing file found. Backing up to ${DEST}.bak"
  cp "$DEST" "${DEST}.bak"
fi

cp "$SOURCE" "$DEST"

echo ""
green "✓ Installed: $DEST"
echo ""
bold "Usage in Claude Code:"
echo "  /unity-safe fix the dropdown crash"
echo "  /unity-safe add a new save condition"
echo "  /unity-safe audit performance in AudioManager.cs"
echo ""

# ── optional: also install overlay template ───────────────────────────────────

OVERLAY_SOURCE="$SCRIPT_DIR/examples/project-overlay.md"

if [ "$MODE" = "project" ] && [ -f "$OVERLAY_SOURCE" ]; then
  OVERLAY_DEST="$PROJECT_DIR/.claude/commands/unity.md"
  if [ ! -f "$OVERLAY_DEST" ]; then
    read -r -p "Also install the project overlay template as /unity? [y/N] " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
      cp "$OVERLAY_SOURCE" "$OVERLAY_DEST"
      green "✓ Overlay installed: $OVERLAY_DEST"
      yellow "  Edit it to describe your project's folders and tech stack."
      echo ""
    fi
  else
    yellow "Project overlay already exists at $OVERLAY_DEST — skipping."
    echo ""
  fi
fi
