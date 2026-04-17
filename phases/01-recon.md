# Phase 1: Recon

## Entry Checklist
- [ ] Target domain confirmed in scope
- [ ] Program policy URL saved to session
- [ ] Two test accounts created (attacker + victim)

---

## 1A. Passive OSINT & Asset Discovery
*CRUXSS-EXT-RCON-01 through -07 | CRUXSS-CLD-RCON-01 through -04 | CRUXSS-INFO-01 through -09*

```bash
TARGET="TARGET_DOMAIN"

# Subdomains (CRUXSS-EXT-RCON-02, CRUXSS-INFO-04)
subfinder -d $TARGET -silent | anew session/subs.txt
assetfinder --subs-only $TARGET | anew session/subs.txt

# Certificate transparency logs (CRUXSS-EXT-RCON-05)
curl -s "https://crt.sh/?q=%25.$TARGET&output=json" \
  | jq -r '.[].name_value' | sed 's/\*\.//g' | sort -u \
  | anew session/subs.txt

# ASN & IP range discovery (CRUXSS-EXT-RCON-03)
# Manual: https://bgpview.io/search/$TARGET, https://dnsdumpster.com

# Leaked credentials (CRUXSS-EXT-RCON-04, CRUXSS-CLD-RCON-04)
trufflehog github --org=$(echo $TARGET | cut -d. -f1) --only-verified \
  2>/dev/null | tee session/secrets-github.txt

echo "[*] Subdomains found: $(wc -l < session/subs.txt)"
```

### Google Dork Quick Set (CRUXSS-INFO-01)
```
site:TARGET filetype:env OR filetype:sql OR filetype:log
site:TARGET "api_key" OR "secret_key" OR "password" OR "token"
site:TARGET inurl:admin OR inurl:login OR inurl:dashboard OR inurl:debug
site:TARGET ext:bak OR ext:old OR ext:backup OR ext:swp
```

---

## 1B. DNS & Email Security
*CRUXSS-EXT-RCON-02 | CRUXSS-EXT-RCON-07 | CRUXSS-EXT-EXPL-06*

```bash
# DNS enumeration
dig any $TARGET
dnsrecon -d $TARGET -t std 2>/dev/null | tee session/dns.txt

# Zone transfer attempt (CRUXSS-EXT-EXPL-06)
for ns in $(dig ns $TARGET +short); do
  dig @$ns $TARGET axfr 2>/dev/null | tee -a session/zonetransfer.txt
done

# Email security — SPF / DMARC / DKIM (CRUXSS-EXT-RCON-07)
dig txt $TARGET | grep -iE "spf|v=spf" | tee session/email-security.txt
dig txt _dmarc.$TARGET >> session/email-security.txt
echo "Email spoofing check: $(cat session/email-security.txt | wc -l) records found"
```

---

## 1C. Live Host Discovery & Tech Fingerprinting
*CRUXSS-EXT-SCAN-01 through -07 | CRUXSS-INFO-02 | CRUXSS-INFO-08 | CRUXSS-INFO-09*

```bash
# Resolve + live hosts with tech detect (CRUXSS-EXT-SCAN-01, -02, -03)
cat session/subs.txt | dnsx -silent | \
  httpx -silent -status-code -title -tech-detect -ip \
  -o session/live.txt
echo "[*] Live hosts: $(wc -l < session/live.txt)"

# WAF detection (CRUXSS-INFO-09)
wafw00f https://$TARGET -o session/waf.txt 2>/dev/null

# URL collection for crawling (CRUXSS-EXT-SCAN-03)
cat session/live.txt | awk '{print $1}' | \
  katana -d 3 -silent | anew session/urls.txt
echo $TARGET | waybackurls | anew session/urls.txt
gau $TARGET | anew session/urls.txt
echo "[*] URLs collected: $(wc -l < session/urls.txt)"

# VPN & remote access enumeration (CRUXSS-EXT-SCAN-07)
cat session/live.txt | awk '{print $1}' | \
  httpx -silent -path "/remote,/vpn,/citrix,/pulse,/sslvpn,/rdweb" -mc 200,302 \
  | tee session/remote-access.txt

# SNMP check (CRUXSS-EXT-SCAN-06)
# onesixtyone -c /usr/share/doc/onesixtyone/dict.txt $TARGET | tee session/snmp.txt
```

