## 3B. Authentication Testing
*CRUXSS-ATHN-01 through -10 | CRUXSS-API-AUTH-02 | CRUXSS-API-AUTH-05 | CRUXSS-API-AUTH-06*

```bash
# Default credentials (CRUXSS-ATHN-01, CRUXSS-INT-CRED-08)
# Try: admin:admin, admin:password, admin:123456, root:root

# Account lockout (CRUXSS-ATHN-02) — test BEFORE password spraying
# Send 5 wrong attempts, verify lockout triggers

# Password reset weakness (CRUXSS-ATHN-08)
# 1. Request reset for victim@email.com
# 2. Check token entropy (< 16 hex chars? = brute-forceable)
# 3. Request second token — does first still work?
# 4. Use token after 2 hours — expired?
```

### JWT Testing (CRUXSS-SESS-10, CRUXSS-API-AUTH-02)
```bash
# Decode and inspect
jwt_tool TOKEN -T

# alg=none attack
jwt_tool TOKEN -X a

# RS256 → HS256 confusion
jwt_tool TOKEN -X k -pk public.pem

# Weak secret brute force
hashcat -a 0 -m 16500 TOKEN ~/wordlists/SecLists/Passwords/Common-Credentials/10-million-password-list-top-1000000.txt
```

### API Key Security (CRUXSS-API-AUTH-06)
```bash
# Check if key appears in URLs (logged by proxies)
grep -r "api_key=\|apikey=\|token=" session/urls.txt

# Check if key appears in JS files
cat session/jsfiles.txt | xargs -I{} curl -s {} | \
  grep -iE "api_key|secret|token|password" | grep -v "example\|sample"
```

---

