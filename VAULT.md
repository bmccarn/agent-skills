# Set up a project vault by hand

A project vault is an Obsidian vault in a private git repo. Your coding agents read it when a session starts. When a session ends, they write the current state and a journal block back, then commit. The vault's `AGENTS.md` is the contract that every writer follows.

The `vault-workspace-setup` skill does every step on this page and also creates the private GitHub repo. To use it, ask your agent to "set up a workspace with a vault for acme". Follow this page to do the same by hand, or to see what the skill does.

If you have a vault made from the August 2026 starter zip, see [docs/upgrade-from-2026-08-starter.md](docs/upgrade-from-2026-08-starter.md).

## What you need

- `git` and `jq`. The Stop hook uses `jq`. Without `jq` the hook prints nothing and never fires.
- `gh`, signed in. The skills read PR state through `gh`.
- Obsidian with the core Bases plugin. The tables on `HOME.md` are Bases views.
- Claude Code, Codex or another agent that loads skills. Only Claude Code runs the Stop hook. In other agents, say "update the vault" before you finish.

## Set up a new vault

The steps assume this layout. The workspace folder holds the vault and your code checkouts, and you start your agent in it or below it.

```
~/work/acme/              the workspace
├── AGENTS.md             points agents at the vault (CLAUDE.md links to it)
├── acme-vault/           the vault: open this folder in Obsidian
└── acme/                 a code checkout
```

1. Set three variables. Use your own names.

   ```bash
   KIT=~/src/agent-skills   # your clone of this repo
   WS=~/work/acme           # the workspace folder
   NAME=acme                # the vault name
   ```

2. Copy the blank vault into the workspace and make it a git repo.

   ```bash
   mkdir -p "$WS"
   cp -R "$KIT/skills/vault-workspace-setup/template" "$WS/$NAME-vault"
   cd "$WS/$NAME-vault"
   git init -b main
   ```

3. Arm the commit guard. Run this command again in every new clone, because git does not copy the setting.

   ```bash
   git config core.hooksPath .githooks
   ```

4. Edit `vault.json`. Set `name` to the vault name, and list the repositories whose pull requests the skills check.

   ```json
   {
     "name": "acme",
     "repositories": ["your-org/acme", "your-org/acme-infra"]
   }
   ```

5. Make the first commit.

   ```bash
   git add -A && git commit -m "vault: initial"
   ```

6. Optional: push the vault to a private GitHub repo, so that a second machine can clone it. The vault holds internal names and state, so the repo must stay private.

   ```bash
   gh repo create "vault-$NAME" --private --source . --remote origin --push
   gh repo edit --add-topic vault --add-topic obsidian --add-topic work-journal
   ```

7. Install the two vault skills. If you installed every skill as the README says, you already have both and can skip this step.

   ```bash
   mkdir -p ~/.claude/skills ~/.agents/skills
   cp -R "$KIT/skills/project-vault" "$KIT/skills/vault-sweep" ~/.claude/skills/     # Claude Code
   cp -R "$KIT/skills/project-vault" "$KIT/skills/vault-sweep" ~/.agents/skills/     # Codex and OMP
   ```

8. Register the Stop hook in `~/.claude/settings.json`. This command keeps your other settings and saves the previous file as `settings.json.bak`.

   ```bash
   S=~/.claude/settings.json
   [ -s "$S" ] || echo '{}' > "$S"
   cp "$S" "$S.bak"
   jq '.hooks.Stop = ((.hooks.Stop // []) + [{hooks: [{type: "command", timeout: 15,
         statusMessage: "Vault session-end review gate",
         command: "bash \"$HOME/.claude/skills/project-vault/hooks/vault-review-stop.sh\""}]}])' \
     "$S.bak" > "$S"
   ```

   Run the command once, because a second run adds a second copy of the hook. The hook is registered for every session, and it stays silent outside a folder that holds a vault.

9. Tell agents that the vault exists. Create `AGENTS.md` in the workspace folder with this text, and replace `acme` with your vault name. If the workspace already has an `AGENTS.md` or a `CLAUDE.md`, add the section to that file instead.

   ```markdown
   # acme workspace

   ## Project vault: read this first

   `acme-vault/` is the canonical cross-session journal for this workspace. Use the `project-vault` skill at session start (pull, then read HOME.md and the journal) and at session end (write back, commit, push). The vault's own `AGENTS.md` is the contract.
   ```

   Claude Code reads `CLAUDE.md`, so link that name to the same file.

   ```bash
   ln -s AGENTS.md "$WS/CLAUDE.md"
   ```

10. Open the vault in Obsidian. Choose **Open folder as vault** and select `$WS/$NAME-vault`. Open **HOME**. You see five empty tables, which fill as you work.

## Check that it works

Run each check. A hook that is broken prints nothing, which looks the same as a hook that has nothing to say.

1. The hook asks for a review inside the workspace. Expect one line of JSON that contains `"decision":"block"`.

   ```bash
   cd "$WS" && echo '{"session_id":"probe","stop_hook_active":false}' \
     | bash ~/.claude/skills/project-vault/hooks/vault-review-stop.sh
   rm -f "${TMPDIR:-/tmp}/claude-vault-stop-probe"
   ```

2. The hook is silent outside the workspace. Expect no output.

   ```bash
   cd / && echo '{"session_id":"probe","stop_hook_active":false}' \
     | bash ~/.claude/skills/project-vault/hooks/vault-review-stop.sh
   ```

3. Claude Code loads the skills. Expect `YES`. The `--settings` flag turns the hook off for this one command.

   ```bash
   cd "$WS" && claude -p 'Is a skill named project-vault available to you? Answer YES or NO.' \
     --settings '{"disableAllHooks":true}'
   ```

4. The commit guard rejects a `#12/#13` pair. Expect the commit to fail with a `pre-commit:` message.

   ```bash
   cd "$WS/$NAME-vault"
   printf -- '---\ntype: note\n---\nPRs #12/#13\n' > inbox/probe.md
   git add inbox/probe.md && git commit -m probe
   git rm -q --cached -f inbox/probe.md && rm inbox/probe.md
   ```

## Use the vault

- Work as usual. When a Claude Code session first stops, the hook asks the session once whether the vault needs an update.
- Say "update the vault" to save progress at any time.
- Say "what is on my plate? check the vault" to get the current state.
- Say "run a vault sweep" about every two weeks. The agent checks the notes against GitHub and corrects the notes that are out of date.
- Say "make a ticket for X in the vault" to track a piece of work that needs its own acceptance criteria or blockers. The agent reports when a ticket is ready to close. You close it.
- Keep secrets out of the notes. Write where a secret is stored, never its value.

On a second machine, clone the vault repo into the same layout, run step 3 in the clone, and repeat steps 7 to 9.

Two more skills build on tickets. `scope` turns an idea into a spec and a set of tickets. `tee-up` builds one ticket into a pull request.
