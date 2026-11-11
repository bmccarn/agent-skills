---
name: project-vault
description: "Use at session start and end in a project that has a project vault (an Obsidian work journal kept in a private GitHub repo named vault-<name>), and when asked to \"update the vault\", \"journal this\" or \"write up what we did\": find or clone the vault, read its state, write back state and a journal block, then commit and push."
---

# Project vault

The vault's own `AGENTS.md` is the contract. This skill finds the vault and is the checklist for reading and writing it; where the two disagree, the vault's `AGENTS.md` wins.

## 1. Find the vault

1. Walk up from the working directory. The vault is the nearest folder that is, or directly contains, a folder with `AGENTS.md`, `HOME.md` and `bases/`:

   ```bash
   find_vault() {
     d="$PWD"
     while [ "$d" != / ]; do
       for c in "$d" "$d"/*/; do
         c="${c%/}"
         [ -f "$c/AGENTS.md" ] && [ -f "$c/HOME.md" ] && [ -d "$c/bases" ] && { printf '%s\n' "$c"; return 0; }
       done
       d="$(dirname "$d")"
     done
     return 1
   }
   VAULT="$(find_vault)"
   ```

2. Otherwise look it up: `python3 scripts/vault-find.py <owner/repo | repo | workspace>` from this skill's folder. It reads the GitHub repos with the topic `vault` that belong to the signed-in `gh` account (or to the `owners` in `~/.config/project-vault.json`), each one's `vault.json` (project name, code repositories, local path), and prints the match as JSON with its local `path` and whether it is `cloned`. Add `--clone` to clone a missing vault; that also arms its commit guard. `--list` prints every vault.
3. No match means the project has no vault. Do not create one; `vault-workspace-setup` does that when the user asks.

GitHub is the meeting point and each machine has its own clone. Check `git -C "$VAULT" remote get-url origin` against the vault repo the workspace `AGENTS.md` names (or `vault-find.py` prints). A folder with no `origin`, or one that doesn't match, is a stale copy: stop before writing and report both values. Keep code checkouts where they are; a worktree uses its workspace's vault.

## 2. Session start

1. `git -C "$VAULT" pull --rebase`. Offline: say so, work from the local clone, and push once the network is back. A conflict: resolve it before writing anything.
2. Run `date '+%Y-%m-%d %H:%M'`; that, not your context, is today.
3. Read `HOME.md`, today's and yesterday's `journal/` notes, then the `projects/`, `prs/` or `tickets/` notes for the work at hand.

## 3. Session end

Write back only if the session produced durable cross-session state: commits, pushes, PR actions, deploys or applies; evidence-backed findings or corrections; decisions, blockers, ownership changes, handoff facts or follow-ups a later session needs. Greetings, explanations and checks that changed nothing need no writeback; say so in one line and stop.

1. **Measure the time** with `date '+%Y-%m-%d %H:%M'` right before writing. A session that crosses midnight writes to the new day's note.
2. **Owning notes first.** In every note the session touched: rewrite `## Current state` in place, add or check `## Follow-ups` boxes in the note that owns them, bump `updated:`, bump `verified:` only for claims you re-checked against the primary source, set `status:` (and `closed:` plus an `## Outcome` citing evidence when closing). Add a `## Log` line only for a milestone, stamped with the session ID. Unsure where something belongs: an `inbox/` note with the required frontmatter.
3. **Tickets.** A PR opened for a ticket gets `repo:` and `pr:` on the ticket note. Check off acceptance criteria you met, with evidence from a primary source, and say in the journal block when a ticket looks ready to close; leave its `status`, since the user closes tickets. A to-do that needs its own blockers, criteria or PR becomes a ticket (the vault's AGENTS.md, "Tickets").
4. **Open PRs.** Every PR worked on that is still open needs a `prs/<repo>-<number>.md` note. Check each code repository in `vault.json`: `gh pr list --repo <owner/repo> --author @me --state open`.
5. **Journal block.** Append to `journal/<today>.md` (from `templates/daily.md` if missing); never rewrite an earlier block. Heading `## ~HH:MM — <topic> (<source>)`, then the session line (`session: claude $CLAUDE_CODE_SESSION_ID`; Codex: see the vault's AGENTS.md), then what happened with a link to every note touched. End the block with a blank line, so a union merge with another machine's block keeps them apart.
6. **Commit and push.** `git -C "$VAULT" status --short`, then `git add` only the paths this session changed, `git commit -m "journal: <summary>"`, `git pull --rebase`, `git push`. Never `git add -A`, never force-push, never absorb, reset or stash another session's changes; if some exist, leave them and say so.
7. **Prove it.** `git -C "$VAULT" status -sb` shows nothing ahead of `origin`, and the changed text reads back as written. A push that failed is not a writeback: report it.

Two sessions on one machine share one clone: reread a note right before editing it. If git reports `index.lock`, wait a few seconds and retry; never delete the lock.

## Rules

- No secrets in the vault, ever: name where a credential lives, never its value. The vault repo stays private.
- The journal records what happened; state notes record what is true now.
- One fact, one home: state it in the owning note and link to it.
- Never mark another agent's follow-up done unless you did it and verified it.

## The Stop hook

`hooks/vault-review-stop.sh` (in this skill's folder) blocks a Claude Code session's first stop once and asks it to run section 3. `vault-workspace-setup` registers it in the workspace's `.claude/settings.local.json`, so it fires only in that workspace. OMP and Codex have no such hook: run section 3 yourself before you finish.
