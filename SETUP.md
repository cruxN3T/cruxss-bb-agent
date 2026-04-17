# CRUXSS Setup Guide

Complete walkthrough to build the CRUXSS bug bounty agent from scratch.

**Environment:** Windows host + Kali Linux VirtualBox VM + Obsidian on Windows

If you have a different setup (native Linux, macOS, WSL) the stages from
Stage 4 onward are identical — only the VirtualBox shared folder section
differs.

---

## What You'll Have When Done

```
Windows Host                        Kali VM
────────────────────                ──────────────────────────────
Obsidian (GUI note viewer)          Claude Code + /bb-agent
C:\vaults\cruxss  ←─shared─────→  /vaults/cruxss
                    folder          │
                                    ├── phases/        (methodology)
                                    ├── session/       (live hunt notes)
                                    └── checklists/    (CRUXSS xlsx)

GitHub
────────────────────
github.com/YOU/cruxss-bb-agent    (public — methodology)
github.com/YOU/cruxss-sessions    (private — real findings)
```

The shared folder means Obsidian on Windows sees everything the Kali agent
writes in real time — no sync step, no copying.

---

## Prerequisites

| Tool | Where | Notes |
|---|---|---|
| VirtualBox | Windows | virtualbox.org |
| Kali Linux VM | VirtualBox | kali.org/get-kali |
| Obsidian | Windows | obsidian.md — free |
| Claude Code | Kali | via npm |
| Go 1.21+ | Kali | golang.org or apt |
| Python 3.10+ | Kali | usually pre-installed on Kali |
| Node 22+ | Kali | via nodesource |
| Git | Kali | usually pre-installed on Kali |
| GitHub account | Browser | github.com |

---

## Stage 1 — Windows: Create the Vault Folder

Open PowerShell as Administrator and run:

```powershell
$base = "C:\vaults\cruxss"
@(
  "",
  "phases\03-hunt",
  "session\leads",
  "session\bugs",
  "session\chains",
  "session\reports",
  "checklists",
  "examples"
) | ForEach-Object { New-Item -ItemType Directory -Force "$base\$_" }

Write-Host "Done:"
Get-ChildItem -Recurse "C:\vaults\cruxss" | Select-Object FullName
```

You should see all subfolders created under `C:\vaults\cruxss`.

---

## Stage 2 — VirtualBox: Shared Folder

This makes `C:\vaults\cruxss` on Windows and `/vaults/cruxss` in Kali
point to the exact same files — live, no syncing needed.

### 2.1 — Configure in VirtualBox Manager

**Shut down your Kali VM completely** (not save state — full shutdown).

In VirtualBox Manager on Windows:
**Settings → Shared Folders → click the folder+ icon**

| Field | Value |
|---|---|
| Folder Path | `C:\vaults\cruxss` |
| Folder Name | `cruxss` |
| Mount Point | `/vaults/cruxss` |
| Auto-mount | ✅ checked |
| Make Permanent | ✅ checked |
| Read-only | ❌ unchecked |

Click OK → OK. Start your Kali VM.

### 2.2 — Install guest utilities and add user to vboxsf group

```bash
sudo apt update && sudo apt install -y virtualbox-guest-utils
sudo usermod -aG vboxsf $USER
sudo mkdir -p /vaults/cruxss
```

Apply the group change without rebooting:
```bash
newgrp vboxsf
```

### 2.3 — Mount the shared folder

```bash
# Get your uid and gid
id $USER
# Note the uid= and gid= numbers (usually 1000)

# Mount with your uid/gid (replace 1000 if yours differ)
sudo mount -t vboxsf -o rw,uid=1000,gid=1000,umask=0022 cruxss /vaults/cruxss
```

Fix permissions on the mount point if needed:
```bash
sudo chmod 755 /vaults
sudo chmod 755 /vaults/cruxss
```

Verify:
```bash
ls /vaults/cruxss
# Should show: checklists  examples  phases  session
```

### 2.4 — Make it permanent across reboots

First clean any duplicate entries from earlier attempts:
```bash
sudo cp /etc/fstab /etc/fstab.backup
sudo grep -v "vboxsf" /etc/fstab | sudo tee /etc/fstab.tmp
sudo mv /etc/fstab.tmp /etc/fstab
```

