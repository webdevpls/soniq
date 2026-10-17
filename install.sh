#!/bin/bash
# Soniq installer: downloads the latest release, installs it into Applications and opens it.
#   curl -fsSL https://raw.githubusercontent.com/webdevpls/soniq/main/install.sh | bash
set -euo pipefail

REPO="webdevpls/soniq"
echo "→ Procurando a última versão do Soniq…"
URL="$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" \
  | grep -o '"browser_download_url": *"[^"]*\.zip"' | head -1 | cut -d'"' -f4)"
[ -n "$URL" ] || { echo "Não encontrei o download. Veja https://github.com/$REPO/releases"; exit 1; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
echo "→ Baixando $(basename "$URL")…"
curl -fsSL "$URL" -o "$TMP/Soniq.zip"
ditto -x -k "$TMP/Soniq.zip" "$TMP"

DEST="/Applications"
[ -w "$DEST" ] || DEST="$HOME/Applications"
mkdir -p "$DEST"

pkill -x Soniq 2>/dev/null || true
rm -rf "$DEST/Soniq.app"
ditto "$TMP/Soniq.app" "$DEST/Soniq.app"
xattr -dr com.apple.quarantine "$DEST/Soniq.app" 2>/dev/null || true

echo "✓ Soniq instalado em $DEST. Abrindo… (o ícone aparece na barra de menus)"
open "$DEST/Soniq.app"
