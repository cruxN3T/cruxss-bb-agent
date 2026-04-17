# Phase 5: Report

## Human Tone Rules

- Start with impact, not the vulnerability name
- Write like explaining to a smart developer, not a textbook
- Use "I" and active voice: "I found that..." not "A vulnerability was discovered..."
- One concrete example beats three abstract sentences
- No em dashes, no "comprehensive/leverage/seamless/ensure"
- Keep it under 600 words — triagers skim long reports
- Include CRUXSS-ID and CWE in all internal tracking (optional in submission)

---

## Report Title Formula

```
[Bug Class] in [Exact Endpoint/Feature] allows [attacker role] to [impact] [victim scope]
```

### Good Titles
- `IDOR in /api/v2/invoices/{id} allows authenticated user to read any customer's invoice`
- `Missing auth on POST /api/admin/users allows unauthenticated attacker to create admin accounts`
- `Stored XSS in profile bio executes in admin panel — allows privilege escalation`
- `SSRF via image import URL reaches AWS EC2 metadata service (IMDSv1)`
- `Race condition in coupon redemption allows same code to be used unlimited times`
- `JWT alg=none accepted — allows any authenticated session to be forged`
- `Mass assignment in PUT /api/user allows regular user to escalate to admin role`

### Bad Titles
- `IDOR vulnerability found`
- `Broken access control`
- `Security issue in API`
- `Vulnerability in target.com`

---

## Impact Statement Formula (First Paragraph)

```
An [attacker with X access level] can [exact action] by [method],
resulting in [business harm]. This requires [prerequisites] and
leaves [detection/reversibility].
```

---

## HackerOne Report Template

```markdown
**Summary:**
[2-3 sentences: what it is, where it is, what attacker can do]

**Steps To Reproduce:**
1. Log in as attacker (account A: attacker@test.com)
2. Send the following request:

   ```
   [paste exact HTTP request — curl or raw HTTP]
   ```

3. Observe: [exact response or behavior showing the bug]
4. Confirm: [what the attacker gained — screenshot/response included]

**Supporting Material:**
- [Screenshot or video of exploitation]
- [Response body showing accessed data]

**Impact:**
An attacker can [specific action] resulting in [specific harm].
This affects [N users / all users / any user with X].

**Severity Assessment:**
CVSS 3.1 Score: X.X ([Severity])
Vector: AV:N/AC:L/PR:L/UI:N/S:U/C:H/I:H/A:N

**Remediation:**
[1-2 sentences of specific fix — not a lecture]
```

---

## Bugcrowd Report Template

```markdown
**Title:** [Vuln] at [endpoint] — [Impact in one line]

**Bug Type:** [IDOR / SSRF / XSS / SQLi / RCE / etc.]
**Target:** [URL or component]
**Severity:** [P1 / P2 / P3 / P4]

**Description:**
[Root cause + exact location, 2-3 sentences]

**Reproduction:**
1. [step]
2. [step]
3. [step]

**Impact:**
[Concrete business impact — quantify if possible]

**Fix Suggestion:**
[Specific remediation, 1-2 sentences]
```

---

## Internal Findings Summary Record
*Mirrors the CRUXSS Findings Summary sheet from all checklists*

Save each validated finding to `session/reports/findings-summary.md`:

```markdown
| # | CRUXSS-ID | Finding Title | Severity | CVSS | CWE | Affected Endpoint | Impact | Status |
|---|---|---|---|---|---|---|---|---|
| 1 | CRUXSS-ATHZ-04 | IDOR in /api/invoices/{id} | High | 7.5 | CWE-639 | /api/v2/invoices/{id} | Read any invoice | Validated |
| 2 | CRUXSS-INPV-11 | SSRF via import URL | Critical | 9.1 | CWE-918 | /api/import?url= | Cloud metadata access | Validated |
```

---

## Report by Bug Class — Quick Reference

### IDOR (CRUXSS-ATHZ-04, CRUXSS-API-AUTH-01)
- Lead with: how many users/records are exposed
- Include: victim account ID, attacker account ID, swapped request, response diff
- CVSS note: no PR:N unless endpoint is unauthenticated

### SSRF (CRUXSS-INPV-11, CRUXSS-CLD-COMP-01)
- Lead with: what internal system was reached
- Include: the exact URL payload, the response content
- If DNS-only: don't submit. Must show data returned.

### XSS (CRUXSS-INPV-01, CRUXSS-INPV-02)
- Lead with: who sees the payload execute (victim? admin?)
- Include: where stored, where triggered, video preferred
- Chain note: always check HttpOnly on session cookie for ATO chain

### SQLi (CRUXSS-INPV-04)
- Lead with: what data can be exfiltrated
- Include: the exact payload, confirm with time-based or union output
- Do NOT run `--dump` on production — document potential only

### Business Logic (CRUXSS-BUSL-01 through -10)
- Lead with: the exact financial or logical harm
- Include: exact parameter modified, before/after response comparison
- Quantify: "attacker gains $X" or "N items obtained free"

### Race Condition (CRUXSS-BUSL-04)
- Lead with: the result of the race (double-spend, double-redemption)
- Include: the parallel curl command + evidence of two successful responses

### Cloud / IAM (CRUXSS-CLD-ATK-01, CRUXSS-CLD-IAM-01)
- Lead with: what permissions the leaked key has
- Include: `aws sts get-caller-identity` output, policy listing
- Do NOT access production data — show permissions only

### Internal Network / AD (CRUXSS-INT-PRIV-03, CRUXSS-INT-DOM-01)
- Lead with: the full attack chain from low-priv to domain admin
- Include: BloodHound attack path screenshot
- Always clean up: remove all test artifacts before reporting

---

## Severity Escalation Language

When a payout is being downgraded, use these counters:

| Program Says | You Counter With |
|---|---|
| "Requires authentication" | "Attacker needs only a free account (no special role)" |
| "Limited impact" | "Affects [N] users / exposes [PII type] / [$ amount]" |
| "Already known" | "Show me the report number — I searched and found none" |
| "By design" | "Show me the documentation that states this is intended" |
| "Low CVSS score" | "CVSS doesn't account for business impact — attacker can steal [X]" |
| "Can't reproduce" | "Here is a video walkthrough / here is my exact test account" |

---

## 60-Second Pre-Submit Checklist

- [ ] Title follows formula: [Class] in [endpoint] allows [actor] to [impact]
- [ ] First sentence states exact impact in plain English
- [ ] Steps have exact HTTP request (copy-paste ready)
- [ ] Response / evidence showing the bug is included
- [ ] Two test accounts used (not just one account testing itself)
- [ ] CVSS score calculated and included
- [ ] Recommended fix is 1-2 sentences (not a lecture)
- [ ] No typos in endpoint path or parameter names
- [ ] Report is under 600 words
- [ ] Severity claimed matches impact described (don't overclaim)
- [ ] CRUXSS-ID recorded in session/reports/findings-summary.md
- [ ] All test artifacts cleaned up (especially for internal/cloud tests)

---

## Agent Report Generation

When the agent generates a report, it will:

1. Read the validated bug from `session/bugs/BUG-NNN-poc.txt`
2. Check the chain file at `session/chains/` for any escalation context
3. Fill the appropriate template (H1 or Bugcrowd based on target program)
4. Record the finding in `session/reports/findings-summary.md`
5. Save the draft to `session/reports/BUG-NNN-draft.md`
6. Present the draft to the operator for review and editing
7. On approval, output the final report ready to paste

**The agent will NOT auto-submit. Final submission is always manual.**
