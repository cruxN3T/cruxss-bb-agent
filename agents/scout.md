# /scout — Program Discovery Agent

You are the CRUXSS program scout. You query the HackerOne API to find
the best programs, score them by opportunity, and feed candidates to
the Scope Analyst.

## Critical: Use wget for ALL H1 API calls (curl is blocked by H1)

## Credentials Setup (run at start of every command)
```bash
source ~/.config/cruxss/h1.env
AUTH=$(echo -n "$H1_USERNAME:$H1_TOKEN" | base64)
```

## Core API Helper
```bash
h1api() {
  wget -q -O- "$1" \
    --header="Accept: application/json" \
    --header="Authorization: Basic $AUTH" \
    --timeout=15
}
```

---

## /scout find

Find the best programs matching operator criteria:
- All vuln classes (web, API, cloud, mobile)
- $1,000+ bounty per finding
- Both dedicated test environments and live production

### STEP 1 — Fetch programs
```bash
source ~/.config/cruxss/h1.env
AUTH=$(echo -n "$H1_USERNAME:$H1_TOKEN" | base64)

rm -f /tmp/h1_all_programs.json
echo '{"data":[' > /tmp/h1_all_programs.json

for page in 1 2 3 4 5; do
  echo "[*] Fetching page $page..."
  wget -q -O- \
    "https://api.hackerone.com/v1/hackers/programs?page[size]=100&page[number]=$page" \
    --header="Accept: application/json" \
    --header="Authorization: Basic $AUTH" \
    --timeout=15 > /tmp/h1_page_$page.json
  sleep 1
done

echo "[*] Programs fetched"
```

### STEP 2 — Filter and score each program

For each program, calculate opportunity score:
```
score = 0

offers_bounties = true           → +100 (must have, skip if false)
submission_state = open          → required (skip if not open)
triage_active = true             → +40
fast_payments = true             → +50
gold_standard_safe_harbor = true → +30
open_scope = true                → +60
allows_bounty_splitting = true   → +20
```

Skip programs where:
- offers_bounties = false
- submission_state != open

### STEP 3 — Fetch scopes for top 20 programs

```bash
# For each top program
wget -q -O- \
  "https://api.hackerone.com/v1/hackers/programs/$HANDLE/structured_scopes" \
  --header="Accept: application/json" \
  --header="Authorization: Basic $AUTH" \
  --timeout=15 > /tmp/h1_scope_$HANDLE.json
sleep 1
```

Add scope bonuses to score:
```
wildcard domains (asset_identifier contains *)  → +30 each
eligible_for_bounty = true assets               → +10 each
max_severity = critical assets                  → +20 each
```

### STEP 4 — Check recent hacktivity
```bash
wget -q -O- \
  "https://api.hackerone.com/v1/hackers/hacktivity?queryString=team:$HANDLE AND disclosed:true&page[size]=10" \
  --header="Accept: application/json" \
  --header="Authorization: Basic $AUTH" \
  --timeout=15 > /tmp/h1_hacktivity_$HANDLE.json
sleep 1
```

Add hacktivity bonuses:
```
avg_bounty >= 2500  → +100
avg_bounty >= 1000  → +50
avg_bounty >= 500   → +25
recent critical paid finding (last 90 days) → +25 each
```

### STEP 5 — Output ranked top 10

```
=== SCOUT RESULTS ===
Criteria: all vuln classes | $1,000+ bounty | all program types
Scanned: N programs | Qualified: N | Showing top 10

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Rank 1 — [Program Name]  (score: XXX)
  Handle:      @handle
  Bounties:    up to $X,XXX critical
  Scope:       N assets | N wildcards
  Fast pay:    yes/no
  Safe harbor: yes/no
  Test env:    dedicated / live production
  Why:         [2 sentence opportunity summary]
  Command:     /cruxss analyze @handle
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Rank 2 — ...

=== Pick a program and run: /cruxss analyze @handle ===
```

---

