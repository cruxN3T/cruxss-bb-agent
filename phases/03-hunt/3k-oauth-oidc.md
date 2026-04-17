## 3K. OAuth / OIDC
*CRUXSS-ATHZ-05 | CRUXSS-API-AUTH-05 | CRUXSS-EXT-EXPL-05*

```bash
# Missing state parameter → CSRF (CRUXSS-ATHZ-05)
# Remove state param from auth request, observe if it still completes

# Open redirect in redirect_uri → ATO
curl "https://TARGET/oauth/authorize?client_id=X&redirect_uri=https://evil.com&response_type=code"

# Missing PKCE → code theft
# Intercept auth code, replay without code_verifier

# Token in referrer leak
# After clicking email reset link, does page load external resources?
# External server logs contain the token in Referer header
```

---

