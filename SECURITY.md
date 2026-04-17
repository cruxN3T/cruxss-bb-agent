# Security Policy

## Intended Use

This tool is for authorized security testing only:
- Bug bounty programs with explicit permission
- Penetration testing with a signed SOW/ROE
- Your own systems

Do not use against systems you do not have written permission to test.

## Reporting Issues With This Tool

1. Do not open a public GitHub issue for security vulnerabilities
2. Email: contact@redacted
3. Allow 90 days for response before public disclosure

## API Key Safety

API keys are stored by Claude Code in ~/.claude/ — never in this repo.
Pre-commit hooks block accidental key commits.
Never paste credentials into any file in this repository.

## Session Data

Real findings, PoCs, and target data never belong in this public repo.
Use the private session repo pattern described in the README.
