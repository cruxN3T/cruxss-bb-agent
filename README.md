# CRUXSS Bug Bounty Agent

A semi-autonomous Claude Code agent that executes the full bug bounty pipeline end-to-end:

**Recon → Learn → Hunt → Validate → Report**

Pauses for human approval at each phase transition. Never auto-submits reports. Every test is tracked with a CRUXSS ID mapped to OWASP, MITRE ATT&CK, and CWE references.

---

## Repository Structure

```
cruxss-bb-agent/
│
├── README.md                          ← You are here
├── CLAUDE.md                          ← Agent identity + operating rules
├── bb-agent.md                        ← Slash command definition (/bb-agent)
├── bb-agent-setup.sh                  ← Tool installer (Go + Python + wordlists)
│
├── phases/
│   ├── 01-recon.md                    ← OSINT, DNS, cloud assets, fingerprinting
│   ├── 02-learn.md                    ← Threat model, disclosed reports, crown jewel
│   ├── 03-hunt.md                     ← Full vuln hunting checklists (all classes)
│   ├── 04-validate.md                 ← 7-Question Gate, CVSS, findings summary
│   └── 05-report.md                   ← H1/BC templates, human-tone rules, DAPT tracking
│
└── checklists/
    ├── CRUXSS_WebApp_Pentest_Checklist.xlsx
    ├── CRUXSS_API_Pentest_Checklist.xlsx
    ├── CRUXSS_Cloud_Pentest_Checklist.xlsx
    ├── CRUXSS_Network_External_Checklist.xlsx
    └── CRUXSS_Network_Internal_Checklist.xlsx
```

---

## Quick Start

### 1. Install tools
```bash
bash bb-agent-setup.sh
```

### 2. Add this repo to Claude Code
```bash
# From inside this directory:
claude --add-dir .

# Or add globally in ~/.claude/settings.json:
# "directoryPaths": ["/path/to/cruxss-bb-agent"]
```

### 3. Start a hunt
```
/bb-agent start target.com
```

---

## Commands

| Command | What it does |
|---|---|
| `/bb-agent start <target>` | Full pipeline from the beginning |
| `/bb-agent recon <target>` | Phase 1 only |
| `/bb-agent learn <target>` | Phase 2 only |
| `/bb-agent hunt` | Phase 3 on current session |
| `/bb-agent validate` | Phase 4 on current leads |
| `/bb-agent report <BUG-NNN>` | Draft report for a finding |
| `/bb-agent chain <bug>` | Suggest B/C chains from Bug A |
| `/bb-agent status` | Show current session state |
| `/bb-agent kill <LEAD-NNN>` | Mark lead as dead end |
| `/bb-agent scope` | Print confirmed scope |

---

## How the Agent Works

The agent reads its instructions from:

- **`CLAUDE.md`** — identity, operating rules, pause points
- **`bb-agent.md`** — the slash command and session directory structure
- **`phases/01-05`** — phase-specific playbooks loaded on demand

All session data is saved to `./session/` relative to where you run Claude Code:

```
session/
├── SESSION.md              ← live notes: leads, dead ends, anomalies, confirmed bugs
├── scope.json              ← program scope from H1/BC API
├── threat-model.md         ← Phase 2 output
├── subs.txt / live.txt     ← recon outputs
├── urls.txt / jsfiles.txt  ← collected attack surface
├── nuclei.txt              ← scanner findings
├── leads/                  ← raw PoC requests
├── bugs/                   ← validated bug PoCs + evidence
├── chains/                 ← multi-bug chain documentation
└── reports/                ← drafted reports + findings summary
```

---

## Phase Transition Protocol

At the end of each phase the agent:

1. Prints a structured summary
2. Asks `=== Proceed to Phase N+1? [yes/no] ===`
3. **Waits for your explicit approval**
4. On `yes` → loads next phase file and begins
5. On `no` → stays in current phase, asks what to dig into further

The agent **never auto-advances** between phases.

---

## Checklist Coverage

The `checklists/` folder contains the source CRUXSS checklist workbooks. Every test in the agent's phase files is mapped to a CRUXSS ID from one of these:

| Checklist | CRUXSS Prefix | Coverage |
|---|---|---|
| WebApp Pentest | `CRUXSS-INFO`, `CRUXSS-CONF`, `CRUXSS-IDNT`, `CRUXSS-ATHN`, `CRUXSS-ATHZ`, `CRUXSS-SESS`, `CRUXSS-INPV`, `CRUXSS-ERRH`, `CRUXSS-CRYP`, `CRUXSS-BUSL`, `CRUXSS-CLNT` | OWASP WSTG v4.2 |
| API Pentest | `CRUXSS-API-DISC`, `CRUXSS-API-AUTH`, `CRUXSS-API-INPV`, `CRUXSS-API-RATE`, `CRUXSS-API-DATA`, `CRUXSS-API-GQL`, `CRUXSS-API-CONF` | OWASP API Security Top 10 2023 |
| Cloud Pentest | `CRUXSS-CLD-RCON`, `CRUXSS-CLD-IAM`, `CRUXSS-CLD-COMP`, `CRUXSS-CLD-NET`, `CRUXSS-CLD-LOG`, `CRUXSS-CLD-ATK` | CIS Cloud Benchmarks, MITRE ATT&CK Cloud |
| External Network | `CRUXSS-EXT-RCON`, `CRUXSS-EXT-SCAN`, `CRUXSS-EXT-EXPL`, `CRUXSS-EXT-POST`, `CRUXSS-EXT-VULN` | PTES, NIST SP 800-115, MITRE ATT&CK |
| Internal Network | `CRUXSS-INT-RCON`, `CRUXSS-INT-CRED`, `CRUXSS-INT-LAT`, `CRUXSS-INT-PRIV`, `CRUXSS-INT-DOM`, `CRUXSS-INT-POST`, `CRUXSS-INT-VULN` | PTES, BloodHound AD Attack Paths |

---

## The Core Philosophy

**Theoretical bugs = wasted time.**

Before reporting anything, the agent asks:
> "Can an attacker do this RIGHT NOW against a real user who took NO unusual actions — and does it cause real harm?"

If the answer is anything other than a clear YES — the finding is dropped. N/A submissions hurt your validity ratio. Only submit what passes the 7-Question Gate in `phases/04-validate.md`.

---

## Safety Rules

- Never probes out-of-scope assets without asking
- Never runs destructive commands (mass dump, etc.) without explicit confirmation
- Never auto-submits reports — you review and paste manually
- Saves all PoC evidence before generating a report
- Always cleans up test artifacts after internal/cloud tests

---

## Requirements

- [Claude Code](https://claude.ai/code) (CLI)
- Go 1.21+ (for recon tools)
- Python 3.10+ (for pip-based tools)
- `bash bb-agent-setup.sh` to install all dependencies

---

## Contributing

Pull requests welcome. To add a new test or update a checklist:

1. Add the test to the appropriate `phases/0N-*.md` file with a `CRUXSS-ID` reference
2. Update the corresponding `.xlsx` checklist in `checklists/`
3. If it's a new vuln class, add it to the chain table in `phases/03-hunt.md`
4. Update the checklist coverage table in this README
