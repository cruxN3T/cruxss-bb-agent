# /cruxss new — Engagement Intake

You are starting a new bug bounty engagement. Your job is to fully
understand the program before any testing begins.

Read /vaults/cruxss/CLAUDE.md for global operating rules.

---

## STEP 1 — Program Identity

Ask the operator:
```
=== NEW ENGAGEMENT ===

Program name: (e.g. "TargetCorp", "AcmeSecurity")
Platform: (HackerOne / Bugcrowd / Intigriti / other)
Program URL: (optional — paste the H1/BC program URL)
```

---

## STEP 2 — Scope Input

Ask the operator how they want to provide scope:

```
How are you providing the scope for this engagement?

1. Paste policy text    — copy/paste the program overview page
2. CSV file             — downloaded from the program scope table
3. Program URL          — I'll fetch the page myself
4. PDF document         — upload the program documentation
5. Multiple sources     — I'll combine them (e.g. CSV + policy text)

Enter choice (1-5):
```

### Input Method 1 — Pasted Policy Text
```
Paste the full program policy text below.
When done, type END on a new line.
```

Parse the pasted text for:
- Program rules and restrictions
- Exclusions and always-rejected findings
- Account requirements
- Rate limits
- Required headers
- Special handling rules (leaked creds, sensitive data, etc.)
- Crown jewel scenarios (worst-case tables, bonus payouts)
- Test environment details
- API documentation URLs
- Active campaigns and multipliers

### Input Method 2 — CSV File
```
Paste the CSV content below (or the file path if uploaded).
When done, type END on a new line.
```

Parse each CSV row:
```
Columns: Asset name, Type, Coverage, Max severity, Bounty, Last update, Resolved Reports

For each row:
- eligible_for_bounty = Bounty column = "Eligible"
- out_of_scope = Bounty column = "Ineligible" OR Coverage = "None"
- max_severity = Max severity column
- resolved_count = Resolved Reports column (0 = potentially untested)
- asset_type = Type column (Domain/Wildcard/URL/Other/Executable)
- last_updated = Last update column
```

Build two lists:
```
IN_SCOPE = all rows where Bounty = "Eligible"
OUT_OF_SCOPE = all rows where Bounty = "Ineligible"
```

Flag high opportunity assets:
```
UNTESTED = rows where Resolved Reports = 0 AND Bounty = "Eligible"
HIGH_VALUE = rows where Max severity = "Critical" AND Bounty = "Eligible"
```

### Input Method 3 — Program URL
```bash
# Fetch the program page
URL=$1
wget -q -O /tmp/program_page.html "$URL" --timeout=30

# If HackerOne — also fetch structured scope via API
if echo "$URL" | grep -q "hackerone.com"; then
  HANDLE=$(echo "$URL" | sed 's|.*/||')
  source ~/.config/cruxss/h1.env
  AUTH=$(echo -n "$H1_USERNAME:$H1_TOKEN" | base64)

  wget -q -O /tmp/h1_scopes.json \
    "https://api.hackerone.com/v1/hackers/programs/$HANDLE/structured_scopes" \
    --header="Accept: application/json" \
    --header="Authorization: Basic $AUTH" \
    --timeout=15

  wget -q -O /tmp/h1_program.json \
    "https://api.hackerone.com/v1/hackers/programs/$HANDLE" \
    --header="Accept: application/json" \
    --header="Authorization: Basic $AUTH" \
    --timeout=15

  wget -q -O /tmp/h1_exclusions.json \
    "https://api.hackerone.com/v1/hackers/programs/$HANDLE/scope_exclusions" \
    --header="Accept: application/json" \
    --header="Authorization: Basic $AUTH" \
    --timeout=15

  wget -q -O /tmp/h1_hacktivity.json \
    "https://api.hackerone.com/v1/hackers/hacktivity?queryString=team:$HANDLE AND disclosed:true&page[size]=25" \
    --header="Accept: application/json" \
    --header="Authorization: Basic $AUTH" \
    --timeout=15

  echo "[*] API data fetched for @$HANDLE"
fi
```

Parse fetched content using same extraction rules as Method 1 + Method 2.

### Input Method 4 — PDF Document
```
Upload the PDF file.
I will extract text and parse it for scope and rules.
```

Read the PDF content and parse for:
- Asset lists
- Rules and restrictions
- API documentation
- Setup instructions
- Test environment details

### Input Method 5 — Multiple Sources
Combine all provided sources. Later sources override earlier ones for
conflicting information. Flag any conflicts to the operator.

---

## STEP 3 — Extraction Protocol

