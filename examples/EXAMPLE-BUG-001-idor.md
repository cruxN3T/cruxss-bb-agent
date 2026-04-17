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
