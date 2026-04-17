#!/bin/bash
# scout-test.sh — Test the H1 API connection and preview program data
# Run: bash scout-test.sh

set -e

echo "=== CRUXSS Scout — API Test ==="
echo ""

# Load credentials
source ~/.config/cruxss/h1.env
AUTH=$(echo -n "$H1_USERNAME:$H1_TOKEN" | base64)

echo "[*] Credentials loaded"
echo "[*] Username: $H1_USERNAME"
echo "[*] Token length: ${#H1_TOKEN} chars"
echo ""

# Test 1 — Fetch first page of programs
echo "[*] Fetching programs from H1 API..."
PROGRAMS=$(wget -q -O- \
  "https://api.hackerone.com/v1/hackers/programs?page[size]=10" \
  --header="Accept: application/json" \
  --header="Authorization: Basic $AUTH" \
  --timeout=15)

COUNT=$(echo "$PROGRAMS" | jq '.data | length')
echo "[*] Programs fetched: $COUNT"
echo ""

# Test 2 — Show program names and bounty info
echo "=== Sample Programs ==="
echo "$PROGRAMS" | jq -r '.data[] | 
  "  " + .attributes.name + 
  " | bounties: " + (.attributes.offers_bounties | tostring) +
  " | fast_pay: " + (.attributes.fast_payments | tostring) +
  " | safe_harbor: " + (.attributes.gold_standard_safe_harbor | tostring)'
echo ""

# Test 3 — Fetch scopes for first program
HANDLE=$(echo "$PROGRAMS" | jq -r '.data[0].attributes.handle')
echo "[*] Fetching scope for: @$HANDLE"
SCOPES=$(wget -q -O- \
  "https://api.hackerone.com/v1/hackers/programs/$HANDLE/structured_scopes" \
  --header="Accept: application/json" \
  --header="Authorization: Basic $AUTH" \
  --timeout=15)

SCOPE_COUNT=$(echo "$SCOPES" | jq '.data | length')
echo "[*] Scope assets found: $SCOPE_COUNT"
echo ""

echo "=== Sample Scope Assets ==="
echo "$SCOPES" | jq -r '.data[:3][] | 
  "  " + .attributes.asset_type + 
  ": " + .attributes.asset_identifier +
  " | bounty: " + (.attributes.eligible_for_bounty | tostring) +
  " | max_severity: " + .attributes.max_severity'
echo ""

# Test 4 — Fetch recent hacktivity
echo "[*] Fetching recent hacktivity..."
HACKTIVITY=$(wget -q -O- \
  "https://api.hackerone.com/v1/hackers/hacktivity?queryString=disclosed:true&page[size]=5" \
  --header="Accept: application/json" \
  --header="Authorization: Basic $AUTH" \
  --timeout=15)

HACK_COUNT=$(echo "$HACKTIVITY" | jq '.data | length')
echo "[*] Recent disclosed reports: $HACK_COUNT"
echo ""

echo "=== Recent Disclosed Reports ==="
echo "$HACKTIVITY" | jq -r '.data[] | 
  "  [" + .attributes.severity_rating + "] " + 
  .attributes.title[:60] +
  " | $" + (.attributes.total_awarded_amount | tostring)'
echo ""

echo "=== ✅ All API tests passed ==="
echo "Run /scout find in Claude Code to start program discovery"
