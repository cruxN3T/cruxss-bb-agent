## 3L. API-Specific Testing
*CRUXSS-API-DISC-01 through -04 | CRUXSS-API-DATA-01 through -03 | CRUXSS-API-CONF-01 through -03*

```bash
# API endpoint discovery (CRUXSS-API-DISC-01)
ffuf -u https://TARGET/api/FUZZ \
  -w ~/wordlists/SecLists/Discovery/Web-Content/api/api-endpoints.txt \
  -mc 200,201,301,302,403 -ac

# API version enumeration (CRUXSS-API-DISC-03)
for v in v1 v2 v3 beta legacy; do
  code=$(curl -s -o /dev/null -w "%{http_code}" https://TARGET/api/$v/users)
  echo "api/$v/users: $code"
done

# Excessive data exposure (CRUXSS-API-DATA-01)
# Compare: what GET /api/users returns vs what app displays
# Extra fields in response = over-exposure

# Hidden parameters (CRUXSS-API-DISC-04)
arjun -u https://TARGET/api/endpoint --stable -t 5 2>/dev/null
```

---

