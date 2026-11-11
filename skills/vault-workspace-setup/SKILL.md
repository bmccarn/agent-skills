---
name: vault-workspace-setup
description: "Use when the user wants a new project workspace with its own project vault (e.g. acme/acme + acme/acme-vault, vault repo vault-acme), to check that a project has no vault yet, to wire a new checkout or worktree into a workspace, or to share a vault with someone who does not have these skills."
---

# Project workspace setup

A workspace is `<root>/<ws>/`, where `<root>` is this machine's projects root (`python3 ../project-vault/scripts/vault-find.py --settings`; `~/development` unless `~/.config/project-vault.json` sets another `root`):

```
<ws>/
  AGENTS.md          workspace rules; CLAUDE.md links to it
  .claude/settings.local.json   Claude Code Stop hook (vault review gate)
  <ws>/              main code checkout
  <other-repo>/      optional extra checkouts, named after the repo
  <ws>-vault/        the project vault: private GitHub repo vault-<ws>
```

Code and vault never share a repo: the vault is private and holds journals and state, the code repo holds what teammates need. The vault's skills (`project-vault`, `vault-sweep`) and its Stop hook script are user-level skills, not files in the vault, so one copy serves every vault. The vault template is `template/` in this skill's folder; change the template there, never by hand in a new vault.

## 1. Inputs

- `WS`: lowercase workspace name.
- `REPO`: the main checkout's `owner/repo`. If the user names none, check `gh repo view <owner>/$WS` (`<owner>` from `vault-find.py --settings`); use it if it exists and say so, otherwise leave it empty and the script makes a local repo with no remote.
- `EXTRA`: other `owner/repo` checkouts, space-separated, or none.

## 2. Check for an existing vault

```bash
bash scripts/new-workspace.sh "$WS" --repo "$REPO" --extra "$EXTRA" --check-only
```

It stops (exit 3) when the workspace folder exists, when the vault list (`vault-find.py --list`: GitHub repos with the topic `vault`, plus overrides) already has a vault named `$WS` or one tracking any of the repos, when `vault-$WS` exists on GitHub, or when a vault folder on this machine mentions the name. If the user works on other machines, check those too, read-only, since stale copies can live there:

```bash
for h in <ssh-host> <ssh-host>; do
  timeout 60 ssh -o BatchMode=yes -o ConnectTimeout=8 "$h" 'bash -s' < scripts/find-local-vaults.sh | grep -i -- "$WS"
done
```

Any hit: stop and show the user what was found. They decide whether it is the vault; never create a second one beside it.

## 3. Create

```bash
bash scripts/new-workspace.sh "$WS" --repo "$REPO" --extra "$EXTRA"
```

It reruns the duplicate check, then clones the checkouts, copies the template, writes `vault.json` (name and repositories, which `vault-find.py`, `vault-sweep` and `scope` read), arms the commit guard, makes the first commit, creates the private GitHub repo `<owner>/vault-$WS` with the topics `vault`, `obsidian` and `work-journal` and pushes, writes the workspace `AGENTS.md` and the Stop hook settings, links those settings into each checkout (hidden through `.git/info/exclude`), and registers the vault in Obsidian unless Obsidian is running. It ends with self-checks; report each PASS or FAIL line. A `manual:` line is a step for the user.

Then confirm the skills load: from `<root>/$WS/$WS`, `claude -p 'Is a skill named project-vault available to you? Answer YES or NO.' --settings '{"disableAllHooks":true}'`. Keep the hooks disabled, or the gate makes the probe write to the vault.

## Another machine

Nothing to set up: the first session there runs `vault-find.py "$WS" --clone`, which clones the vault into the same layout and arms the commit guard. Clone the code checkouts beside it and copy the workspace `AGENTS.md`, `CLAUDE.md` link and `.claude/settings.local.json` from the layout above (they are not in any repo).

## Add a checkout or worktree later

From the workspace: link `.claude/settings.local.json` into the new checkout (`mkdir -p <c>/.claude && ln -s ../../.claude/settings.local.json <c>/.claude/settings.local.json`) and add `/.claude/settings.local.json` to its `info/exclude`. A new repository also goes into the vault's `vault.json` and the `Repos:` line of the workspace `AGENTS.md`; commit and push the vault.

## Share a vault with someone who does not have these skills

`bash scripts/make-kit.sh <vault>` copies `project-vault` and `vault-sweep` (with the Stop hook) into `<vault>/skills/` with install steps in `skills/README.md`, and leaves it uncommitted for review. The copies are generated: rerun the script after the skills change, never edit them in the vault. Your own sessions keep using the installed skills.

Give them access to the private repo (`gh repo edit` or an invitation); everything in the vault becomes readable to them, so check it for anything personal first.
