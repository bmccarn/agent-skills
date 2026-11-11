---
type: deployment
status: active
updated: {{date}}
verified:
source: claude
jira:
blocked-on:
---

# <Rollout name>

What is being deployed/applied, and the blast radius. Link the project: [[<project-note>]].

## Preconditions

- [ ] gate that must be true before starting (e.g. PR merged, drift resolved, plan reviewed)

## Sequence

Ordered. Each step: the action, the workspace/environment, and how to verify before proceeding.

1. [ ] step — verify: …
2. [ ] step — verify: …

## Rollback

How to back out if a step fails, and the point of no return if one exists.

## Outcome

Filled in when status flips to done: what was applied, when, anomalies observed.

## Log

- 2026-01-01 · claude `<uuid>` — created. Milestone-level entries only; day-to-day detail goes in journal/. Append-only: never rewrite a stamped line (AGENTS.md, Session IDs).
