#!/bin/bash
# Soniq installer: downloads the latest release, verifies it, installs it into Applications and opens it.
#   curl -fsSL https://raw.githubusercontent.com/webdevpls/soniq/main/install.sh | bash
set -euo pipefail

REPO="webdevpls/soniq"
BASE="https://github.com/$REPO/releases/latest/download"
CURL=(curl --proto '=https' --tlsv1.2 -fsSL)

fail() { echo "✗ $1" >&2; exit 1; }

[ "$(uname -s)" = "Darwin" ] || fail "O Soniq é só para macOS."

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "→ Baixando o Soniq…"
"${CURL[@]}" "$BASE/Soniq.zip" -o "$TMP/Soniq.zip" || fail "Não consegui baixar. Veja https://github.com/$REPO/releases"
"${CURL[@]}" "$BASE/SHA256SUMS.txt" -o "$TMP/SHA256SUMS.txt" || fail "Não consegui baixar a soma de verificação."

echo "→ Verificando a integridade do arquivo…"
EXPECTED="$(awk '$2 == "Soniq.zip" { print $1 }' "$TMP/SHA256SUMS.txt")"
ACTUAL="$(shasum -a 256 "$TMP/Soniq.zip" | awk '{ print $1 }')"
[ -n "$EXPECTED" ] && [ "$EXPECTED" = "$ACTUAL" ] || fail "A soma SHA-256 não confere. O download pode estar corrompido; nada foi instalado."

ditto -x -k "$TMP/Soniq.zip" "$TMP"
APP="$TMP/Soniq.app"
[ -d "$APP" ] || fail "O pacote baixado não contém o Soniq.app."

echo "→ Verificando a assinatura do app…"
codesign --verify --deep --strict "$APP" 2>/dev/null || fail "A assinatura do app é inválida; nada foi instalado."
[ "$(defaults read "$APP/Contents/Info" CFBundleIdentifier 2>/dev/null)" = "io.github.soniq" ] || fail "O app baixado não é o Soniq."

DEST="/Applications"
[ -w "$DEST" ] || DEST="$HOME/Applications"
mkdir -p "$DEST"

pkill -x Soniq 2>/dev/null || true
rm -rf "$DEST/Soniq.app"
ditto "$APP" "$DEST/Soniq.app"
xattr -dr com.apple.quarantine "$DEST/Soniq.app" 2>/dev/null || true

echo "✓ Soniq instalado em $DEST. Abrindo… (o ícone aparece na barra de menus)"
open "$DEST/Soniq.app"
