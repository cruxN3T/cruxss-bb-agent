## 3D. Session Management
*CRUXSS-SESS-01 through -10*

```bash
# Session fixation (CRUXSS-SESS-03)
# 1. Note session token BEFORE login
# 2. Login
# 3. Check if token changed — if not = fixation

# Cookie attributes (CRUXSS-SESS-02)
curl -I https://TARGET/login | grep -i "set-cookie"
# Verify: HttpOnly, Secure, SameSite=Strict on session cookies

# CSRF testing (CRUXSS-SESS-05)
# 1. Find state-changing POST request
# 2. Remove CSRF token — does it still work?
# 3. Use CSRF token from account A in account B's request

# Session timeout (CRUXSS-SESS-07)
# 1. Log in, wait 30+ min idle
# 2. Make request — still valid?

# Session not invalidated on logout (CRUXSS-SESS-06)
# 1. Log in, copy session token
# 2. Log out
# 3. Replay request with old token — still works?
```

---

