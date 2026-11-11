# Tracker notes for scope

Where a spec and its tickets go, per tracker. tee-up reads tickets back from the same places.

## GitHub Issues

- Spec: a parent issue titled after the feature, the spec as its body.
- Tickets: one issue each, created blockers first so later tickets can name them: `gh issue create --parent <spec#> --blocked-by <n>,<n> ...`. If that gh lacks `--parent` or `--blocked-by`, use the REST endpoints (`POST /repos/{o}/{r}/issues/{n}/sub_issues` with `sub_issue_id`, `POST /repos/{o}/{r}/issues/{n}/dependencies/blocked_by` with `issue_id`; both take the issue's numeric id, not its number) and fall back to a "Blocked by" section only if the repo refuses them.
- Labels: only ones `gh label list` shows. Create none.
- Issues are public to everyone with repo access: no private paths, vault links or secrets.

## Project vault (Obsidian)

Find the vault with the `project-vault` skill and pull it. Read the vault's `AGENTS.md` first and follow its contract (frontmatter, linking, close-out, journal). Make every write through the `project-vault` skill's session-end rules: reread before editing, commit only the paths you changed, then pull and push.

- If the vault's AGENTS.md has no `tickets/` folder in its folder map, this vault is not set up for tickets. Stop and tell the user; do not invent a layout.
- Spec: the project note `projects/<slug>.md`. For a new workstream, create it from `templates/project.md`. Put the spec under a `## Spec` heading; the note's other sections keep their usual jobs.
- Tickets: `tickets/<project-slug>-NN-<slug>.md` from `templates/ticket.md`, numbered from 01 in dependency order. Link each to the project note in `project:` and list blockers as wiki-links in `blocked-by:`. Acceptance criteria are checkboxes under `## Acceptance criteria`, which the vault keeps out of the follow-ups rollup.
- Add each ticket to the project note's `## Tickets` list, and add a journal block for the session as the contract requires.

## Local markdown (repo without a tracker, or the user asks for files)

- Spec: `.scratch/<feature-slug>/spec.md` in the target repo, unless the repo already has a planning location.
- Tickets: `.scratch/<feature-slug>/issues/NN-<slug>.md`, one per ticket, using to-tickets' local template; "Blocked by" names ticket numbers.
- Check `git check-ignore .scratch` and tell the user whether these files will be committed.

## Anything else (Linear, Jira, another vault layout)

Follow the repo's `docs/agents/issue-tracker.md` or the user's description: what "publish" means, how blocking is recorded, where the spec goes. If any of the three is missing, ask before publishing.
