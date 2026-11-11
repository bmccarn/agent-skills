---
type: meta
status: active
updated: 2026-11-03
source: claude
---

# Vault contract — read this before writing anything

This vault is the **canonical cross-session journal** for your work. It is read and written by you and by AI agents (Claude Code, Codex, others). Its value depends on every writer following the same small set of rules. If you are an AI session touching this work, this file is your instruction set.

## TL;DR protocol

**At session start** (any working session):
1. Run `date '+%Y-%m-%d %H:%M'` — this, not your context's assumed date, defines "today". It tells you which `journal/` note is current and whether a new day's note needs creating (see "Timestamps are measured, never estimated" below).
2. If the vault has a remote, `git pull --rebase` — another machine may have written since your last read.
3. Read `HOME.md` — the dashboard of active/blocked work.
4. Read today's and yesterday's notes in `journal/` if they exist ("today" per step 1).
5. Open the `projects/`, `prs/` or `tickets/` note for whatever you're working on.

**At session end** (or after completing meaningful work):
1. Append a session block to today's `journal/YYYY-MM-DD.md` — the date and block time both come from running `date` at write time; create the note from `templates/daily.md` if it doesn't exist yet.
2. Update `status`, `updated`, and `## Follow-ups` in every project/PR note you touched.
3. Create notes for new workstreams/PRs/gotchas discovered (use `templates/`). **Bright line for PRs:** any PR you worked on that is still open when the session ends gets a `prs/<repo>-<number>.md` note (a thin companion pointing at its project-note anchor if one exists — see "Multi-repo PR sets"). PRs opened and merged within the session need journal mention only. Check with `gh pr list --author <your-gh-handle>`.
4. Commit only the paths this session changed (`git add <paths> && git commit -m "journal: <one-line summary>"`) — another session may have uncommitted edits in the same vault. If the vault has a remote, `git pull --rebase && git push` — a bare push gets rejected once another machine has moved. The `project-vault` skill is the checklist for all four steps.

**Unsure where something goes?** Put it in `inbox/` with at minimum a `type: note` + `source:` frontmatter stub. A later session will triage it. Never let uncertainty stop you from capturing.

## Folder map

| Folder | Contains | One note per |
|---|---|---|
| `journal/` | Daily session logs, append-only | day (`YYYY-MM-DD.md`) |
| `projects/` | Workstream dossiers — goals, state, decisions, follow-ups | workstream |
| `prs/` | PR tracking beyond a one-liner — review findings, blockers, merge/apply state | PR (`<repo>-<number>.md`) |
| `deployments/` | Ordered apply/deploy sequences with gates and checkboxes | rollout |
| `tickets/` | Planned work and tracked tasks, each with acceptance criteria and blockers (see "Tickets") | ticket (`<project>-NN-<slug>.md`) |
| `notes/` | Evergreen nuances, gotchas, reference facts | topic |
| `inbox/` | Untriaged dumps (other-AI output, quick captures) | whatever |
| `templates/` | Note skeletons — copy structure when creating notes | — |
| `bases/` | Obsidian Bases view definitions used by HOME.md — do not edit | — |
| `attachments/` | Images, exports, artifacts | — |

**Multi-repo PR sets.** When one logical change spans PRs in several repos, anchor the set at the **base PR** (the one that must land/apply first): its `prs/<repo>-<number>.md` note owns everything shared — cross-PR findings, set-wide verdict, merge/apply sequencing (or a link to the `deployments/` note that owns it). Every companion PR still gets its own `prs/` note, so the HOME dashboard shows one row per open PR, but it carries **only** that PR's specific state (head SHA, checks, its own fix list) plus pointers to the anchor — shared facts are never copied into companion notes (see "One fact, one home"). Companions blocked by the base are `status: blocked` with `blocked-on:` naming the anchor; when the set resolves, close all notes in the set. Anchor and companions must link each other.

## Frontmatter schema

Every note starts with YAML frontmatter. Required on all notes:

```yaml
type: project | pr | deployment | ticket | note | daily | meta
status: active | blocked | parked | done | dropped
updated: YYYY-MM-DD        # bump every time you meaningfully edit the note
source: claude | codex | human | other
```

Optional, used where relevant (the Bases dashboards read these — use these exact key names):

```yaml
verified: YYYY-MM-DD       # last date these claims were checked against primary
                           #   sources — see "Keeping the vault accurate". The
                           #   review-queue dashboard sorts on it; a note without
                           #   one sorts to the top as never-verified.
jira: ABC-12345            # linked ticket
repo: <repo-name>          # for type: pr, and type: ticket once a PR exists
pr: 253                    # for type: pr, and type: ticket once a PR exists
blocked-on: <short reason> # required when status: blocked
closed: YYYY-MM-DD         # required when status: done or dropped
project: "[[<project-note>]]"  # for type: ticket — the project it belongs to
blocked-by: ["[[<ticket>]]"]   # for type: ticket — tickets that must be done first
```

