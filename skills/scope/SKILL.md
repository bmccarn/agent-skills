---
name: scope
description: "Use when the user says \"scope\" a project, feature or idea: grill them to a shared plan, write the spec, have another model review it, and publish tickets to the project's tracker, ready for tee-up."
---

# scope

Turn an idea into an agreed spec and a set of tickets in the project's tracker, then stop. tee-up is the next step: each ticket should be something tee-up can build and prove on its own. The user is in the loop throughout; scope plans and never implements.

Three vendored skills do the work: `grilling`, `to-spec` and `to-tickets`. Read each one's SKILL.md from your skills folder at the step that names it and follow it, with the overrides listed in that step. Where an override and the vendored skill disagree, the override wins. The global AGENTS.md rules apply ("Public text" for anything published).

## 1. Find the tracker

Work out where this project's spec and tickets live. Take the first rule that matches:

1. The project names its own tracker: `docs/agents/issue-tracker.md`, or an issue-tracker line in the repo's AGENTS.md or CLAUDE.md. Use it as written.
2. The repo or workspace has a project vault (the `project-vault` skill finds it: walk up from the repo, or `vault-find.py <owner/repo>`): the project vault.
3. The repo has a GitHub remote: GitHub Issues in that repo.
4. None of these: ask the user where tickets go. If they describe a new tracker, offer to save their description as the repo's `docs/agents/issue-tracker.md` so rule 1 finds it next time.

The user's words override the rules ("put this in GitHub", "local files"). Read the tracker's notes in [references/trackers.md](references/trackers.md).

Done when you can say, in one line, the tracker and the rule that chose it ("acme vault, because vault-acme tracks your-org/acme"). Say it to the user before grilling starts, so they can redirect it.

## 2. Grill

Read `grilling` and follow it. Before the first round, read the code, the repo's AGENTS.md, and for a vault project the vault's project note if one exists, so questions are about decisions, not facts.

Done when grilling's own end condition holds and the user has confirmed the shared understanding.

## 3. Write the spec

Read `to-spec` and follow it, with these overrides:

- The spec goes where the tracker notes say a spec goes, but it is published in step 5, together with the tickets. This replaces "publish it to the project issue tracker".
- Apply no labels you did not find in the tracker. `ready-for-agent` and `/setup-matt-pocock-skills` do not apply here.
- User stories cover the behavior the user agreed to and its edge cases. Leave out stories for anything not agreed; an extensive list is not a goal.
- Add an `## Acceptance criteria` section (observable pass/fail outcomes) and an `## Open questions` section (anything unresolved, marked as blocking or not).

Hold the spec as a draft until step 4 finishes. Done when the draft covers every decision from the grilling and nothing beyond it.

## 4. Cross-model review of the spec

One read-only review by a model from a different family than the one writing the spec. One round only; a second round is not needed because the user settles what remains.

- OMP and Claude Code (Opus wrote it): Sol. OMP: the `sol` agent. Claude Code: from the repo root, `codex exec -s read-only -o <tmp>/scope-review.txt "<brief>" < /dev/null`, run in the background, and wait for it to exit. Keep `< /dev/null`: with stdin open, codex waits for input forever.
- Codex (Sol wrote it): Claude Opus, from the repo root: `claude -p "<brief>" --model opus --tools "Read,Grep,Glob" --strict-mcp-config < /dev/null`. The brief goes first because `--tools` would take it as a tool name. The tool list plus `--strict-mcp-config` (no MCP servers) keep it read-only.

Save the draft spec and the decision list from the grilling to a file in a scratch folder first and name the paths in the brief:

```
Review only. Do not edit files, commit, or publish anything.
Repo: <abs path>. Draft spec: <path>. Decisions agreed with the user: <path>.
Check the spec against the decisions and the code:
- a decision the spec contradicts, drops or changes
- an acceptance criterion that cannot be checked, or a behavior with none
- something the plan needs that nobody decided (a gap)
- scope the decisions do not ask for
Reply with one line per finding: F1 [gap|contradiction|untestable|scope] <claim>, citing the spec section.
End with VERDICT: READY or CHANGES.
```

Fix wording, untestable criteria and scope findings yourself. Put every gap or contradiction that needs a decision to the user as one more grilling round. If the review does not run (no route, timeout), say so and go on; it is not a pass.

Done when every finding is fixed, decided by the user or declined with a reason. Nothing is published yet.

## 5. Cut tickets

Read `to-tickets` and follow it, with these overrides:

- A slice crosses only the layers its behavior needs.
- Prefactoring becomes its own ticket only when a ticket cannot be built without it; it blocks only the tickets that need it.
- Every ticket's acceptance criteria are observable and specific enough for tee-up to write a failing test or check from them before building.
- Publish to the tracker as the tracker notes say. On GitHub, use native sub-issues and blocking links when the repo supports them, else the parent reference and "Blocked by" sections, and existing labels only. This replaces the `/setup-matt-pocock-skills` configuration.
- Run `unslop` on ticket titles and bodies before publishing to any tracker other people read.

Show the final spec (its text, or the path of the draft) with the proposed breakdown, so that one approval covers both. Publish nothing until the user approves the breakdown (to-tickets' quiz step). Then publish the spec first and the tickets after it, and read every published item back to confirm its text and links.

## 6. Report

The tracker and why, the spec location, the cross-model review (findings fixed, decided, declined; or that it did not run), the tickets in dependency order with their links, which ones can start now (for example "tee up <ticket>"), and the open questions left. Claim only what you read back.
