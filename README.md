# CRUXSS Bug Bounty Agent

A semi-autonomous bug bounty hunting agent built on [Claude Code](https://claude.ai/code).
Executes the full offensive security pipeline with engagement-aware scope enforcement,
token-efficient architecture, and structured output for every finding.

```
New Engagement → Recon → Threat Model → Hunt → Validate → Report
```

Every phase pauses for human approval. Reports are never auto-submitted.
Every test maps to a CRUXSS ID cross-referenced with OWASP, MITRE ATT&CK, and CWE.

---

## What This Is

Bug bounty hunting involves a repeatable workflow — recon, threat modeling,
vulnerability testing, validation, and reporting. This project automates the
mechanical parts of that workflow while keeping a human in the loop for every
decision that matters.

The agent is **engagement-first**: before touching any target, it reads the
full program policy, extracts all rules and restrictions, identifies the
highest-value targets, and enforces everything automatically throughout testing.
Different programs have different scopes, rate limits, forbidden techniques,
and required headers — the agent handles all of it per engagement.

---

## Architecture

```
.claude/commands/
└── cruxss.md              ← single entry point (~400 tokens at startup)

agents/                    ← loaded on demand, not at startup
├── engagement-intake.md   ← parses program policy, CSV, PDF, or URL
├── scout.md               ← discovers programs via HackerOne API
├── scope-analyst.md       ← extracts rules and generates engagement files
├── bb-agent.md            ← runs phases 1-3 (recon, threat model, hunt)
└── report.md              ← validates findings and drafts reports

phases/                    ← methodology, loaded one file at a time
├── 01-recon.md            ← OSINT, DNS, cloud assets, fingerprinting
├── 02-learn.md            ← threat modeling, disclosed reports, crown jewels
├── 03-hunt/               ← 15 individual topic files (IDOR, SSRF, XSS, etc.)
├── 04-validate.md         ← 7-Question Gate, CVSS 3.1, findings summary
└── 05-report.md           ← report templates, human-tone rules, escalation

checklists/                ← CRUXSS pentest checklists (OWASP / MITRE mapped)
templates/                 ← blank engagement template
examples/                  ← redacted real findings showing output format
session/                   ← per-engagement folders (private repo, gitignored)
```

**Token efficiency:** The agent loads ~400 tokens at startup instead of loading
all methodology files upfront. Individual phase files and hunt topics are loaded
only when needed, reducing active context by ~85% compared to a naive approach.

---

## Key Features

### Engagement-First Scope Enforcement

Every engagement starts with a scope briefing. The agent accepts program policy
via paste, CSV download, URL, or PDF — extracts all rules, restrictions, and
crown jewels — and enforces them automatically throughout testing.

```
/cruxss new

→ "How are you providing scope?"
  1. Paste policy text
  2. Paste CSV from scope table
  3. Program URL (fetches automatically)
  4. PDF documentation
  5. Multiple sources combined

→ Extracts: in-scope assets, out-of-scope assets, rate limits,
  required headers, forbidden techniques, crown jewels, rejection list

→ Confirms with operator before saving

→ Enforces everything automatically during testing
```

### Program Discovery via HackerOne API

```
/cruxss find

→ Queries HackerOne API for public programs
→ Scores each by opportunity (bounty range, scope size, untested assets,
  fast payments, safe harbour, active campaigns)
→ Returns ranked top 10 with rationale
→ Feeds directly into engagement setup
```

### Semi-Autonomous Pipeline

The agent runs each phase fully, then pauses for approval:

```
Phase 1: Recon         → asset discovery, fingerprinting, quick wins
Phase 2: Threat Model  → crown jewel identification, attack surface mapping
Phase 3: Hunt          → targeted vulnerability testing per engagement rules
Phase 4: Validate      → 7-Question Gate, CVSS scoring, deduplication check
Phase 5: Report        → structured draft ready for manual submission
```

### Multi-Engagement Support

Each program gets an isolated session folder. Switch between active
engagements instantly without losing context:

```
/cruxss switch <program>
```

### A→B Bug Chaining

When a lead is confirmed, the agent checks known chain patterns
and suggests escalation paths:

```
/cruxss chain <bug-description>

SSRF → cloud metadata → IAM credential exfil → potential RCE
Open redirect → OAuth redirect_uri → auth code theft → ATO
IDOR (read) → PUT/DELETE same endpoint → full data manipulation
```

---

## Quick Start

### Prerequisites
- [Claude Code](https://claude.ai/code) installed and authenticated
- Go 1.21+, Python 3.10+, Node 18+
- Kali Linux or any Debian-based system (recommended)

### Install
```bash
git clone https://github.com/cruxN3T/cruxss-bb-agent.git
cd cruxss-bb-agent
bash bb-agent-setup.sh
```

### Register with Claude Code
```bash
claude --add-dir .
```

### Start a new engagement
```bash
claude
/cruxss new
```

Full setup guide including VirtualBox shared folder, Obsidian integration,
and two-repo security architecture: [SETUP.md](SETUP.md)

---

## Command Reference

| Command | What it does |
|---|---|
| `/cruxss new` | Start a new engagement — intake scope and rules |
| `/cruxss find` | Discover programs via HackerOne API |
| `/cruxss start <program>` | Begin hunt pipeline on a set-up engagement |
| `/cruxss switch <program>` | Switch to a different active engagement |
| `/cruxss hunt` | Continue Phase 3 on current engagement |
| `/cruxss validate` | Run 7-Question Gate on current leads |
| `/cruxss report <BUG-NNN>` | Draft report for a validated finding |
| `/cruxss status` | Show all engagements and their state |
| `/cruxss scope` | Show current engagement rules |
| `/cruxss chain <bug>` | Suggest B/C chains from Bug A |

---

## Checklist Coverage

Five professional pentest checklists with CRUXSS IDs mapped to
OWASP, MITRE ATT&CK, and CWE references:

| Checklist | Standards | CRUXSS Prefixes |
|---|---|---|
| Web Application | OWASP WSTG v4.2 | CRUXSS-INFO, CRUXSS-ATHN, CRUXSS-ATHZ, CRUXSS-SESS, CRUXSS-INPV, CRUXSS-BUSL, CRUXSS-CLNT |
| API Security | OWASP API Top 10 2023 | CRUXSS-API-DISC, CRUXSS-API-AUTH, CRUXSS-API-INPV, CRUXSS-API-GQL |
| Cloud | CIS Benchmarks, MITRE ATT&CK Cloud | CRUXSS-CLD-IAM, CRUXSS-CLD-COMP, CRUXSS-CLD-NET, CRUXSS-CLD-ATK |
| External Network | PTES, NIST SP 800-115, MITRE ATT&CK | CRUXSS-EXT-RCON, CRUXSS-EXT-SCAN, CRUXSS-EXT-EXPL |
| Internal Network | PTES, BloodHound AD paths | CRUXSS-INT-CRED, CRUXSS-INT-LAT, CRUXSS-INT-PRIV, CRUXSS-INT-DOM |

---

## Security Model

**Public repo:** methodology, tooling, checklists, redacted examples.
No program names, no credentials, no findings, no target data.

**Private repo:** all engagement data — session notes, leads, validated bugs, drafted reports. Stored separately, never public.
leads, validated bugs, drafted reports. Never public.

**Local only:** HackerOne API credentials (`~/.config/cruxss/`),
Claude Code API key (`~/.claude/`). Never in any repo.

Pre-commit secret scanning blocks accidental credential commits.
GitHub push protection adds a second layer.

---

## The Core Rule

Before reporting anything, the agent asks:

> *"Can an attacker do this RIGHT NOW against a real user who took NO
> unusual actions — and does it cause real harm?"*

If the answer is not a clear YES — the finding is dropped.
Only findings that pass the full 7-Question Gate get drafted into reports.

---

## Requirements

| Tool | Version | Purpose |
|---|---|---|
| Claude Code | latest | Agent runtime |
| Go | 1.21+ | Recon tools (subfinder, httpx, nuclei, ffuf, etc.) |
| Python | 3.10+ | Supporting tools (semgrep, arjun, detect-secrets) |
| Node | 18+ | Claude Code and tooling |
| Git | any | Version control |

---

## Contributing

Pull requests welcome.

To add a new test:
1. Add it to the relevant `phases/03-hunt/<topic>.md` with a `CRUXSS-ID`
2. Update the corresponding `.xlsx` checklist in `checklists/`
3. If it introduces a new chain pattern, add it to the chain table in `CLAUDE.md`
4. Update the checklist coverage table in this README

To report a security issue with this tool: see [SECURITY.md](SECURITY.md)

---

## License

MIT — see [LICENSE](LICENSE)