Add the correct single entry (replace 1000 with your actual uid/gid):
```bash
echo "cruxss /vaults/cruxss vboxsf rw,uid=1000,gid=1000,umask=0022,_netdev 0 0" | sudo tee -a /etc/fstab
```

Verify fstab:
```bash
cat /etc/fstab
# Should show one vboxsf line at the bottom
```

### 2.5 — Reboot and verify

```bash
sudo reboot
```

After reboot:
```bash
ls /vaults/cruxss
mount | grep vboxsf
```

Both should work without sudo. `mount | grep vboxsf` should show exactly
one line.

### 2.6 — Fix zsh history warning (Kali-specific)

If you see `zsh: corrupt history file` on every terminal open:
```bash
rm ~/.zsh_history && touch ~/.zsh_history
```

---

## Stage 3 — Windows: Install Obsidian

1. Download Obsidian from **obsidian.md** and install it
2. Open Obsidian → **Open folder as vault**
3. Navigate to `C:\vaults\cruxss` → click **Open**

You should see the vault load with your folder structure in the left sidebar.

**Verify live sync is working:**

In Kali:
```bash
echo "# Test note from Kali" > /vaults/cruxss/test.md
```

Switch to Obsidian on Windows — `test.md` should appear instantly.

Clean up:
```bash
rm /vaults/cruxss/test.md
```

---

## Stage 4 — Kali: Verify Core Tools

```bash
echo "=== Core ===" && \
go version && \
python3 --version && \
claude --version && \
git --version && \
node --version && \
echo "" && \
echo "=== Recon tools ===" && \
for tool in subfinder httpx dnsx nuclei ffuf katana dalfox waybackurls anew gau; do
  which $tool &>/dev/null && echo "✅ $tool" || echo "❌ $tool missing"
done
```

### Install missing Go tools

```bash
go install github.com/projectdiscovery/dnsx/cmd/dnsx@latest
go install github.com/projectdiscovery/katana/cmd/katana@latest
go install github.com/hahwul/dalfox/v2@latest
go install github.com/tomnomnom/waybackurls@latest
go install github.com/tomnomnom/anew@latest
go install github.com/lc/gau/v2/cmd/gau@latest
```

Make sure Go binaries are in your PATH:
```bash
echo 'export PATH=$PATH:$(go env GOPATH)/bin' >> ~/.bashrc
source ~/.bashrc
```

### Install Node 22 if missing or outdated

```bash
node --version
# If below 18 or missing:
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo bash -
sudo apt install -y nodejs
```

### Install Claude Code if missing

```bash
npm install -g @anthropic/claude-code
claude login
```

Run the tool check again — all 10 should be green before continuing.

---

## Stage 5 — GitHub: Create Two Repos

You need two repos — one public for the methodology, one private for
your real findings. Do this at github.com.

### Public repo
- Name: `cruxss-bb-agent`
- Visibility: **Public**
- Do NOT initialize with README, .gitignore, or license

### Private repo
- Name: `cruxss-sessions`
- Visibility: **Private**
- Do NOT initialize with anything

### Configure git in Kali

```bash
git config --global user.name "Your Name"
git config --global user.email "your-github-email@example.com"
git config --global credential.helper store
```

### Initialize both repos from Kali

```bash
# Public repo
cd /vaults/cruxss
git init
git remote add origin https://github.com/YOURUSERNAME/cruxss-bb-agent.git

# Private sessions repo
cd /vaults/cruxss/session
git init
git remote add origin https://github.com/YOURUSERNAME/cruxss-sessions.git
cd /vaults/cruxss
```

Verify:
```bash
echo "=== Public ===" && cd /vaults/cruxss && git remote -v
echo "=== Sessions ===" && cd /vaults/cruxss/session && git remote -v
```

---

## Stage 6 — Drop Agent Files Into the Vault

Since `C:\vaults\cruxss` and `/vaults/cruxss` are the same folder,
copy the downloaded agent files into `C:\vaults\cruxss` using Windows
Explorer. They appear in Kali instantly.

Expected structure:
```
/vaults/cruxss/
├── CLAUDE.md
├── README.md
├── bb-agent.md
├── bb-agent-setup.sh
├── phases/
│   ├── 01-recon.md
│   ├── 02-learn.md
│   ├── 03-hunt.md
│   ├── 04-validate.md
│   └── 05-report.md
└── checklists/
    ├── CRUXSS_WebApp_Pentest_Checklist.xlsx
    ├── CRUXSS_API_Pentest_Checklist.xlsx
    ├── CRUXSS_Cloud_Pentest_Checklist.xlsx
    ├── CRUXSS_Network_External_Checklist.xlsx
    └── CRUXSS_Network_Internal_Checklist.xlsx
```

