# Phase 4: Validate

## The Only Question That Matters
> "Can an attacker do this RIGHT NOW against a real user who took NO unusual
> actions — and does it cause real harm (stolen money, leaked PII, ATO, RCE)?"

---

## 7-Question Gate

Run every lead through ALL 7. Any NO = kill it.

**Q1: Can I exploit this RIGHT NOW with a real PoC?**
Write the exact HTTP request. No working request = kill it.

**Q2: Does it affect a REAL user who took NO unusual actions?**
No "the user would need to X" with preconditions. Victim did nothing special.

**Q3: Is the impact concrete (money, PII, ATO, RCE)?**
"Technically possible" is not impact. "I read victim's SSN" is impact.

**Q4: Is this in scope per the program policy?**
Check the exact domain/endpoint against `session/scope.json`.

**Q5: Did I check Hacktivity/changelog for duplicates?**
Search disclosed reports and recent changelog entries.
*Reference: CRUXSS-EXT-VULN-01, CRUXSS-INT-VULN-01*

**Q6: Is this NOT on the always-rejected list?**
See the list below.

**Q7: Would a triager reading this say "yes, that's a real bug"?**
Read your report as a tired triager at 5pm Friday. Does it pass?

---

## 4 Pre-Submission Gates

### Gate 0: Reality Check (30 seconds)
- [ ] Bug is real — confirmed with actual HTTP requests, not just code reading
- [ ] Bug is in scope — checked program scope explicitly
- [ ] Reproducible from scratch (not just once)
- [ ] Evidence ready (screenshot, response, video)

### Gate 1: Impact Validation (2 minutes)
- [ ] "What can an attacker DO that they couldn't before?" — answered
- [ ] Answer is more than "see non-sensitive data"
- [ ] Real victim: another user's data, company data, or financial loss
- [ ] Not relying on unlikely user behavior

### Gate 2: Deduplication Check (5 minutes)
*Reference: CRUXSS-EXT-VULN-01, CRUXSS-INT-VULN-01*
- [ ] Searched HackerOne Hacktivity for similar bug title
- [ ] Searched GitHub issues for target repo
- [ ] Read the 5 most recent disclosed reports
- [ ] Not a "known issue" in changelog or public docs

### Gate 3: Report Quality (10 minutes)
- [ ] Title: vuln class + location + impact (follows CRUXSS formula)
- [ ] Steps to reproduce: copy-pasteable HTTP request
- [ ] Evidence: screenshot/video of actual impact
- [ ] Severity: matches CVSS 3.1 AND program severity definitions
- [ ] Remediation: 1-2 sentences of concrete fix

---

## Attack Chain Documentation
*Reference: CRUXSS-EXT-VULN-02, CRUXSS-INT-POST-04, CRUXSS-CLD-ATK-03*

Before writing any report, map the full chain:

```
## Attack Chain: [BUG-001 + BUG-002]

Entry Point: <unauthenticated / low-privilege user / external attacker>
Step 1: [CRUXSS-ID] <action> at <endpoint>
  → Evidence: session/leads/001.txt
Step 2: [CRUXSS-ID] <escalation> leveraging result of Step 1
  → Evidence: session/leads/002.txt
Step 3: Impact: <concrete harm>

Crown Jewel Reached: [ ] funds  [ ] PII  [ ] ATO  [ ] RCE  [ ] domain takeover

Blast Radius: affects ___ users / ___ records / $___ value
```

Save to `session/chains/CHAIN-001.md`.

---

## Findings Summary Schema
*Based on CRUXSS Findings Summary sheets across all checklists*

For each validated bug, record:

```
BUG-NNN
  CRUXSS-ID:          CRUXSS-XXX-YYY-ZZ
  Finding Title:    [Class] in [endpoint] allows [actor] to [impact]
  Severity:         Critical / High / Medium / Low
  CVSS 3.1 Score:   X.X
  CVSS Vector:      AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:N
  CWE:              CWE-XXX
  OWASP / MITRE:    OWASP A01:2021 / T1190
  Affected Target:  https://target.com/api/endpoint
  Description:      [root cause + exact location]
  Impact:           [concrete business harm]
  Recommendation:   [specific fix]
  PoC:              session/bugs/BUG-NNN-poc.txt
  Evidence:         session/bugs/BUG-NNN-evidence/
  Status:           Validated
  Chain:            Part of CHAIN-NNN / Standalone
```

---

## CVSS 3.1 Quick Guide

| Factor | Low (0-3.9) | Medium (4-6.9) | High (7-8.9) | Critical (9-10) |
|---|---|---|---|---|
| Attack Vector | Physical | Local | Adjacent | Network |
| Privileges | High | Low | None | None |
| User Interaction | Required | Required | None | None |
| Impact | Partial | Partial | High | High (all 3) |