`meta` is for the vault's own infrastructure — `AGENTS.md` and `HOME.md`. They are not claim sets, so they carry `updated:` but never `verified:`, and the review queue excludes them by type rather than by filename.

## Status lifecycle

```
active ──▶ blocked ──▶ active
   │          │
   ▼          ▼
 parked ──▶ done | dropped
```

- `active` — being worked, or next in line.
- `blocked` — cannot proceed; `blocked-on:` must say why (a person, a TFC apply, an upstream PR).
- `parked` — deliberately shelved, no blocker; will resume someday.
- `done` — completed and verified. `dropped` — abandoned, won't do.

**Closing out = changing `status` and setting `closed:`. Never delete or move a note to close it.** Dashboards filter closed items out of view; the note stays linkable and searchable forever. Add a final `## Outcome` section saying how it ended.

## Follow-ups

Every actionable item is a checkbox under a `## Follow-ups` heading **in the note that owns it** (the project/PR it belongs to — not the journal, not a global list). HOME.md rolls up every unchecked box vault-wide automatically. An item that needs its own blockers, acceptance criteria or PR becomes a ticket instead (see "Tickets").

```markdown
## Follow-ups
- [ ] re-apply the staging Terraform after the CI revert (owner: claude)
- [x] update PR body after harness removal ✅ 2026-07-14
```

- Completing one = check the box (append a date if useful). Don't delete it.
- If a follow-up came up in a journal entry, put the checkbox in the owning note and link it from the journal.
- A follow-up with no owning note yet → create the note, or park the checkbox in an `inbox/` stub.

## Tickets

A ticket is a piece of work tracked on its own, with a status, blockers and acceptance criteria. Two kinds share one format:

- **Planned work** cut from a project's spec by the `scope` skill; `tee-up` builds one into a PR. The spec lives in the project note under `## Spec`; tickets link it through `project:` and never repeat it (see "One fact, one home").
- **Tasks and to-dos**: a follow-up big enough to track on its own, such as a verification, an apply, a decision or a cleanup, with or without a PR. It needs no spec: the ticket says what done looks like and links its context.

**Ticket or follow-up?** A checkbox under `## Follow-ups` in the owning note is enough for a small next step. Make a ticket when the item needs its own blockers, acceptance criteria, PR or status. When a ticket takes over a follow-up, replace the checkbox with a plain `Ticket [[<ticket>]]` line, so the item lives in one place.

- One note per ticket in `tickets/`, created from `templates/ticket.md` and named `<project>-NN-<slug>.md`, numbered from 01 within a project (in dependency order for planned work). The project note lists its tickets under `## Tickets`.
- **Acceptance criteria are checkboxes under `## Acceptance criteria`.** They define done; they are not follow-ups, so HOME's follow-ups rollup skips `tickets/`. Put a follow-up you find while working a ticket in the project note. Check a criterion only with evidence from a primary source.
- **Status:** `active` while open; ordering between tickets lives in `blocked-by:`, not in status. `blocked` only for an outside blocker, with `blocked-on:` as for any note; such a ticket cannot start until that condition is cleared, even when its `blocked-by:` tickets are done. `done` only when primary sources show every acceptance criterion met (a merged PR alone is not enough when a criterion needs an apply, deploy or check), with an `## Outcome` citing the evidence; `dropped` with a reason.
- **Your human closes tickets.** Agents report which tickets are ready to close and why, and never flip one to `done` themselves.
- When `tee-up` opens a PR for a ticket it sets `repo:` and `pr:`.
- Tickets are plans, not claims about the world, so they carry no `verified:` and stay out of the review queue.

## Journal convention

One file per day. Each session appends a block — never rewrite earlier blocks:

```markdown
## ~09:30 — <topic> (<source>)
What happened, decisions made, and why. Link every note touched: [[<pr-note>]], [[<project-note>]].
New follow-ups were added to: [[<note>]].
```

The journal records *what happened*; project/PR notes record *current state*. Don't make future readers reconstruct state from journal archaeology — update the state notes.

**Timestamps are measured, never estimated.** AI agents have no reliable clock — context clues (hook output, file mtimes, session start) are stale by write time and estimated headings have been wrong. Immediately before appending a block, run:

```bash
date '+%H:%M'
```

