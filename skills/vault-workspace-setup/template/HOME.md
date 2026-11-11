---
type: meta
status: active
updated: 2026-08-03
source: claude
---

# Work dashboard

New session or new AI? **Read [[AGENTS]] first** — it's the contract for using this vault.

## Active + blocked projects

![[bases/projects.base]]

## PRs being tracked

![[bases/prs.base]]

Full open-PR list lives on GitHub (`gh pr list --author @me`). Any PR still open at the end of a session that touched it gets a note here (open at session end = cross-session state); same-session open-and-merged PRs stay journal-only.

## Open tickets

![[bases/tickets.base]]

Planned work from project specs, one row per open ticket; see "Tickets" in [[AGENTS]].

## Pending deployments / apply sequences

![[bases/deployments.base]]

## Review queue — stalest facts first

Oldest `verified:` dates float to the top. Spare capacity? Re-verify the top item against its primary source and bump the date. See "Keeping the vault accurate" in [[AGENTS]].

![[bases/review-queue.base]]

## All open follow-ups (vault-wide)

```query
task-todo:"" -path:templates -path:skills -path:AGENTS -path:tickets
```

## Recent journal

- (links to recent `journal/` notes go here)

*(If the Bases views above ever render oddly after an Obsidian update, open the `.base` files in `bases/` via the Bases UI and re-save — the data in the notes is the source of truth, views are disposable.)*
