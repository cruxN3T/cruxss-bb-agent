# Security Policy

## Intended Use

This tool is for authorized security testing only:
- Bug bounty programs with explicit permission
- Penetration testing with a signed SOW/ROE
- Your own systems

Do not use against systems you do not have written permission to test.

## Reporting Issues With This Tool

1. Do not open a public GitHub issue for security vulnerabilities
2. Contact via GitHub: https://github.com/cruxN3T
3. Allow 90 days for response before public disclosure

## API Key Safety

API keys and credentials are stored locally on disk only — never in
this repository. Pre-commit hooks block accidental credential commits.
Never paste credentials into any file in this repository.

## Session Data

Real findings, PoCs, target names, and engagement data never belong in
this public repository. Use the private session pattern described in
SETUP.md.
