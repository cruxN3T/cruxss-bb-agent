## 3A. Information Gathering & Configuration
*CRUXSS-CONF-01 through -13 | CRUXSS-ERRH-01 through -02*

```bash
# Sensitive files (CRUXSS-CONF-03, CRUXSS-CONF-04)
ffuf -u https://TARGET/FUZZ \
  -w ~/wordlists/SecLists/Discovery/Web-Content/raft-medium-files.txt \
  -e .bak,.old,.sql,.zip,.log,.env,.conf,.inc,.swp \
  -mc 200,301,302 -ac

# HTTP method testing (CRUXSS-CONF-06, CRUXSS-API-DISC-04)
curl -s -X OPTIONS https://TARGET -v 2>&1 | grep "Allow:"

# Admin interface enumeration (CRUXSS-CONF-05, CRUXSS-API-DISC-01)
ffuf -u https://TARGET/FUZZ \
  -w ~/wordlists/SecLists/Discovery/Web-Content/common.txt \
  -mc 200,301,302,403 -ac

# Error message leakage (CRUXSS-ERRH-01, CRUXSS-API-DATA-03)
curl -s "https://TARGET/api/nonexistent" -H "Accept: application/json"
curl -s "https://TARGET/api/users?id='" -H "Accept: application/json"
```

---

