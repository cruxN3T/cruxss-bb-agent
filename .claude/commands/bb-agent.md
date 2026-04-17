Execute the CRUXSS bug bounty agent pipeline.

Read /vaults/cruxss/CLAUDE.md first for operating rules.

When the user types `/bb-agent start <target>`:

1. Create a session folder for this target:
   FOLDER=/vaults/cruxss/session/$(date +%Y-%m-%d)-<target>
   mkdir -p $FOLDER/{leads,bugs,chains,reports}

2. Create SESSION.md inside that folder:
   /vaults/cruxss/session/$(date +%Y-%m-%d)-<target>/SESSION.md

3. All findings, leads, bugs, chains, and reports for this target
   go inside that folder — never in the root session/ folder

4. Read /vaults/cruxss/phases/01-recon.md
5. Run the recon pipeline against <target>
6. Write all findings to the target SESSION.md
7. Present Phase 1 summary and ask: "=== Proceed to Phase 2? [yes/no] ==="
8. On yes, read /vaults/cruxss/phases/02-learn.md and continue
9. Never load 03-hunt.md as a whole — load individual files from
   /vaults/cruxss/phases/03-hunt/ on demand only
10. Pause for human approval at every phase transition

Available commands:
- /bb-agent start <target> — full pipeline
- /bb-agent recon <target> — Phase 1 only
- /bb-agent hunt — Phase 3 on current session
- /bb-agent validate — Phase 4 on current leads
- /bb-agent report <BUG-NNN> — draft report
- /bb-agent status — show all sessions
- /bb-agent chain <bug> — suggest B/C chains
