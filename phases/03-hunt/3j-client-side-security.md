## 3J. Client-Side Security
*CRUXSS-CLNT-01 through -11 | CRUXSS-CRYP-01 through -04*

```bash
# DOM XSS sinks (CRUXSS-CLNT-01)
grep -rn "innerHTML\|document.write\|eval(\|location.href" \
  --include="*.js" | grep -v node_modules

# Prototype pollution (CRUXSS-CLNT-02)
grep -rn "__proto__\|constructor\[" --include="*.js" | grep -v node_modules

# postMessage without origin check (CRUXSS-CLNT-10)
grep -rn "postMessage\|addEventListener.*message" --include="*.js" | grep -v node_modules

# CORS misconfiguration (CRUXSS-CLNT-07, CRUXSS-API-CONF-01)
curl -s "https://TARGET/api/user" \
  -H "Origin: https://evil.com" \
  -H "Cookie: session=TOKEN" -I | grep -i "access-control"
# Dangerous: Access-Control-Allow-Origin: https://evil.com
#           + Access-Control-Allow-Credentials: true

# Clickjacking (CRUXSS-CLNT-08)
curl -I https://TARGET | grep -i "x-frame-options\|frame-ancestors"

# WebSocket testing (CRUXSS-CLNT-09)
# websocat wss://TARGET/ws
# Test: no auth, injection via messages, CSWSH

# Browser storage (CRUXSS-CLNT-11)
# DevTools → Application → localStorage/sessionStorage
# Look for: session tokens, PII, JWT in storage
```

### Cryptography (CRUXSS-CRYP-01 through -04)
```bash
# TLS weaknesses (CRUXSS-CRYP-01)
testssl.sh --fast --color 0 https://TARGET | tee session/tls.txt

# Padding oracle (CRUXSS-CRYP-02)
# padBuster https://TARGET/page ENCRYPTED_VALUE 8 --encoding 0

# Sensitive data over HTTP (CRUXSS-CRYP-03)
# Check if login form POSTs to http:// vs https://
```

---