### Typical Scores by CRUXSS Class
| Bug | CVSS | Severity | CRUXSS-ID |
|---|---|---|---|
| IDOR (read PII) | 6.5 | Medium | CRUXSS-ATHZ-04 |
| IDOR (write/delete) | 7.5 | High | CRUXSS-ATHZ-04 |
| Auth bypass → admin | 9.8 | Critical | CRUXSS-ATHZ-02 |
| Stored XSS | 5.4–8.8 | Med–High | CRUXSS-INPV-02 |
| SQLi (data exfil) | 8.6 | High | CRUXSS-INPV-04 |
| SSRF (cloud metadata) | 9.1 | Critical | CRUXSS-CLD-COMP-01 |
| Race condition (double spend) | 7.5 | High | CRUXSS-BUSL-04 |
| GraphQL auth bypass | 8.7 | High | CRUXSS-API-GQL-03 |
| JWT none algorithm | 9.1 | Critical | CRUXSS-SESS-10 |
| SSTI → RCE | 9.8 | Critical | CRUXSS-INPV-10 |
| Mass assignment → admin | 8.8 | High | CRUXSS-INPV-14 |
| Subdomain takeover + OAuth | 9.0 | Critical | CRUXSS-CONF-10 |
| ADCS ESC1 → DA | 9.9 | Critical | CRUXSS-INT-PRIV-04 |
| IAM wildcard → cloud takeover | 9.8 | Critical | CRUXSS-CLD-IAM-01 |

---

## ALWAYS REJECTED — Never Submit These

Missing CSP/HSTS/security headers, missing SPF/DKIM/DMARC, GraphQL
introspection alone (CRUXSS-API-GQL-01 alone), banner/version disclosure without
working CVE exploit, clickjacking on non-sensitive pages (CRUXSS-CLNT-08 alone),
tabnabbing, CSV injection, CORS wildcard without credential exfil PoC,
logout CSRF, self-XSS, open redirect alone (CRUXSS-INPV-15 alone), OAuth
client_secret in mobile app (by design), SSRF DNS-ping only, host header
injection alone (CRUXSS-INPV-12 alone), no rate limit on non-critical forms,
session not invalidated on logout alone, concurrent sessions, internal IP
disclosure, mixed content, SSL weak ciphers alone, missing HttpOnly/Secure
flags alone (CRUXSS-SESS-02 alone), broken external links, pre-account takeover.

---

## Conditionally Valid With Chain

| Low Finding | + Chain | = Valid Bug | CRUXSS-IDs |
|---|---|---|---|
| Open redirect | + OAuth code theft | ATO | CRUXSS-INPV-15 + CRUXSS-ATHZ-05 |
| Clickjacking | + sensitive action + PoC | Account action | CRUXSS-CLNT-08 |
| CORS wildcard | + credentialed exfil | Data theft | CRUXSS-CLNT-07 |
| CSRF | + sensitive state change | ATO | CRUXSS-SESS-05 |
| No rate limit | + OTP brute force | ATO | CRUXSS-API-RATE-01 + CRUXSS-ATHN-02 |
| SSRF (DNS only) | + internal access proof | Internal network | CRUXSS-INPV-11 |
| Host header injection | + password reset poisoning | ATO | CRUXSS-INPV-12 + CRUXSS-ATHN-08 |
| Self-XSS | + login CSRF | Stored XSS on victim | CRUXSS-SESS-05 |
| GraphQL introspection | + missing field-level auth | Mass PII exfil | CRUXSS-API-GQL-01 + CRUXSS-API-GQL-03 |
| S3 public listing | + JS secrets | OAuth chain | CRUXSS-CLD-RCON-02 + CRUXSS-INFO-05 |

---

## CVE Validation & False Positive Removal
*Reference: CRUXSS-EXT-VULN-01, CRUXSS-INT-VULN-01*

For scanner findings (nuclei, nessus, etc.):
1. **Do not report raw scanner output** — manually verify every finding
2. Write a working PoC HTTP request for each finding
3. Confirm the finding is not a false positive before writing a report
4. Remove or downgrade theoretical-only findings
5. Rate each confirmed finding with CVSS v3.1

---

## Remediation Verification (Retest)
*Reference: CRUXSS-EXT-VULN-03, CRUXSS-INT-VULN-02*

When retesting fixed findings:
- Verify the exact PoC from the original report no longer works
- Check for incomplete fixes (patch masked, not fixed)
- Check for regressions in related functionality
- Document any partial fixes or bypasses separately

---

## Phase 4 Output Format

```
=== PHASE 4 COMPLETE: VALIDATED FINDINGS ===

VALIDATED (passed all 7 gates):

  [BUG-001] [CRUXSS-ATHZ-04] IDOR at /api/v2/invoices/{id}
    Impact: read any customer invoice (PII + financial data)
    CVSS: 6.5 (Medium)
    PoC: session/bugs/BUG-001-poc.txt
    Chain: standalone

  [BUG-002] [CRUXSS-INPV-11 + CRUXSS-CLD-COMP-01] SSRF → IMDSv1 → IAM keys
    Impact: AWS access key exfil → potential cloud takeover
    CVSS: 9.1 (Critical)
    PoC: session/bugs/BUG-002-poc.txt
    Chain: CHAIN-001 (SSRF → cloud metadata → IAM)

KILLED (failed gate — reason):
  - LEAD-003: failed Q3 (data already public in web UI)
  - LEAD-004: always-rejected list (open redirect, no OAuth chain built)

=== Proceed to Phase 5 (Report)? [yes/no] ===
```
