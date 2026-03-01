#!/usr/bin/env bash
# sync-to-project.sh — sincroniza skills e agents do workspace para um projeto
# Uso: ./scripts/sync-to-project.sh /path/to/project

set -euo pipefail

WORKSPACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_DIR="${1:?Uso: ./sync-to-project.sh /path/to/project}"

[ -d "$PROJECT_DIR" ] || { echo "Erro: '$PROJECT_DIR' não encontrado."; exit 1; }

DEST="$PROJECT_DIR/.claude/commands"
mkdir -p "$DEST"

echo "Sincronizando skills e agents de '$WORKSPACE_DIR' → '$DEST'..."
cp "$WORKSPACE_DIR/.claude/skills/"*.md "$DEST/"
cp "$WORKSPACE_DIR/.claude/agents/"*.md "$DEST/"

echo ""
echo "Skills copiadas:"
ls "$WORKSPACE_DIR/.claude/skills/"
echo ""
echo "Agents copiados:"
ls "$WORKSPACE_DIR/.claude/agents/"
