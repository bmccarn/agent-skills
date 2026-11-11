---
type: daily
status: active
updated: {{date}}
source: claude
---

# {{date}}

## ~HH:MM — <topic> (<source>)
`session: <claude|codex> <uuid>`

<!-- HH:MM comes from running `date '+%H:%M'` at write time — never estimate (AGENTS.md, Journal convention) -->
<!-- session uuid: `echo $CLAUDE_CODE_SESSION_ID` for Claude; see AGENTS.md "Session IDs" for Codex. One line per agent. -->
What happened, decisions, and why. Link every note touched. New follow-ups go in the owning notes, referenced from here.