### Technology Fingerprinting (CRUXSS-INFO-02, CRUXSS-INFO-08)

| Signal | Technology |
|---|---|
| `Cookie: XSRF-TOKEN + *_session` | Laravel |
| `Cookie: PHPSESSID` | PHP |
| `X-Powered-By: Express` | Node.js/Express |
| `wp-json / wp-content` | WordPress |
| `{"errors":[{"message":` | GraphQL |
| `X-Powered-By: Next.js` | Next.js |
| `CF-Ray:` | Cloudflare CDN |
| `X-Varnish:` | Varnish cache |
| WAF present | Use WAFW00F to fingerprint |

---

## 1D. Cloud Asset Enumeration
*CRUXSS-EXT-RCON-06 | CRUXSS-CLD-RCON-01 | CRUXSS-CLD-RCON-02 | CRUXSS-CONF-11*

```bash
BASE="${TARGET%%.*}"

# S3 bucket brute (CRUXSS-CLD-RCON-02, CRUXSS-CONF-11)
for suffix in "" "-dev" "-staging" "-test" "-backup" "-api" \
              "-data" "-assets" "-static" "-cdn" "-prod" "-uploads"; do
  name="${BASE}${suffix}"
  code=$(curl -s -o /dev/null -w "%{http_code}" \
    "https://${name}.s3.amazonaws.com/")
  [ "$code" != "404" ] && echo "$code  s3://$name" | tee -a session/cloud-assets.txt
done

# Firebase open read (CRUXSS-CLD-RCON-01)
fb_code=$(curl -s -o /dev/null -w "%{http_code}" \
  "https://${BASE}.firebaseio.com/.json")
echo "Firebase $BASE: $fb_code" >> session/cloud-assets.txt

# Cloud secrets in public repos (CRUXSS-CLD-RCON-04)
gitleaks detect --source . --report-path session/gitleaks.json 2>/dev/null

echo "[*] Cloud assets checked → session/cloud-assets.txt"
```

---

## 1E. Vulnerability Scanning & Quick Wins
*CRUXSS-EXT-SCAN-04 | CRUXSS-CONF-01 through -13*

```bash
# Nuclei scan — critical/high/medium (CRUXSS-EXT-SCAN-04)
nuclei -l session/live.txt -severity critical,high,medium \
  -silent -o session/nuclei.txt
echo "[*] Nuclei findings: $(wc -l < session/nuclei.txt)"

# Sensitive file discovery (CRUXSS-CONF-03, CRUXSS-CONF-04)
cat session/urls.txt | grep -iE \
  "\.env$|\.git/|\.bak$|\.sql$|\.zip$|\.log$|\.conf$|\.old$|config\." \
  > session/quickwins.txt

# JS files for secret scanning (CRUXSS-INFO-05)
cat session/urls.txt | grep "\.js$" | sort -u > session/jsfiles.txt
echo "[*] JS files: $(wc -l < session/jsfiles.txt)"

# Admin panel discovery (CRUXSS-CONF-05)
ffuf -u https://$TARGET/FUZZ \
  -w ~/wordlists/SecLists/Discovery/Web-Content/common.txt \
  -mc 200,301,302,403 -ac -o session/dirs.json 2>/dev/null
```

### SSL/TLS Check (CRUXSS-CRYP-01, CRUXSS-EXT-EXPL-04)
```bash
testssl.sh --fast --color 0 $TARGET 2>/dev/null | tee session/tls.txt
# Flag: SSLv2, SSLv3, TLS 1.0/1.1, RC4, HEARTBLEED, POODLE, BEAST
```

### Framework Quick Wins (CRUXSS-CONF-02, CRUXSS-INFO-08)

```bash
# Laravel
curl -sk https://$TARGET/horizon
curl -sk https://$TARGET/telescope
curl -sk https://$TARGET/.env

# WordPress
curl -sk https://$TARGET/wp-json/wp/v2/users
curl -sk "https://$TARGET/?author=1"

# Node/Express / GraphQL
curl -sk https://$TARGET/graphql \
  -H "Content-Type: application/json" \
  -d '{"query":"{__schema{types{name}}}"}'

# Spring Boot actuators
for p in env heapdump mappings beans; do
  code=$(curl -sk -o /dev/null -w "%{http_code}" https://$TARGET/actuator/$p)
  echo "actuator/$p: $code"
done

# Kubernetes API (CRUXSS-CLD-COMP-04)
curl -sk https://$TARGET:6443/api/v1/namespaces/default/pods

# Docker API exposed (CRUXSS-CLD-COMP-04)
curl -s http://$TARGET:2375/containers/json
```