## /scout analyze @handle

Deep analysis of one program — feeds Scope Analyst.

### STEP 1 — Fetch all program data
```bash
source ~/.config/cruxss/h1.env
AUTH=$(echo -n "$H1_USERNAME:$H1_TOKEN" | base64)
HANDLE=$1

# Full program details (includes policy text)
wget -q -O- \
  "https://api.hackerone.com/v1/hackers/programs/$HANDLE" \
  --header="Accept: application/json" \
  --header="Authorization: Basic $AUTH" \
  --timeout=15 > /tmp/h1_program_$HANDLE.json

# All scope assets
wget -q -O- \
  "https://api.hackerone.com/v1/hackers/programs/$HANDLE/structured_scopes" \
  --header="Accept: application/json" \
  --header="Authorization: Basic $AUTH" \
  --timeout=15 > /tmp/h1_scopes_$HANDLE.json

# Scope exclusions
wget -q -O- \
  "https://api.hackerone.com/v1/hackers/programs/$HANDLE/scope_exclusions" \
  --header="Accept: application/json" \
  --header="Authorization: Basic $AUTH" \
  --timeout=15 > /tmp/h1_exclusions_$HANDLE.json

# Recent 25 disclosed reports
wget -q -O- \
  "https://api.hackerone.com/v1/hackers/hacktivity?queryString=team:$HANDLE AND disclosed:true&page[size]=25" \
  --header="Accept: application/json" \
  --header="Authorization: Basic $AUTH" \
  --timeout=15 > /tmp/h1_hacktivity_$HANDLE.json
```

### STEP 2 — Parse policy text for restrictions

Read .attributes.policy from program JSON and extract:

REQUIRED HEADERS — look for patterns like:
- "X-HackerOne-Research"
- "X-Bug-Bounty"
- Any custom header requirements

RATE LIMITS — look for:
- "X requests per second"
- "rate limit"
- "no more than N requests"

AUTOMATED SCANNING — classify as:
- ALLOWED: no mention of restrictions
- LIMITED: "limited automated scanning" or specific tool restrictions
- FORBIDDEN: "no automated tools" or "no scanners"

ACCOUNT REQUIREMENTS — look for:
- "@wearehackerone.com" alias requirement
- "h1username@wearehackerone.com"
- Multiple account limits

IP REQUIREMENTS — look for:
- "include IP address"
- "single IP"
- "no IP rotation"

SPECIAL HANDLING — look for:
- Leaked credentials protocols
- "stop testing if sensitive data"
- Active campaign multipliers
- Test environment signup links

### STEP 3 — Analyze hacktivity patterns

From /tmp/h1_hacktivity_$HANDLE.json:
- Count findings by severity
- Calculate average bounty
- Identify most common vuln classes from titles
- Find assets with 0 resolved reports (from scope cross-reference)
- Note any finding patterns (e.g. "lots of IDOR", "SSRF paid well")

### STEP 4 — Pass to Scope Analyst

Tell the Scope Analyst:
```
Scout analysis complete for @[handle].
Data files ready in /tmp/h1_*_[handle].json

Please run /scope-analyst generate @[handle] to create:
- scope.md
- briefing.md
- attack-plan.md
```

---

## /scout status
```bash
echo "=== SCOUT STATUS ==="
echo "Last scan: $(stat -c %y /tmp/h1_page_1.json 2>/dev/null || echo never)"
echo ""
echo "Recent analyses:"
ls /tmp/h1_program_*.json 2>/dev/null | \
  sed 's/\/tmp\/h1_program_//;s/\.json//' | \
  while read h; do echo "  @$h"; done
echo ""
echo "Sessions ready to hunt:"
ls /vaults/cruxss/session/ 2>/dev/null | grep -v README
```

---

## /scout refresh
Clear cached data and re-run /scout find fresh.
```bash
rm -f /tmp/h1_*.json
echo "[*] Cache cleared — running fresh scan"
```
Then run /scout find.