Verify in Kali:
```bash
ls /vaults/cruxss/phases/
ls /vaults/cruxss/checklists/
```

---

## Stage 7 — Split Hunt File + Update CLAUDE.md

### Split 03-hunt.md into individual topic files

This is the token-saving step. Instead of loading the entire hunt file
into context, the agent loads only the relevant topic file per session.

```bash
cat << 'SPLITTER' > /vaults/cruxss/phases/split-hunt.sh
#!/bin/bash
SRC=/vaults/cruxss/phases/03-hunt.md
OUT=/vaults/cruxss/phases/03-hunt
mkdir -p "$OUT"

awk -v out="$OUT" '
/^## 3[A-Z]\./ {
  if (file) close(file)
  header = $0
  gsub(/^## /, "", header)
  gsub(/[^a-zA-Z0-9]/, "-", header)
  gsub(/-+/, "-", header)
  gsub(/^-|-$/, "", header)
  file = out "/" tolower(header) ".md"
}
file { print > file }
' "$SRC"

echo "Split complete:"
ls -1 "$OUT/"
SPLITTER

chmod +x /vaults/cruxss/phases/split-hunt.sh
bash /vaults/cruxss/phases/split-hunt.sh
```

### Add vault reading rules to CLAUDE.md

```bash
cat << 'EOF' >> /vaults/cruxss/CLAUDE.md

---

## Knowledge Base — Token-Efficient Reading

Vault path: /vaults/cruxss/
Never load 03-hunt.md as a whole file.
Never load all phase files at session start.
Load one phase file per phase. Load individual 03-hunt/ topic files on demand.

### Reading rules
# One vuln class:
cat /vaults/cruxss/phases/03-hunt/<topic>.md

# Find by CRUXSS-ID:
grep -r "CRUXSS-<ID>" /vaults/cruxss/phases/

# Search by keyword:
grep -ril "<keyword>" /vaults/cruxss/phases/03-hunt/

# List available topics:
ls /vaults/cruxss/phases/03-hunt/

### Session notes — always append, never overwrite
echo "- [$(date +%H:%M)] [CRUXSS-ID] <note>" >> /vaults/cruxss/session/SESSION.md

### Phase load order
Phase 1 → phases/01-recon.md only
Phase 2 → phases/02-learn.md only
Phase 3 → phases/03-hunt/<relevant-topic>.md on demand
Phase 4 → phases/04-validate.md only
Phase 5 → phases/05-report.md only
EOF
```

---

## Stage 8 — Security Hardening

### Check where Claude Code stores your API key

```bash
# Should be in ~/.claude/ only — never in your vault
cat ~/.claude/config.json 2>/dev/null | grep -i "api\|key\|token" \
  && echo "Key found in Claude config (correct)" || echo "Not here"

# Confirm key is NOT in vault
grep -r "sk-ant" /vaults/cruxss/ 2>/dev/null \
  && echo "⚠ FOUND IN VAULT - fix before pushing" \
  || echo "✅ Clean - key not in vault"
```

### Create .gitignore

```bash
cat << 'EOF' > /vaults/cruxss/.gitignore
# Secrets
.env
.env.*
*.key
*.pem
*.p12
*.pfx
secrets.json
*_credentials*
*_secret*

# Tool output with potential target data
*.nessus
nuclei-output/
nmap-output/

# OS noise
.DS_Store
Thumbs.db
desktop.ini

# Obsidian personal state (not methodology)
.obsidian/workspace.json
.obsidian/workspace-mobile.json
.obsidian/plugins/
.obsidian/themes/
EOF
```

### Install pre-commit secret scanner

```bash
pip3 install pre-commit detect-secrets --break-system-packages

cat << 'EOF' > /vaults/cruxss/.pre-commit-config.yaml
repos:
  - repo: https://github.com/Yelp/detect-secrets
    rev: v1.4.0
    hooks:
      - id: detect-secrets
        args: ['--baseline', '.secrets.baseline']
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: detect-private-key
      - id: check-added-large-files
        args: ['--maxkb=500']
      - id: check-merge-conflict
EOF

cd /vaults/cruxss
detect-secrets scan > .secrets.baseline
pre-commit install
```