---

## 1F. Source Code Recon (if repo available)
*CRUXSS-INFO-05 | CRUXSS-CLD-RCON-04*

```bash
# Changelog / security history
cat SECURITY.md 2>/dev/null
cat CHANGELOG.md | head -100 | grep -i "security\|fix\|CVE"
git log --oneline --all --grep="security\|CVE\|fix\|vuln" | head -20

# Dangerous sinks (JS/TS)
grep -rn "eval(\|innerHTML\|dangerouslySetInner\|execSync" \
  --include="*.ts" --include="*.js" | grep -v node_modules

# TODOs and unsafe markers
grep -rn "TODO\|FIXME\|HACK\|UNSAFE" \
  --include="*.ts" --include="*.js" | grep -iv "test\|spec"

# Secrets in code (CRUXSS-CLD-RCON-04)
trufflehog filesystem . --only-verified 2>/dev/null \
  | tee session/secrets-code.txt
```

---

## 1G. HackerOne / Bugcrowd Scope Retrieval

```bash
PROGRAM="PROGRAM_HANDLE"
curl -s "https://hackerone.com/graphql" \
  -H "Content-Type: application/json" \
  -d '{"query":"query { team(handle: \"'$PROGRAM'\") { name policy_scopes(archived: false) { edges { node { asset_type asset_identifier eligible_for_bounty } } } } }"}' \
  | jq '.data.team.policy_scopes.edges[].node' \
  | tee session/scope.json
```

---

## Quick Wins Checklist

- [ ] Subdomain takeover — CRUXSS-CONF-10
- [ ] Exposed `.git` (`/.git/config`) — CRUXSS-CONF-04
- [ ] Exposed `.env` — CRUXSS-CONF-03
- [ ] Default credentials on admin panels — CRUXSS-ATHN-01
- [ ] JS secrets (trufflehog, SecretFinder) — CRUXSS-INFO-05
- [ ] Open redirects (`?redirect=`, `?next=`, `?url=`) — CRUXSS-INPV-15
- [ ] CORS misconfig — CRUXSS-CLNT-07
- [ ] S3/GCS/Azure blob public — CRUXSS-CONF-11, CRUXSS-CLD-RCON-02
- [ ] GraphQL introspection enabled — CRUXSS-API-GQL-01
- [ ] Spring actuators (`/actuator/env`) — CRUXSS-CONF-02
- [ ] Firebase open read/write — CRUXSS-CLD-RCON-01
- [ ] DNS zone transfer succeeded — CRUXSS-EXT-EXPL-06
- [ ] Email spoofing possible (SPF/DMARC missing) — CRUXSS-EXT-RCON-07
- [ ] SSL/TLS weaknesses (TLS 1.0, HEARTBLEED) — CRUXSS-CRYP-01
- [ ] Kubernetes API unauthenticated — CRUXSS-CLD-COMP-04
- [ ] Docker API exposed on port 2375 — CRUXSS-CLD-COMP-04

---

## Phase 1 Output Format

```
=== PHASE 1 COMPLETE: RECON SUMMARY ===

Target: <domain>
Subdomains found: <N>
Live hosts: <N>
URLs collected: <N>
Nuclei findings: <N> (see session/nuclei.txt)
Cloud assets: <list or "none found">
Email security: SPF=<ok/missing>  DMARC=<ok/missing>
TLS: <ok / weak ciphers / HEARTBLEED / etc.>

Tech Stack:
  - <framework> on <subdomain>
  - WAF: <vendor or "none detected">

Quick Wins Triggered:
  - [CRUXSS-ID] <finding> at <location>

Priority Subdomains for Hunting:
  1. <subdomain> — <reason>
  2. <subdomain> — <reason>
  3. <subdomain> — <reason>

=== Proceed to Phase 2 (Learn)? [yes/no] ===
```
