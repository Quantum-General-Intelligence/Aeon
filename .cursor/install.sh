#!/usr/bin/env bash
# Idempotent Cloud Agent bootstrap for Aeon.
# Installs Bun (required runtime/bundler), project dependencies, builds the
# bundle, and installs the `aeon` CLI globally under a user-writable prefix.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# 1. Install Bun if it is not already present.
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
if ! command -v bun >/dev/null 2>&1; then
  echo "[install] Installing Bun..."
  curl -fsSL https://bun.sh/install | bash
fi
echo "[install] Bun $(bun --version)"

# 2. Install dependencies with the nested strategy so Aeon and @opentui/react
#    resolve a single React 19 runtime (see README).
echo "[install] Installing npm dependencies (nested strategy)..."
npm install --install-strategy=nested

# 3. Build the distributable bundle.
echo "[install] Building bundle..."
bun run build

# 4. Install the `aeon` CLI globally under a user-writable npm prefix and make
#    that prefix's bin available in future shells.
NPM_PREFIX="$HOME/.npm-global"
mkdir -p "$NPM_PREFIX"
npm config set prefix "$NPM_PREFIX"
export PATH="$NPM_PREFIX/bin:$PATH"
echo "[install] Installing aeon CLI globally..."
npm install -g .

# Ensure the global bin dir is on PATH for interactive shells (Bun's installer
# already adds ~/.bun/bin to ~/.bashrc).
BASHRC="$HOME/.bashrc"
PATH_LINE='export PATH="$HOME/.npm-global/bin:$PATH"'
if [ -f "$BASHRC" ] && ! grep -qF "$PATH_LINE" "$BASHRC"; then
  printf '\n# aeon global CLI\n%s\n' "$PATH_LINE" >> "$BASHRC"
fi

echo "[install] Done. aeon -> $(command -v aeon || echo 'not on PATH (use: bun run dev)')"
