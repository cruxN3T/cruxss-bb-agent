#!/usr/bin/env bash
# bb-agent-setup.sh — Install all required tools for the bug bounty agent
# Run once before first use: bash bb-agent-setup.sh

set -e

echo "=== Bug Bounty Agent — Tool Setup ==="
echo ""

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
  OS="mac"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  OS="linux"
else
  echo "Unsupported OS: $OSTYPE"
  exit 1
fi

echo "[*] OS: $OS"
echo ""

# --- Go tools ---
echo "[*] Installing Go-based tools..."

GO_TOOLS=(
  "github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
  "github.com/projectdiscovery/httpx/cmd/httpx@latest"
  "github.com/projectdiscovery/dnsx/cmd/dnsx@latest"
  "github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest"
  "github.com/projectdiscovery/katana/cmd/katana@latest"
  "github.com/projectdiscovery/interactsh/cmd/interactsh-client@latest"
  "github.com/tomnomnom/waybackurls@latest"
  "github.com/lc/gau/v2/cmd/gau@latest"
  "github.com/tomnomnom/anew@latest"
  "github.com/tomnomnom/qsreplace@latest"
  "github.com/tomnomnom/assetfinder@latest"
  "github.com/tomnomnom/gf@latest"
  "github.com/hahwul/dalfox/v2@latest"
  "github.com/ffuf/ffuf/v2@latest"
  "github.com/LukaSikic/subzy@latest"
  "github.com/assetnote/kiterunner/cmd/kr@latest"
)

for tool in "${GO_TOOLS[@]}"; do
  name=$(basename "$tool" | cut -d@ -f1)
  echo -n "  Installing $name... "
  go install "$tool" 2>/dev/null && echo "OK" || echo "FAILED (check Go install)"
done

# --- Python tools ---
echo ""
echo "[*] Installing Python-based tools..."

PIP_TOOLS=(
  "arjun"
  "paramspider"
  "semgrep"
)

for tool in "${PIP_TOOLS[@]}"; do
  echo -n "  Installing $tool... "
  pip3 install "$tool" --quiet && echo "OK" || echo "FAILED"
done

# --- Brew tools (Mac only) ---
if [[ "$OS" == "mac" ]]; then
  echo ""
  echo "[*] Installing Homebrew tools..."
  for tool in trufflehog gitleaks sqlmap; do
    echo -n "  Installing $tool... "
    brew install "$tool" --quiet 2>/dev/null && echo "OK" || echo "FAILED"
  done
fi

# --- SecLists wordlists ---
echo ""
echo "[*] Checking SecLists..."
if [[ ! -d "$HOME/wordlists/SecLists" ]]; then
  echo "  Cloning SecLists to ~/wordlists/SecLists (this takes a minute)..."
  mkdir -p "$HOME/wordlists"
  git clone --depth 1 https://github.com/danielmiessler/SecLists.git \
    "$HOME/wordlists/SecLists" --quiet
  echo "  Done."
else
  echo "  SecLists already present at ~/wordlists/SecLists"
fi

# --- Nuclei templates ---
echo ""
echo "[*] Updating nuclei templates..."
nuclei -update-templates -silent 2>/dev/null || true

# --- Verify ---
echo ""
echo "=== Tool Check ==="
TOOLS=(subfinder httpx dnsx nuclei katana waybackurls gau anew ffuf dalfox subzy)
for tool in "${TOOLS[@]}"; do
  if command -v "$tool" &> /dev/null; then
    echo "  [OK] $tool"
  else
    echo "  [MISSING] $tool — check your PATH (~/.local/bin or ~/go/bin)"
  fi
done

echo ""
echo "=== Setup complete. Run: claude --add-dir . ==="
echo "Then use: /bb-agent start <target>"
