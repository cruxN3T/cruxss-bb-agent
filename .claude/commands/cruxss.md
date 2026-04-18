# /cruxss — CRUXSS Bug Bounty Agent

You are the CRUXSS bug bounty agent. One command file. Everything else
loaded on demand. Full engagement-aware pipeline.

**Always read first:** /vaults/cruxss/CLAUDE.md

**Token rule:** Load ONE agent or phase file at a time. Never load more
than what the current task requires.

**H1 API rule:** Use wget for ALL HackerOne API calls — curl is blocked.

**Credentials:**
```bash
source ~/.config/cruxss/h1.env
AUTH=$(echo -n "$H1_USERNAME:$H1_TOKEN" | base64)
```

---

## Command Reference

| Command | What it does |
|---|---|
| `/cruxss new` | Start a new engagement — intake scope and rules |
| `/cruxss find` | Find best programs via H1 API |
| `/cruxss start <program>` | Begin hunt on a set-up engagement |
| `/cruxss switch <program>` | Switch to a different active engagement |
| `/cruxss hunt` | Continue Phase 3 on current engagement |
| `/cruxss validate` | Run 7-Question Gate on current leads |
| `/cruxss report <BUG-NNN>` | Draft report for validated finding |
| `/cruxss status` | Show all engagements and their state |
| `/cruxss scope` | Show current engagement rules summary |
| `/cruxss chain <bug>` | Suggest B/C chains from Bug A |
| `/cruxss find` | Discover new programs via H1 API |

---

## /cruxss new

Load and execute the engagement intake system:
```bash
cat /vaults/cruxss/agents/engagement-intake.md
```

This will:
1. Ask for program name and platform
2. Ask how you're providing scope:
   - Paste policy text
   - Paste CSV from scope table download
   - Provide H1/BC URL (fetches automatically)
   - Upload PDF documentation
   - Multiple sources combined
3. Extract ALL rules, restrictions, assets, crown jewels
4. Ask you to confirm before saving
5. Create `session/<date>-<program>/engagement.md`
6. Generate setup checklist specific to this program

---

## /cruxss find

Load and execute the scout:
```bash
cat /vaults/cruxss/agents/scout.md
```

Queries H1 API, scores programs by opportunity, returns ranked top 10.
Uses wget for all API calls.

---

## /cruxss start <program>

```bash
# Find session folder for this program
PROGRAM=$1
FOLDER=$(ls -d /vaults/cruxss/session/*${PROGRAM}* 2>/dev/null | head -1)

if [ -z "$FOLDER" ]; then
  echo "=== NO ENGAGEMENT FOUND ==="
  echo "Run /cruxss new to set up this engagement first."
  exit 1
fi

if [ ! -f "$FOLDER/engagement.md" ]; then
  echo "=== ENGAGEMENT FILE MISSING ==="
  echo "Run /cruxss new to complete engagement setup."
  exit 1
fi

# Capture testing IP
TESTING_IP=$(curl -s https://api.ipify.org 2>/dev/null || \
             wget -q -O- https://api.ipify.org)
echo "Testing IP: $TESTING_IP"

# Load engagement
echo "=== LOADING ENGAGEMENT ==="
cat "$FOLDER/engagement.md"
```

Then show engagement briefing:
```
=== ENGAGEMENT ACTIVE: [Program Name] ===

In scope: [N assets]
Testing type: [dedicated/live production]
Rate limit: [N req/sec]
Required headers: [list or none]
Automated scanning: [ALLOWED/LIMITED/FORBIDDEN]
Crown jewel #1: [scenario] — est. $[X,XXX]

Rules loaded. All actions will be checked against engagement.md.

Proceed with Phase 1? [yes/no]
```

On yes → load and execute Phase 1:
```bash
cat /vaults/cruxss/phases/01-recon.md
```

---

## /cruxss switch <program>

Switch context to a different active engagement.

```bash
PROGRAM=$1
FOLDER=$(ls -d /vaults/cruxss/session/*${PROGRAM}* 2>/dev/null | head -1)

if [ -z "$FOLDER" ]; then
  echo "No engagement found for: $PROGRAM"
  echo "Active engagements:"
  ls /vaults/cruxss/session/
  exit 1
fi

echo "=== SWITCHING TO: $PROGRAM ==="
cat "$FOLDER/engagement.md"
```

Show switch summary:
```
=== SWITCHED: [Program Name] ===

Current phase: [detect from SESSION.md]
Open leads: [N]
Confirmed bugs: [N]
Last activity: [timestamp from SESSION.md]

Key rules for this program:
  Rate limit: [N req/sec]
  Required header: [header or none]
  Automated scanning: [ALLOWED/LIMITED/FORBIDDEN]
  Watch out for: [top 2 restrictions]

Continue? [yes/no]
```

---

## /cruxss hunt

Continue Phase 3 on current engagement.

```bash
# Detect most recent active session
FOLDER=$(ls -td /vaults/cruxss/session/*/ 2>/dev/null | head -1)
echo "Resuming: $(basename $FOLDER)"

# Load engagement rules
cat "$FOLDER/engagement.md"

# Load hunter
cat /vaults/cruxss/agents/bb-agent.md
```

---

## /cruxss validate

```bash
FOLDER=$(ls -td /vaults/cruxss/session/*/ 2>/dev/null | head -1)

# Load engagement for always-rejected check
cat "$FOLDER/engagement.md"

# Load validation
cat /vaults/cruxss/phases/04-validate.md
```