Regardless of input method, extract these fields:

### A. Asset Classification
```
For each asset found:
  name:            exact domain/URL/IP/app name
  type:            Domain/Wildcard/URL/IP/Mobile/Executable/SourceCode/Other
  in_scope:        true/false
  bounty_eligible: true/false
  max_severity:    Critical/High/Medium/Low/None
  resolved_count:  number (from CSV) or "unknown"
  notes:           any asset-specific instructions
  opportunity:     HIGH/MEDIUM/LOW (calculated below)

Opportunity calculation:
  HIGH   = bounty_eligible=true AND max_severity=Critical AND resolved_count=0
  HIGH   = bounty_eligible=true AND max_severity=Critical AND resolved_count<5
  MEDIUM = bounty_eligible=true AND max_severity=High
  LOW    = bounty_eligible=true AND max_severity=Medium/Low
```

### B. Rules Extraction
```
automated_scanning:   ALLOWED / LIMITED / FORBIDDEN
rate_limit:           "N req/sec" or "not stated — use 5 req/sec"
required_headers:     list of headers (e.g. X-HackerOne-Research: cruxn3t)
account_type:         "H1 alias" / "wearehackerone.com email" / "own accounts"
max_accounts:         number or "not stated"
ip_logging:           true/false (must include IP in report)
single_ip_required:   true/false (no IP rotation)
test_environment:     "dedicated" / "live production" / details
stop_if_sensitive:    true/false (stop testing if real data found)
leaked_creds_protocol: "standard" / "do not validate — submit evidence only"
consolidation_policy: "one report per chain" / "one per root cause" / "standard"
disclosure_restriction: "standard H1" / "written consent required" / other
safe_harbour:         "Gold Standard" / "standard" / "none"
```

### C. Always Rejected List
```
Extract every finding type the program explicitly says they won't pay for.
These are instant kills — never test or report these.

Common ones to check for:
- Missing security headers
- CSRF on non-sensitive forms
- Self-XSS
- Open redirect alone
- Clickjacking alone
- SSL/TLS cipher issues
- DKIM/SPF/DMARC
- Rate limiting on non-auth endpoints
- Version disclosure
- CSV injection
- Tabnabbing
- Host header injection alone
- SSRF DNS-only
- Subdomain takeover (some programs)
- Automated scanner output
- Third-party assets
```

### D. Crown Jewels
```
Identify highest-value scenarios:
1. Check for explicit worst-case/bonus tables
2. If no table: infer from asset descriptions + bounty tiers
3. Check for active campaign multipliers

For each crown jewel:
  scenario:    plain English description
  target:      specific asset
  cruxss_ids:  relevant CRUXSS test IDs
  est_payout:  dollar amount (apply campaign multiplier if active)
  priority:    1/2/3
```

### E. Ambiguities
```
Flag anything unclear:
- Assets that might be in or out of scope
- Third-party services embedded in app
- Attack types not explicitly mentioned
- Conflicting statements in policy
- Assets with no resolved reports (opportunity or just ignored?)

For each:
  item:       what's unclear
  default:    what we'll assume if not confirmed
  ask:        yes/no question for operator
```

---

## STEP 4 — Operator Confirmation

Before writing any files, present a summary for confirmation:

```
=== ENGAGEMENT SUMMARY — [Program Name] ===

Platform: [H1/BC/etc]
Testing type: [dedicated environment / live production]

IN SCOPE ([N] assets):
  CRITICAL eligible:
    ✓ [asset] — [N resolved reports] — [opportunity level]
    ✓ [asset] — 0 resolved — HIGH OPPORTUNITY
  HIGH eligible:
    ✓ [asset]
  OTHER:
    ✓ [asset]

OUT OF SCOPE ([N] assets — NEVER TOUCH):
  ✗ [asset]
  ✗ [asset]

RULES:
  Automated scanning: [ALLOWED/LIMITED/FORBIDDEN]
  Rate limit: [N req/sec]
  Required headers: [list or none]
  Accounts needed: [type and how many]
  IP logging required: [yes/no]
  Single IP only: [yes/no]

ALWAYS REJECTED ([N] finding types):
  [list top 5 most relevant]

CROWN JEWELS:
  #1 [scenario] — est. $[X,XXX] — [CRUXSS-IDs]
  #2 [scenario] — est. $[X,XXX]
  #3 [scenario] — est. $[X,XXX]

ACTIVE CAMPAIGN: [yes — Nx multiplier until DATE / none]

AMBIGUITIES ([N] items need confirmation):
  ? [item] — default: [assumption] — OK? [yes/no]

Does this look correct? [yes / no / edit]
```

