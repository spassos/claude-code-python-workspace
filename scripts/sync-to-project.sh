#!/usr/bin/env bash
# sync-to-project.sh — copia os commands do workspace para um projeto
# Uso: ./scripts/sync-to-project.sh /path/to/project

set -euo pipefail

WORKSPACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_DIR="${1:?Informe o caminho do projeto: ./sync-to-project.sh /path/to/project}"

if [ ! -d "$PROJECT_DIR" ]; then
  echo "Erro: diretório '$PROJECT_DIR' não encontrado."
  exit 1
fi

DEST="$PROJECT_DIR/.claude/commands"
mkdir -p "$DEST"

echo "Sincronizando commands de '$WORKSPACE_DIR' → '$DEST'..."
cp "$WORKSPACE_DIR/.claude/commands/"*.md "$DEST/"
echo "Pronto. Commands sincronizados:"
ls "$DEST/"