### Add LICENSE and SECURITY.md

```bash
cat << 'EOF' > /vaults/cruxss/LICENSE
MIT License

Copyright (c) 2025 YOUR NAME

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
EOF

cat << 'EOF' > /vaults/cruxss/SECURITY.md
# Security Policy

## Intended Use

This tool is for authorized security testing only:
- Bug bounty programs with explicit permission
- Penetration testing with a signed SOW/ROE
- Your own systems

Do not use against systems you do not have written permission to test.

## Reporting Issues With This Tool

1. Do not open a public GitHub issue for security vulnerabilities
2. Email: your-email@example.com
3. Allow 90 days for response before public disclosure

## API Key Safety

API keys are stored by Claude Code in ~/.claude/ — never in this repo.
Pre-commit hooks block accidental key commits.
Never paste credentials into any file in this repository.

## Session Data

Real findings, PoCs, and target data never belong in this public repo.
Use the private session repo pattern described in the README.
EOF
```

---

## Stage 9 — Redacted Example Findings

These show employers and the community what your output looks like
with all real data removed.

```bash
cat << 'EOF' > /vaults/cruxss/examples/EXAMPLE-BUG-001-idor.md
# Example Finding — CRUXSS-ATHZ-04 IDOR

> Redacted demo. Target, endpoints, and account details replaced.
> Finding was submitted, triaged, and resolved.

## Title
IDOR in /api/v2/[resource]/{id} allows authenticated user to read any
[resource] belonging to other users

## CRUXSS-ID
CRUXSS-ATHZ-04

## Severity
High — CVSS 3.1: 7.5
AV:N/AC:L/PR:L/UI:N/S:U/C:H/I:N/A:N

## Summary
The [resource] endpoint accepted a user-supplied integer ID with no ownership
check. Any authenticated attacker with a free account could read another
user's [resource] by changing the ID.

## Steps to Reproduce
1. Log in as Account A (attacker)
2. Create a [resource] — note the returned ID e.g. 1042
3. Send this request using Account B's token:

   GET /api/v2/[resource]/1041 HTTP/1.1
   Host: [REDACTED]
   Authorization: Bearer [ACCOUNT-B-TOKEN]

4. Response returns Account A's full [resource] data

## Impact
Attacker with any free account could enumerate all [resources] across
the platform's [N]+ users by iterating integer IDs 1 to [MAX].

## Remediation
Enforce server-side ownership check on every resource request:
verify resource.owner_id == authenticated_user.id before returning data.

## Resolution
Resolved by program within [N] days. Bounty awarded.
EOF

cat << 'EOF' > /vaults/cruxss/examples/EXAMPLE-BUG-002-ssrf-chain.md
# Example Finding — CRUXSS-INPV-11 + CRUXSS-CLD-COMP-01 SSRF Chain

> Redacted demo. Real target, endpoints, and credentials replaced.

## Title
SSRF via [feature] reaches AWS IMDSv1 — IAM role credentials exposed

## CRUXSS-IDs
CRUXSS-INPV-11 → CRUXSS-CLD-COMP-01 → CRUXSS-CLD-ATK-01

## Severity
Critical — CVSS 3.1: 9.1
AV:N/AC:L/PR:L/UI:N/S:C/C:H/I:H/A:N

## Chain
SSRF confirmed (DNS) → internal metadata reachable → IAM key exfil

## Steps to Reproduce
1. Supply metadata URL to [feature] parameter:

   POST /api/[feature] HTTP/1.1
   Host: [REDACTED]
   Authorization: Bearer [TOKEN]

   {"url": "http://169.254.169.254/latest/meta-data/iam/security-credentials/"}

2. Response reveals IAM role name

3. Second request retrieves credentials:

   {"url": "http://169.254.169.254/latest/meta-data/iam/security-credentials/[ROLE]"}

4. Response contains AccessKeyId, SecretAccessKey, Token

## Impact
Exposed AWS IAM credentials with [REDACTED] permissions. Attacker could
access [cloud resources] within the credential rotation window.

## Remediation
1. Enforce IMDSv2 on all EC2 instances
2. Block RFC-1918 ranges in URL validator server-side
3. Apply SSRF WAF ruleset

## Resolution
Resolved. Critical bounty awarded.
EOF
```