and use that value in the `## ~HH:MM` heading. Same rule for any other time-of-day you write anywhere in the vault. (Dates too, if there is any doubt which day it is: `date '+%Y-%m-%d'` — a session that crosses midnight appends to the *new* day's note.)

## Session IDs and the `## Log` convention

Project, PR, and deployment notes carry a `## Log` section: a short list of **milestone** entries only — the sessions that actually moved the work. Day-to-day detail belongs in `journal/`, which is the exhaustive index. If you're unsure whether something is a Log entry, it probably isn't.

Stamp the agent session that produced the work onto both, so a note can be resumed live while it's fresh or read as archaeology when it's cold.

**Every journal block** gets one line under its heading, backticked so Obsidian renders it inert:

```markdown
## ~09:56 — <topic> (claude)
`session: claude 1b2c3d4e-5f60-4a7b-8c9d-0e1f2a3b4c5d`
```

A topic worked by two agents at once (a Claude pane plus a Codex pane) gets one line each.

**`## Log` lines** carry the same ID inline, keeping the `— <what happened>` boundary:

```markdown
- 2026-01-16 · claude `1b2c3d4e-...` — dashboard name doubling found post-deploy; rename PR opened.
- 2026-01-24 · codex `0a1b2c3d-...` — apply retry after access logs disabled.
```

**Getting the IDs:**

```bash
echo $CLAUDE_CODE_SESSION_ID          # Claude: its own ID, always set in the environment

# Codex: rollouts record their own `cwd`, so a pane's session resolves by directory.
# Point WORK at the workspace root you were working in.
WORK="$HOME/path/to/your/workspace"
grep -l "\"cwd\": *\"$WORK" ~/.codex/sessions/*/*/*/rollout-*.jsonl 2>/dev/null \
  | sort | tail -3 | sed -E 's|.*/rollout-([0-9T:-]{19})-(.*)\.jsonl|\1  \2|'
```

Output is `<start-time>  <uuid>`, oldest first — match the pane you want by its start time.

**Resuming:** `claude --resume <uuid>` · `codex resume <uuid>`

**Never rewrite a stamped line.** Both the journal block and the `## Log` line are append-only; that is the only reason the same UUID may safely appear in both places. Editing one in place reintroduces drift.

> [!warning] Claude transcripts are pruned after 30 days by default
> `cleanupPeriodDays` in `~/.claude/settings.json` defaults to **30**, and the pruner
> really runs. A session ID written into this vault — a permanent git repo — becomes a
> dead pointer about a month later, and it fails in the worst way: the note still
> *looks* like it carries provenance. Raise the setting (365 costs roughly 17 MB/day)
> if you want stamped IDs to stay resolvable, and treat **any plan that assumes an old
> Claude session can be resumed as wrong by default**. Codex rollouts are never pruned.
> Expiry is readable from the date on the line, so no separate liveness marker is needed.

Adopting this later is additive — existing ID-less Log lines stay valid, and nothing gets backfilled (matching old journal blocks to surviving transcripts is guesswork).

## Naming and linking

- Filenames: kebab-case, descriptive, stable — they are link targets. `prs/` uses `<repo>-<number>.md`. No dates in filenames except `journal/`.
- Link liberally with `[[wiki-links]]`. Links resolve by filename anywhere in the vault, so renaming/moving breaks nothing inside Obsidian — but prefer not to rename once created.
- When referencing code, use full repo-relative paths with the repo named: `<repo>: path/to/file.ts:42`.

## Rules for non-Claude AIs (Codex, ChatGPT dumps, etc.)

- Write new material to `inbox/` unless you are confident about the destination folder and schema.
- Always include the frontmatter stub (`type`, `status`, `updated`, `source`).
- Never edit `bases/`, `templates/`, `AGENTS.md`, or `HOME.md`.
- Never mark another agent's follow-up as done unless you actually did it and verified it.

## Content rules

- **No secrets**: no tokens, passwords, private keys, webhook capability URLs, or credential material — ever. Reference where a secret lives (e.g. "token at ~/.config/acme/token"), never its value.
- Internal account IDs, hostnames, and Jira keys are fine — this vault and its remote are private. Never make the remote public or copy vault text into a public repo.
- Dates: always absolute (`2026-07-14`), never "yesterday"/"last week".
- Be specific about uncertainty: "PR #250 believed merge-ready, unverified since 2026-07-13" beats silent staleness.

## Keeping the vault accurate

The vault is the **map, not the territory**. GitHub, TFC, AWS, and Jira are the territory. These rules keep the map trustworthy:

**`verified:` vs `updated:`.** `updated` is the last time anyone edited the note. `verified` is the last date the note's factual claims were checked against primary sources. Add `verified: YYYY-MM-DD` to project/pr/deployment/note frontmatter and bump it **only** when you actually confirmed the facts (ran `gh`, checked TFC, queried AWS) — not when you merely edited prose.

**Provenance tagging.** A claim you confirmed from a primary source can be stated plainly. A claim from memory, inference, or another note must be tagged inline: `(unverified, as of 2026-07-14)`. Never launder recall into fact by writing it confidently.

**Verify before acting.** Before doing anything consequential based on vault state — merging, applying, closing a note, reporting status to your human — re-check the primary source first. Then bump `verified:`. The vault tells you where to look; it does not replace looking.

**Review queue.** HOME.md has a "review queue" view sorted oldest-verified-first. When a session has spare capacity, pick the top item, re-verify it, and bump or correct it. Notes that are `parked` still rot — they're in the queue too.

**Sweeps.** The `vault-sweep` skill reconciles the vault against reality: PR/branch states via `gh` (automatic), everything else flagged for spot-checking. Run it when asked, or suggest it when the review queue's top entries are more than ~2 weeks old. See "Skills and hooks" below for wiring it up.

**Corrections.** When something in a note proves wrong: fix the state text in place, and if the error had downstream copies or could recur, add a dated callout so the wrong version can't come back:

```markdown
> [!warning] Corrected 2026-07-15
> Previously claimed X. Actually Y — the earlier claim came from <source of error>.
```

Log the correction in the journal. Journal entries themselves are never rewritten — corrections there are new entries.

**One fact, one home.** State each fact in exactly one note and link to it from everywhere else. Copies drift; links don't.

**Never write `#N/#M` for PR pairs.** Obsidian parses `#246/` as a valid nested tag (the slash supplies the required non-numeric character) and renders a misleading clickable tag pill; bare `#246` is safely plain text, because purely numeric tags are invalid. Write `#246 / #247`, `#246 and #247`, or link the PR note (`[[<repo>-246]]`) when a click-through is actually wanted. Same trap for `#N/<sha>` — write `#113, e08be5d`. **Machine-enforced:** `.githooks/pre-commit` rejects the pattern (outside code spans and URLs) at commit time. It is not active until you arm it — after `git init` or a fresh clone, run `git config core.hooksPath .githooks`.

**Close-out requires evidence.** Flipping a note to `done` requires an `## Outcome` line citing the proof: merge SHA, apply date, alarm-fired timestamp — something a future reader can re-check.

## Skills and hooks

The agent tooling for this vault is not stored in it:

- `project-vault` (find the vault, session start and session-end ritual), `vault-sweep` (reconcile against reality, tickets included) and the `vault-review-stop.sh` Stop hook (asks a Claude Code session once, at its first stop, whether anything needs writing back) come from your agent's skill set. Install them once per machine as user-level skills, for example in `~/.claude/skills/`.
- `.githooks/pre-commit` is the one hook kept here, because it guards this repo's commits. Arm it after every `git init` or clone: `git config core.hooksPath .githooks`.

Keeping tooling outside the vault means one copy per skill instead of one per vault; a fix lands everywhere at once. Two cautions for anyone writing tooling for this vault:

- **Never hardcode an absolute path.** Find the vault by walking up from `$PWD` to the nearest folder that is, or contains, a folder with `AGENTS.md`, `HOME.md` and `bases/`. That works from the workspace root, a checkout, a worktree, or inside the vault, on any machine. A hardcoded root doesn't error: the guard never matches and the gate never fires. **A broken gate looks exactly like a satisfied one**, so verify by running it.
- **Link a skill's directory, not its `SKILL.md`.** Claude Code discovers a skill through a linked directory but not through a real directory holding a linked `SKILL.md` (verified 2026-08-03), and it gives no error.

## Relationship to other stores

| Store | Role | Rule |
|---|---|---|
| **This vault** | Canonical journal: project state, PRs, follow-ups, session history | Everything cross-session lands here first |
| Agent auto-memory (e.g. `~/.claude/projects/.../memory/`) | Durable user preferences, feedback rules, small reference facts | No project state; points here for that |
| Team-shared repo/wiki (if any) | **Team-shared** memory (PR review context, handoffs) | Copy things there deliberately; nothing syncs automatically. Team-shared content rules apply (generic incident descriptions, nothing personal) |
| Repo `docs/`, CLAUDE.md files | Code-adjacent, committed docs | Anything a teammate needs belongs there, not here |

## Git

The vault is a git repo with a private remote, named `vault-<name>` with the topics `vault`, `obsidian` and `work-journal` so `gh repo list --topic vault` finds every vault. Each machine works in its own clone: pull before reading (session start), commit and push after writing (session end).

`.gitattributes` merges `journal/*.md` with git's union driver, so two machines appending blocks to the same day keep both. Any other conflict is resolved by hand: keep both writers' facts, and never force-push. Commit at session end with `journal: <summary>` or a more specific message. History is the audit trail of who wrote what — don't squash or rewrite it.