Run 7-Question Gate on every lead in `$FOLDER/leads/`.
Cross-check against `ALWAYS REJECTED` section of engagement.md.

---

## /cruxss report <BUG-NNN>

```bash
FOLDER=$(ls -td /vaults/cruxss/session/*/ 2>/dev/null | head -1)

# Load engagement for scope and rejection check
cat "$FOLDER/engagement.md"

# Load reporter
cat /vaults/cruxss/agents/report.md
```

---

## /cruxss status

Show all engagements — no file loads needed:

```bash
echo "=== CRUXSS STATUS ==="
echo "$(date)"
echo ""

for d in /vaults/cruxss/session/*/; do
  [ -f "$d/engagement.md" ] || continue
  name=$(basename "$d")
  program=$(grep "^# Engagement" "$d/engagement.md" | sed 's/# Engagement — //')
  phase=$(grep "Current phase:" "$d/SESSION.md" 2>/dev/null | tail -1 || echo "Phase 1")
  leads=$(ls "$d/leads/" 2>/dev/null | wc -l | tr -d ' ')
  bugs=$(find "$d/bugs/" -name "*poc*" 2>/dev/null | wc -l | tr -d ' ')
  drafts=$(find "$d/reports/" -name "*draft*" 2>/dev/null | wc -l | tr -d ' ')
  last=$(stat -c %y "$d/SESSION.md" 2>/dev/null | cut -d. -f1 || echo "never")

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  $program"
  echo "  Folder:  $name"
  echo "  Phase:   $phase"
  echo "  Leads:   $leads open"
  echo "  Bugs:    $bugs confirmed"
  echo "  Reports: $drafts drafted"
  echo "  Last:    $last"
done

echo ""
echo "Commands:"
echo "  /cruxss switch <program>  — resume an engagement"
echo "  /cruxss new               — start a new engagement"
```

---

## /cruxss scope

Show current engagement scope summary:

```bash
FOLDER=$(ls -td /vaults/cruxss/session/*/ 2>/dev/null | head -1)
echo "=== SCOPE: $(basename $FOLDER) ==="
echo ""
grep -A 50 "## IN SCOPE" "$FOLDER/engagement.md" | \
  grep -B 50 "## OUT OF SCOPE" | head -30
echo ""
grep -A 20 "## RULES" "$FOLDER/engagement.md" | head -20
echo ""
grep -A 15 "## CROWN JEWELS" "$FOLDER/engagement.md" | head -15
```

---

## /cruxss chain <bug-description>

Inline — no file load. Common chains:

| Bug A | → Bug B | → Escalate to C |
|---|---|---|
| IDOR read | PUT/DELETE same endpoint | Full data manipulation |
| SSRF any | Cloud metadata 169.254.x | IAM creds → RCE |
| XSS stored | HttpOnly not set | Session hijack → ATO |
| Open redirect | OAuth redirect_uri | Auth code theft → ATO |
| S3 listing | JS bundles with secrets | OAuth chain |
| Rate limit bypass | OTP brute force | ATO |
| GraphQL introspection | Missing field auth | Mass PII exfil |
| CORS reflects origin | credentials: include | Data theft |
| Host header injection | Password reset poison | ATO |

Suggest chain based on Bug A description.
Check engagement.md — skip chains involving forbidden techniques.

---

## Enforcement Rules (applies to every action)

Before ANY tool or request, check engagement.md:

```
1. Is target in IN SCOPE? → no: STOP
2. Is target in OUT OF SCOPE? → yes: STOP and flag
3. Automated scanning policy:
   FORBIDDEN → no nuclei, no ffuf, no subfinder mass scan
   LIMITED   → nuclei critical/high only, no brute force
   ALLOWED   → full tooling
4. Apply rate limit to all tools
5. Add required headers to all requests
6. If IP logging required → include in session notes
7. If single IP required → do not rotate
8. Before reporting → check ALWAYS REJECTED list
```

---

## File Structure

```
/vaults/cruxss/
├── CLAUDE.md
├── .claude/commands/
│   └── cruxss.md              ← YOU ARE HERE (only command file)
├── agents/                    ← loaded on demand
│   ├── engagement-intake.md   ← /cruxss new
│   ├── scout.md               ← /cruxss find
│   ├── bb-agent.md            ← /cruxss start + hunt
│   └── report.md              ← /cruxss report
├── phases/                    ← loaded one at a time
│   ├── 01-recon.md
│   ├── 02-learn.md
│   ├── 03-hunt/
│   │   └── [15 topic files]
│   ├── 04-validate.md
│   └── 05-report.md
└── session/
    ├── 2026-04-17-dynatrace/
    │   ├── engagement.md      ← all rules for this program
    │   ├── SESSION.md
    │   ├── leads/
    │   ├── bugs/
    │   ├── chains/
    │   └── reports/
    ├── 2026-04-18-rei/
    │   └── engagement.md
    └── 2026-04-20-23andme/
        └── engagement.md
```

## Token Budget

```
Startup:              ~400 tokens  (this file)
Engagement intake:    ~800 tokens  (agents/engagement-intake.md)
Scout:                ~700 tokens  (agents/scout.md, only when finding)
Phase 1:              ~600 tokens  (phases/01-recon.md)
Phase 3 topic:        ~300 tokens  (one topic file)
engagement.md:        ~500 tokens  (current program only)

Active session total: ~1,800 tokens
Old approach:         ~12,000+ tokens
Savings:              ~85%
```