---

## Stage 10 — Install Recon Tools

```bash
cd /vaults/cruxss
chmod +x bb-agent-setup.sh
bash bb-agent-setup.sh
```

Verify all tools are present:
```bash
for tool in subfinder httpx dnsx nuclei ffuf katana dalfox waybackurls anew gau; do
  which $tool &>/dev/null && echo "✅ $tool" || echo "❌ $tool missing"
done
```

---

## Stage 11 — Wire Claude Code to the Vault

```bash
cd /vaults/cruxss
claude --add-dir .
```

Or set permanently:
```bash
mkdir -p ~/.claude
cat << 'EOF' > ~/.claude/settings.json
{
  "directoryPaths": ["/vaults/cruxss"]
}
EOF
```

---

## Stage 12 — First Push to GitHub

### Final security check
```bash
cd /vaults/cruxss
grep -r "sk-ant\|ANTHROPIC_API" \
  --include="*.md" --include="*.sh" --include="*.yaml" \
  --exclude-dir=".git" --exclude-dir="session" \
  . 2>/dev/null && echo "⚠ FIX BEFORE PUSHING" || echo "✅ Clean"
```

### Push private sessions repo first
```bash
cd /vaults/cruxss/session
echo "# CRUXSS Hunt Sessions (Private)" > README.md
git add .
git commit -m "init: private session store"
git branch -M main
git push -u origin main
```

### Link session as submodule and push public repo
```bash
cd /vaults/cruxss
git submodule add https://github.com/YOURUSERNAME/cruxss-sessions.git session
git add .
git commit -m "feat: initial release — CRUXSS bug bounty agent v1.0"
git branch -M main
git push -u origin main
```

### Harden the GitHub repo
Go to github.com/YOURUSERNAME/cruxss-bb-agent → **Settings**:

- **Security tab:** Enable Dependabot alerts, secret scanning, push protection
- **General tab:** Add description and topics:
  `bug-bounty` `claude-code` `penetration-testing` `security` `osint` `kali-linux`

---

## Stage 13 — First Hunt Test

```bash
cd /vaults/cruxss
claude
```

Type:
```
/bb-agent start testphp.vulnweb.com
```

This is a deliberately vulnerable test target — safe and legal to run against.

Switch to Obsidian on Windows — you should see `session/SESSION.md` being
written to in real time as the agent works.

---

## Daily Workflow

```bash
# Start a hunt
cd /vaults/cruxss && claude
/bb-agent start TARGET

# After a hunt — push findings to private repo
cd /vaults/cruxss/session
git add .
git commit -m "hunt: [target-alias] $(date +%Y-%m-%d)"
git push

# Push methodology updates to public repo
cd /vaults/cruxss
git add phases/ examples/ checklists/ CLAUDE.md README.md
git commit -m "update: [what changed]"
git push
```

---

## Troubleshooting

### Shared folder not mounting after reboot
```bash
sudo mount -t vboxsf -o rw,uid=1000,gid=1000,umask=0022 cruxss /vaults/cruxss
# If this works, check /etc/fstab has exactly one vboxsf entry
cat /etc/fstab | grep vboxsf
```

### Permission denied on /vaults/cruxss
```bash
sudo chmod 755 /vaults
sudo chmod 755 /vaults/cruxss
id $USER | grep vboxsf  # confirm user is in vboxsf group
```

### Multiple vboxsf entries in mount output
```bash
# Unmount all
sudo umount /vaults/cruxss
sudo umount /vaults/cruxss
sudo umount /vaults/cruxss
# Remount once
sudo mount -t vboxsf -o rw,uid=1000,gid=1000,umask=0022 cruxss /vaults/cruxss
```

### Go tools not found after install
```bash
echo $PATH | grep go
# If go/bin missing:
echo 'export PATH=$PATH:$(go env GOPATH)/bin' >> ~/.bashrc
source ~/.bashrc
```

### zsh corrupt history warning
```bash
rm ~/.zsh_history && touch ~/.zsh_history
```

### Pre-commit blocking a false positive secret
```bash
# Review what it flagged
detect-secrets scan --list-all-basic-regex .
# Update the baseline to mark it as a known false positive
detect-secrets scan > .secrets.baseline
git add .secrets.baseline
```
