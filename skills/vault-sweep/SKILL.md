---
name: vault-sweep
description: "Use when asked to \"run a vault sweep\", \"sync the vault\", or check whether a project vault (Obsidian work journal) is accurate, or when its review queue shows verified dates older than about two weeks. Reconciles notes against primary sources (PR state via gh; ticket, infra and cloud claims flagged for spot checks), closes finished work with evidence, bumps verified dates and journals the sweep."
---

# Vault sweep: reconcile the journal against reality

The vault is the canonical cross-session journal; its `AGENTS.md` is the contract, and this sweep follows its "Keeping the vault accurate" section. Read that first if you haven't this session.

## 0. Find the vault and its repos

Find the vault and pull it as the `project-vault` skill says (sections 1 and 2). The code repositories it tracks are in `$VAULT/vault.json`:

```bash
jq -r '.repositories[]' "$VAULT/vault.json"
```

If that list is empty or missing, use the `Repos:` line of the workspace's `AGENTS.md`, and say in the sweep's journal block that `vault.json` needs its repositories filled in.

## 1. Snapshot reality (read-only)

```bash
for r in $(jq -r '.repositories[]' "$VAULT/vault.json"); do
  gh pr list --repo "$r" --author @me --state all --limit 40 \
    --json number,title,state,isDraft,mergedAt,headRefName,url
done
```

## 2. Reconcile `prs/` notes

For each note with `type: pr` and a status other than done or dropped:

- Merged: status `done`, `closed:` the merge date, an `## Outcome` line with the merge SHA and date. If a deploy or apply step remains, move that follow-up to the owning project note before closing.
- Closed unmerged: status `dropped` with an outcome line.
- Still open: confirm the note's draft or ready state matches; bump `verified:`.
- Coverage, the reverse direction: every open PR in the snapshot needs a `prs/<repo>-<number>.md` note. Create any missing one (a thin companion if a project note anchors it) and flag it in the journal block as a miss.

## 3. Reconcile `tickets/`

For each ticket whose status is not `done` or `dropped` (planned work and tasks alike):

- **Close gate.** Report a ticket as ready to close only when primary sources (gh, TFC, AWS, logs) show every item under `## Acceptance criteria` met. A merged `pr:` is necessary for a PR ticket but not sufficient: merged is not applied is not verified. For a ticket without `pr:`, check its criteria directly (an apply that already ran, a decision recorded). Check off criteria you confirmed, and say which are met with what evidence and which are not. The user closes tickets: never set `done` yourself. A `pr:` closed unmerged: flag it.
- **Start gate.** Report a ticket as ready to start only when every `blocked-by:` ticket is `done` and, for `status: blocked`, its `blocked-on:` condition is confirmed cleared at the primary source. Blockers done but `blocked-on:` still true: report it as still blocked and name the outside blocker.
- **Links.** The ticket is listed under its `project:` note's `## Tickets`; add a missing link. A `blocked-by:` entry that names no existing ticket: flag it.
- Tickets carry no `verified:`; never add one.

The sweep's journal block lists the tickets ready to close (with evidence), ready to start, and still blocked.

## 4. Reconcile `projects/` notes

For each active or blocked project:

- Check every PR number mentioned against the snapshot and fix stale references.
- Verify `blocked-on:` claims that `gh` can check. For ticket-tracker, infrastructure and cloud claims, spot-check the primary source if it takes one CLI or MCP call; otherwise tag the claim `(unverified, as of <today>)` and leave it in the review queue.
- Bump `verified:` only on notes whose claims you confirmed.

## 5. Review-queue pass

Take the two or three stalest entries in HOME's review queue (oldest `verified:`, never-verified first) and verify or correct them.

## 6. Corrections

Fix anything wrong in place, following the vault's correction protocol: a dated `> [!warning] Corrected` callout when the error could recur or has copies elsewhere.

## 7. Journal, commit, push

Append a sweep block to today's journal, with the date and `~HH:MM` heading measured with `date`: what was checked, what changed, what could not be verified, and the ticket lists from step 3. Then commit only the paths the sweep changed and push, as in the `project-vault` skill's section 3, step 6, with the message `sweep: <summary>`.

## Rules

- Never mark something done without primary-source evidence (merge SHA, apply timestamp).
- Merged is not deployed: closing a PR note must not drop a pending apply or release.
- Don't create project notes during a sweep; flag the gaps in the journal block. Missing `prs/` notes are the one exception (step 2).
- A sweep that changes nothing still writes its journal block ("swept, all current") and bumps `verified:` on what it confirmed.