Wait for operator to confirm or correct before proceeding.

---

## STEP 5 — Create Engagement Files

Once confirmed, create the session folder and write engagement.md:

```bash
PROGRAM_NAME=$(echo "$NAME" | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g')
DATE=$(date +%Y-%m-%d)
FOLDER="/vaults/cruxss/session/${DATE}-${PROGRAM_NAME}"
mkdir -p "$FOLDER"/{leads,bugs,bugs/evidence,chains,reports}
```

Write $FOLDER/engagement.md:

```markdown
# Engagement — [Program Name]
Created: [date]
Platform: [platform]
Handle: @[handle]
Program URL: [url]
Testing Type: [dedicated / live production]
Safe Harbour: [Gold Standard / standard / none]

---

## IDENTITY
Name: [program name]
Contact: [email if provided]
Campaign: [active campaign details or "none"]

---

## IN SCOPE
[For each in-scope asset:]
| Asset | Type | Max Severity | Resolved | Opportunity |
|---|---|---|---|---|
| [asset] | [type] | [severity] | [count] | [HIGH/MED/LOW] |

---

## OUT OF SCOPE — NEVER TOUCH
[List every out-of-scope asset]
- [asset] — [reason/notes]

---

## RULES
Automated scanning: [ALLOWED/LIMITED/FORBIDDEN]
  Details: [specifics]

Rate limit: [N req/sec]

Required headers (add to EVERY request):
  [header: value]
  [header: value]

Account requirements:
  Type: [H1 alias / wearehackerone.com / own accounts]
  Max accounts: [N]
  Attacker account: [format]
  Victim account: [format]

IP requirements:
  Log testing IP in reports: [yes/no]
  Single IP only (no rotation): [yes/no]
  Testing IP: [captured at session start]

Special rules:
  [any unique rules extracted from policy]

---

## ALWAYS REJECTED — NEVER TEST OR REPORT THESE
[Complete list from program policy]
- [finding type]
- [finding type]

---

## CROWN JEWELS
Priority 1 — highest value, hunt these first:
| # | Scenario | Asset | CRUXSS-IDs | Est. Payout |
|---|---|---|---|---|
| 1 | [scenario] | [asset] | [ids] | $[amount] |

Priority 2 — high value:
[same format]

Priority 3 — medium value:
[same format]

---

## TEST ENVIRONMENT
[Setup instructions if dedicated environment]
[Signup URL if required]
[Account format]
[Special setup steps]

---

## API DOCUMENTATION
[Any Swagger/OpenAPI/REST doc URLs]

---

## HUNT TOPICS (Phase 3 files to load)
Based on crown jewels and asset types:
- phases/03-hunt/[topic].md — reason
- phases/03-hunt/[topic].md — reason

---

## SESSION NOTES START
Testing IP: [captured automatically]
Session started: [date/time]
```

---

## STEP 6 — Ready Confirmation

```
=== ENGAGEMENT READY ===

Program: [name]
Session: [folder path]
In-scope assets: [N]
Crown jewels: [N]
Hunt topics queued: [list]

Setup checklist:
[generate based on rules extracted]
  [ ] Test account created: [format]
  [ ] Victim account created: [format]
  [ ] Required header configured: [header]
  [ ] Rate limit noted: [N req/sec]
  [ ] Testing IP logged: [IP]

All rules loaded. Agent will enforce them automatically.

=== Run: /cruxss start [primary target] ===
```

---

## Enforcement During Testing

Once engagement.md exists, the agent checks it before EVERY action:

Before running any tool:
```
Is [target] in IN SCOPE section? → yes: proceed / no: STOP
Is automated scanning ALLOWED/LIMITED/FORBIDDEN?
  FORBIDDEN → skip nuclei, ffuf, subfinder
  LIMITED → nuclei critical/high only, no brute force
Apply rate limit: [N] req/sec to all tools
Add required headers to all requests
```

Before probing any new asset:
```
Check against OUT OF SCOPE list
If match → STOP and flag to operator
If unclear → ASK before proceeding
```

Before Phase 3 testing:
```
Remind operator of key restrictions:
"[Program] reminder:
  - Rate limit: [N] req/sec
  - Required header: [header]
  - Forbidden: [top 3 restrictions]
  - Crown jewel target: [P1 scenario]"
```

Before writing any report:
```
Check finding against ALWAYS REJECTED list
If match → kill finding, do not report
Check scope — is this endpoint actually in scope?
Apply consolidation policy
```
