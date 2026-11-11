# Upgrade a vault made from the August 2026 starter

Before this repo existed, the vault template went out as a zip named `vault-starter.zip`. This page is for a vault made from that zip. For a new vault, follow [VAULT.md](../VAULT.md).

## What changed since the August starter

- **Tickets.** The vault has a `tickets/` folder, a ticket template, a tickets view on `HOME.md` and a "Tickets" section in `AGENTS.md`. A ticket has a status, acceptance criteria and blockers. The project template has a `## Tickets` list.
- **One skill for the session.** `project-vault` replaces `vault-session-end`. It finds the vault, reads it at session start and writes it at session end. `vault-sweep` now checks tickets too.
- **The skills live outside the vault.** They install once for each machine in `~/.claude/skills/`, so several vaults share one copy. The vault keeps only the commit guard.
- **The Stop hook uses `jq`.** The earlier hook piped its input to an inline Python command. Endpoint security tools such as CrowdStrike Falcon can kill that pattern, and the hook then fails without output.
- **Safer with two machines or two sessions.** A session pulls before it reads. At the end it commits only the paths it changed, pulls, then pushes. `.gitattributes` merges two machines' journal blocks for the same day.
- **`vault.json`.** The file names the vault and the repositories whose pull requests the skills check.

## Upgrade the vault

Your notes stay as they are. The steps add the ticket files, replace the contract and move the tooling out of the vault.

1. Set the paths, and start from a clean vault. If `git status` lists changes, commit them first.

   ```bash
   KIT=~/src/agent-skills                           # your clone of this repo
   T="$KIT/skills/vault-workspace-setup/template"   # the blank vault
   V=~/path/to/your-vault                           # your existing vault
   cd "$V" && git status --short
   ```

2. Add the ticket files and the new settings files.

   ```bash
   mkdir -p tickets && touch tickets/.gitkeep
   cp "$T/templates/ticket.md" "$T/templates/project.md" templates/
   cp "$T/bases/tickets.base" "$T/bases/review-queue.base" bases/
   cp "$T/.gitattributes" "$T/vault.json" .
   ```

3. Edit `vault.json`. Set `name` to the vault name, and list the repositories whose pull requests the skills check.

4. Replace the contract. If you edited your `AGENTS.md`, run `git diff AGENTS.md` after the copy and put your edits back.

   ```bash
   cp "$T/AGENTS.md" AGENTS.md
   ```

5. Edit `HOME.md` by hand, so that your own additions stay. Add this section after "PRs being tracked":

   ```markdown
   ## Open tickets

   ![[bases/tickets.base]]

   Planned work from project specs, one row per open ticket; see "Tickets" in [[AGENTS]].
   ```

   In the same file, add `-path:tickets` to the end of the follow-ups query:

   ```
   task-todo:"" -path:templates -path:skills -path:AGENTS -path:tickets
   ```

6. Remove the old tooling from the vault, and remove the old skill links from your workspace.

   ```bash
   git rm -rq skills hooks
   rm -f /path/to/your-workspace/.claude/skills/vault-sweep \
         /path/to/your-workspace/.claude/skills/vault-session-end
   ```

7. Install the new skills (step 7 of [VAULT.md](../VAULT.md)).

8. Open `~/.claude/settings.json`. Delete the Stop hook entry whose command points at `hooks/vault-review-stop.sh` inside your vault. Then register the new hook (step 8 of [VAULT.md](../VAULT.md)).

9. Commit, then run the checks in [VAULT.md](../VAULT.md).

   ```bash
   git add -A && git commit -m "vault: tickets, contract and tooling from the 2026-11 template"
   ```
