#!/bin/bash
# Stop hook: vault session-end review gate.
#
# Blocks the FIRST stop of each session (once per session_id) with a request to
# review the vault per its AGENTS.md session-end ritual, and hands the session
# precomputed vault state so it doesn't have to gather it.
#
# This is a SEMANTIC gate, not an automatic journal writer: it asks the session
# to decide whether the turn produced durable cross-session state, because only
# the session has the context to choose the owning note, verify live claims, and
# summarize meaning. A script that parsed the transcript and wrote the vault
# itself would depend on an unstable format, risk copying secrets, and could not
# tell durable state from conversational detail.
#
# Install: registered per workspace in <workspace>/.claude/settings.local.json
# (vault-workspace-setup writes it). Part of the project-vault skill.
#
# NOTE: the guard walks up from $PWD to find the vault. Never hardcode a path
# here — a hardcoded root fails SILENTLY on another machine (the guard simply
# never matches and the gate never fires), and a broken gate looks exactly like
# a satisfied one.

INPUT=$(cat)

# --- Locate the vault: nearest ancestor that is, or contains, the vault -------
VAULT=""
d="$PWD"
while [ "$d" != "/" ]; do
  for c in "$d" "$d"/*/; do
    c="${c%/}"
    if [ -f "$c/AGENTS.md" ] && [ -f "$c/HOME.md" ] && [ -d "$c/bases" ]; then
      VAULT="$c"; break 2
    fi
  done
  d=$(dirname "$d")
done
[ -n "$VAULT" ] || exit 0     # not in a vault workspace — stay silent

# --- Never re-block a continuation of a previous stop-hook block --------------
# jq, not an inline interpreter: endpoint security tools (CrowdStrike Falcon is
# one) treat "code from argv that reads stdin" as fileless execution and kill
# the process tree, so the hook would fail with no output at all.
SESSION_ID=$(printf '%s' "$INPUT" | jq -r 'if .stop_hook_active then "ACTIVE" else (.session_id // "unknown") end' 2>/dev/null)
[ "$SESSION_ID" = "ACTIVE" ] && exit 0
[ -z "$SESSION_ID" ] && exit 0

# --- One review per session ---------------------------------------------------
SENTINEL="${TMPDIR:-/tmp}/claude-vault-stop-${SESSION_ID}"
[ -f "$SENTINEL" ] && exit 0
touch "$SENTINEL" 2>/dev/null

# --- Precompute vault state (all read-only) -----------------------------------
TODAY=$(date '+%Y-%m-%d')
NOW=$(date '+%H:%M')
DIRTY=$(git -C "$VAULT" status --porcelain 2>/dev/null | head -8)
AHEAD=$(git -C "$VAULT" rev-list --count '@{u}..HEAD' 2>/dev/null || echo "no upstream")
if [ -f "$VAULT/journal/$TODAY.md" ]; then JOURNAL="exists"; else JOURNAL="MISSING"; fi

STATE="Vault state (measured now, $TODAY $NOW): uncommitted changes: $([ -n "$DIRTY" ] && echo yes || echo none); unpushed commits: $AHEAD; today's journal note ($TODAY.md): $JOURNAL."
if [ -n "$DIRTY" ]; then
  STATE="$STATE Dirty paths: $(printf '%s' "$DIRTY" | tr '\n' ' ' | cut -c1-300)"
fi

REASON="Session-end vault review (fires once per session). $STATE Review whether this session produced durable cross-session state, then follow the vault's AGENTS.md session-end ritual: update status/updated/verified and Follow-ups in the notes that own them, append a journal block to journal/$TODAY.md (heading time measured with date '+%H:%M'), ensure any PR still open now has a prs/ note, commit only this session's paths, then git pull --rebase and git push. If uncommitted changes belong to another concurrently running session, leave them alone and say so. If this session did nothing vault-worthy and the state above is clean, say so briefly and stop — this gate will not fire again this session, and a no-op does not need a user-facing announcement."

jq -nc --arg reason "$REASON" '{decision: "block", reason: $reason}'
exit 0
