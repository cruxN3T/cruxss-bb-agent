# Phase 2: Learn (Pre-Hunt Intelligence)

## Goal
Build a mental model of the target before touching it aggressively.
10 minutes here saves 2 hours of wrong-direction hunting.

---

## Top 1% Pre-Hunt Mental Framework

### Step 1: Crown Jewel Thinking
Before anything else — answer this:
> "If I were the attacker and could do ONE thing, what causes maximum damage?"

| App Type | Crown Jewel |
|---|---|
| Financial | Drain funds, transfer to attacker account |
| Healthcare | PII leak, HIPAA violation |
| SaaS / multi-tenant | Tenant data crossing, admin takeover |
| Auth provider | Full SSO chain compromise |
| Marketplace | Seller payout manipulation |

Save answer to `session/SESSION.md` under `## Crown Jewel`.

### Step 2: Developer Empathy
Ask for each major feature:
- What was the simplest implementation?
- What shortcut would a tired dev take at 2am?
- Where is auth checked — controller? middleware? DB layer?
- What happens when you call endpoint B without going through endpoint A first?

### Step 3: Trust Boundary Mapping
```
Client → CDN → Load Balancer → App Server → Database
          ^             ^              ^
     Where does app STOP trusting input?
     Where does it ASSUME input is already validated?
```

### Step 4: Feature Interaction Thinking
- Does a new feature reuse old auth, or have its own?
- Does the mobile API share auth logic with the web app?
- Was this feature built by the same team or a third-party?

---

## Read Disclosed Reports

```bash
PROGRAM="PROGRAM_HANDLE"

# Fetch recent disclosed reports
curl -s "https://hackerone.com/graphql" \
  -H "Content-Type: application/json" \
  -d '{"query":"{ hacktivity_items(first:25, order_by:{field:popular, direction:DESC}, where:{team:{handle:{_eq:\"'$PROGRAM'\"}}}) { nodes { ... on HacktivityDocument { report { title severity_rating } } } } }"}' \
  | jq '.data.hacktivity_items.nodes[].report' \
  | tee session/disclosed-reports.json
```

For each report: identify the bug class, the endpoint, and the root cause pattern.
Save patterns to `session/SESSION.md` under `## Known Patterns`.

---

## "What Changed" Method

1. Find a disclosed report for this tech stack
2. Get the fix commit
3. Read the diff — identify the anti-pattern
4. Grep your target for that same anti-pattern

```bash
# Example: find all places the same pattern exists
grep -rn "ANTI_PATTERN_HERE" --include="*.js" --include="*.ts" \
  | grep -v node_modules | tee session/pattern-hits.txt
```

---

## 6 Key Patterns from Top Reports

1. **Feature Complexity = Bug Surface** — imports, integrations, multi-tenancy,
   multi-step workflows
2. **Developer Inconsistency** — `timingSafeEqual` in one place, `===` elsewhere
3. **"Else Branch" Bug** — proxy passes raw token without validation in else path
4. **Import/Export = SSRF** — every "import from URL" feature has had SSRF
5. **Secondary/Legacy Endpoints = No Auth** — `/api/v1/` guarded but `/api/` isn't
6. **Race Windows in Financial Ops** — check-then-deduct as two DB ops = double-spend

---

## Threat Model Template

Fill this out and save to `session/threat-model.md`:

```
TARGET: _______________
CROWN JEWELS: 1.___ 2.___ 3.___

ATTACK SURFACE:
  [ ] Unauthenticated: login, register, password reset, public APIs
  [ ] Authenticated: all user-facing endpoints, file uploads, API calls
  [ ] Cross-tenant: org/team/workspace ID parameters
  [ ] Admin: /admin, /internal, /debug

TECH STACK: _______________
AUTH SYSTEM: _______________
INTERESTING FEATURES (import, export, webhooks, payments, AI): _______________

HIGHEST PRIORITY (crown jewel × easiest entry):
  1.___ 2.___ 3.___

VULN CLASSES TO TARGET (ranked by signal):
  1.___ 2.___ 3.___
```

---

## Pre-Hunt Mental Checklist

- [ ] I know the app's core business model
- [ ] I've used the app as a real user for 15+ minutes
- [ ] I know the tech stack (language, framework, auth, cache)
- [ ] I've read at least 3 disclosed reports for this program
- [ ] I have 2 test accounts ready (attacker + victim)
- [ ] I've defined my primary target: ONE crown jewel to hunt today

---

## Phase 2 Output Format

```
=== PHASE 2 COMPLETE: LEARN SUMMARY ===

Crown Jewel: <one sentence>

Tech Stack Confirmed: <stack>
Auth System: <JWT / session / OAuth / etc.>

Key Patterns from Disclosed Reports:
  - <pattern 1>
  - <pattern 2>

Priority Attack Surface:
  1. <endpoint/feature> — <reason>
  2. <endpoint/feature> — <reason>
  3. <endpoint/feature> — <reason>

Planned Vuln Classes (in order):
  1. <class> — <why this target>
  2. <class> — <why this target>
  3. <class> — <why this target>

=== Proceed to Phase 3 (Hunt)? [yes/no] ===
```
