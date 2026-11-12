# Set up OMP with these skills

This guide installs the whole setup in [OMP (oh-my-pi)](https://github.com/can1357/oh-my-pi): the skills, the global instructions, the agents, rules and commands, and the settings. Part 1 lists the steps. Part 2 explains why each setting in `config.yml` has its value. [how-it-works.md](how-it-works.md) explains the skills, the agents, the rules and the vault.

If you point a coding agent at this file and at `how-it-works.md`, it has what it needs to walk you through the setup and to answer "why is it like this?"

The files come from one person's working setup on OMP 18.19.0:

| In this repo | Where it goes | What it holds |
|---|---|---|
| `skills/*` | `~/.agents/skills/` | The skills. OMP reads this folder natively. |
| `extras/AGENTS.md` | `~/.omp/agent/AGENTS.md` | Global instructions that OMP loads into every session. |
| `extras/omp/config.yml` | `~/.omp/agent/config.yml` | Settings: model roles, presets, fallbacks, the advisor, per-agent models, LSP, memory and UI. |
| `extras/omp/agents/` | `~/.omp/agent/agents/` | Eight agents: the `sol` and `muse` reviewers, `ponytail-reviewer`, and the agents for slices, audits, dependency bumps and security review. |
| `extras/omp/rules/` | `~/.omp/agent/rules/` | Eight short rules that OMP adds to the main session or to chosen subagents. |
| `extras/omp/commands/` | `~/.omp/agent/commands/` | The `/tldr`, `/prs`, `/ship` and `/cleanup` commands. |
| `extras/omp/WATCHDOG.md` | `~/.omp/agent/WATCHDOG.md` | What the advisor looks for first. |
| `extras/omp/TITLE_SYSTEM.md` | `~/.omp/agent/TITLE_SYSTEM.md` | How OMP names a session. |
| `extras/omp/lsp.json` | `~/.omp/agent/lsp.json` | Extra root markers for the built-in language servers. |
| `extras/omp/mcp.json` | `~/.omp/agent/mcp.json` | The Context7 documentation server. |

## Part 1: Set it up

### Accounts you need

Each model in the settings needs a signed-in provider. The table lists the providers by the prefix in the model ID.

| Provider prefix | Account | What breaks without it |
|---|---|---|
| `anthropic/` | A Claude subscription or API key | Everything. Every role that edits files runs on Claude. |
| `openai-codex/` | A ChatGPT account that can use Codex | The advisor, the `review` role, the `sol`, `slice-reviewer` and `security-reviewer` agents, `sol-loop`, and image generation. |
| `openrouter/` | An OpenRouter API key | The `judge` role. `features.unexpectedStopDetection: smart` uses it. |
| `muse-code/` | A Muse Code subscription from Meta | Only the `muse` agent, which `council` calls. |

If you lack an account, step 7 says what to change.

### Tools you need

- `git`, and `gh` signed in (`gh auth status`). Every PR and issue step goes through `gh`.
- `jq` and `python3`. The vault scripts and `pr-wait` use them.
- Obsidian with the core Bases plugin, if you use a project vault.
- A terminal font from [Nerd Fonts](https://www.nerdfonts.com), because the settings use `symbolPreset: nerd`.

### Steps

1. Install OMP. Follow the install section of the [oh-my-pi README](https://github.com/can1357/oh-my-pi).
2. Clone this repo and change into it:

	```bash
	git clone https://github.com/bmccarn/agent-skills.git
	cd agent-skills
	```

3. Copy the skills. The copy replaces the files of any skill with the same name. If `ls ~/.agents/skills` lists one of the names in `skills/`, back that folder up first.

	```bash
	mkdir -p ~/.agents/skills
	cp -R skills/* ~/.agents/skills/
	```

4. Install the ponytail plugin. `tee-up`, `vet` and four of the agents load its `ponytail-review` skill.

	```bash
	omp plugin marketplace add DietrichGebert/ponytail
	omp plugin install ponytail@ponytail
	```

5. Read `extras/AGENTS.md`. It holds one person's working rules, such as when to ask before a git command and how to write reports. Edit what does not fit you.

	If `~/.omp/agent/AGENTS.md` already exists, copy the sections you want into it by hand. The command below copies the file only when you have none:

	```bash
	mkdir -p ~/.omp/agent
	[ -e ~/.omp/agent/AGENTS.md ] || cp extras/AGENTS.md ~/.omp/agent/AGENTS.md
	```

6. Copy the OMP files. The first two commands save every file you already have that the copy would replace. They save each file in a dated folder next to `~/.omp/agent`, and print a `saved` line for it. The last command copies everything in `extras/omp/`.

	```bash
	B=~/.omp/agent.bak-$(date +%Y%m%d-%H%M%S)
	(cd extras/omp && find . -type f) | while read -r f; do if [ -e ~/.omp/agent/"$f" ]; then mkdir -p "$B/$(dirname "$f")" && cp ~/.omp/agent/"$f" "$B/$f" && echo "saved $f"; fi; done
	cp -R extras/omp/. ~/.omp/agent/
	```

	If you see `saved` lines, compare each saved file in `$B` with the new copy, and move your own changes back into the new file.

7. If you lack an account from the table above, edit `~/.omp/agent/config.yml` now. Each role appears in three places: `modelRoles`, `modelPresets.daily.modelRoles` and `modelPresets.deep.modelRoles`. Make each role change in all three. A preset switch writes all of the preset's roles. If you change a role only in `modelRoles`, the next `/modelpreset switch` puts the old model back.

	- No `openai-codex/` access:
		- Set `advisor.enabled: false`.
		- Point the `advisor` and `review` roles at a Claude model.
		- Delete the `image` role.
		- Point `task.agentModelOverrides.security-reviewer` at a Claude model.
		- Change the `model:` line in `~/.omp/agent/agents/sol.md`.

		`sol-loop` and `council` then lose their second model family. `slice-reviewer` and `reviewer` follow the `review` role.
	- No `openrouter/` access: delete the `judge` role and set `features.unexpectedStopDetection: mechanical`.
	- No `muse-code/` access: change the `model:` line in `~/.omp/agent/agents/muse.md`, or skip `council`.
	- A newer model release: change the model IDs. The IDs in the file were current in November 2026.

	To find every place that names a provider, run `grep -rn 'openai-codex/\|openrouter/\|muse-code/' ~/.omp/agent/config.yml ~/.omp/agent/agents`. Each key under `retry.fallbackChains` names a model, and OMP uses the chain only when that model runs. You can leave those keys in place.

8. Install the language servers for the languages you work in. `lsp.json` does not install servers. It only adds root markers to OMP's built-in server definitions. For example, the `pyright` server needs the `pyright` command, and `gopls` needs `gopls`.

9. Start OMP:

	```bash
	omp
	```

	On the first start, OMP runs its setup wizard. The settings file leaves out `setupVersion`, the first-run marker, so the wizard shows all its steps:

	- **Sign in.** Sign in to every provider from the accounts table. You can sign in later with `/login`.
	- **Model.** Skip this step. If you press Enter, OMP saves the highlighted model as your default and replaces `modelRoles.default` from the settings file.
	- **Theme** and **auto-update.** Pick what you like. These steps change the theme and the auto-update setting.

10. Check the result. In a terminal, run:

	```bash
	omp config get modelRoles
	```

	The `default` value must be `anthropic/claude-opus-5-5:high`. The `advisor` value must be `openai-codex/gpt-6.1-sol:high`. If you changed a role in step 7, expect your value for that role. If `default` shows another model, the wizard's model step replaced it. Set `modelRoles.default` back in `~/.omp/agent/config.yml`.

11. Check the skills and agents. Start `omp` and ask: "Which skills and agents named sol, muse, tee-up and vet can you use?" The answer must list all four.

12. If you want a project vault, follow [VAULT.md](../VAULT.md), or ask OMP to "set up a workspace with a vault for acme". OMP does not run the Claude Code Stop hook, so say "update the vault" before you end a session.

### Change settings later

OMP rewrites `~/.omp/agent/config.yml` when you run `/settings`, `/modelpreset switch` or `omp config set`. When it rewrites the file, it drops the comments. The comments stay in `extras/omp/config.yml`, so look there for the reasons.

Two model presets come with the settings:

- `/modelpreset switch deep` puts Claude Fable 5.2 on the `default` and `slow` roles, for hard problems.
- `/modelpreset switch daily` switches back. Keep `daily` identical to `modelRoles`.

## Part 2: Why the settings are this way

### One rule decides the model routing

Every role or agent that can edit files runs on Claude. GPT 6.1 Sol and Muse only review. The reason is a split of jobs. Claude writes the code, and a model from another provider checks it, so the two do not share the same blind spots. The skills `sol-loop`, `council`, `tee-up` and `vet` depend on that split.

The rule is a convention in this config, not a limit that OMP enforces. Each setting below either follows the rule or protects it.

### Model roles

OMP sends each kind of work to a named role. The settings set every role explicitly.

| Role | What uses it | Model | Why |
|---|---|---|---|
| `default` | The main session | Opus 5.5, high | The daily driver. |
| `smol` | `scout`, `sonic` and other quick work | Sonnet 5.5, high | Fast enough for lookups. `high` keeps accuracy without the latency of `xhigh`. |
| `slow` | The model cycle, and the target of `plan` | Opus 5.5, xhigh | `slow` is in the model cycle (`smol`, `default`, `slow`), so it can become the coding model. It must be Claude. |
| `plan` | Plan mode | `@slow` | Plans get the most reasoning. The Sol advisor reviews them anyway. |
| `task` | Subagents that implement changes | Opus 5.5, high | Subagents edit files, so they run on Claude. |
| `advisor` | The live reviewer on every turn | Sol, high | OMP gives the advisor read-only tools, so Sol can review without writing. |
| `review` | The `reviewer` agent | Sol, high | Review work. |
| `commit` | Commit messages | Sonnet 5.5, medium | Commit messages are public text. Sonnet is enough. |
| `tiny` | Session titles and similar small jobs | Sonnet 5.5, low | Trivial work. |
| `memory` | Memory extraction | Sonnet 5.5, medium | What memory stores decides what it recalls later, so this role gets more than `low`. |
| `vision` | Questions about screenshots | Opus 5.5, high | Accuracy over cost. |
| `image` | Image generation | `gpt-image-2` | The image model that the Codex login gives. |
| `judge` | Classification, and smart stop detection | `jev-latest` through OpenRouter | `features.unexpectedStopDetection: smart` needs a judge. |

`defaultThinkingLevel: high` applies to any model ID without a thinking suffix. Every role above has a suffix, so the setting matters only for models you pick by hand.

`textVerbosity: medium` exists because OMP 18.17.0 changed the default to `low` and applied it to Codex models too. With `low`, the advisor and the Sol reviewers wrote short reports that left out findings.

### Fallbacks keep coding on Claude

When a model hits a usage limit, OMP walks a fallback chain. The chains in these settings keep Sol out of coding:

- `retry.fallbackOn: usage-limit`. A transient server error retries on the same model. Only a usage limit walks the chain. With the default `any`, one server error moved the rest of a turn to another model.
- `retry.usageAwareFallback: true`. Before each turn, OMP checks the provider's quota reports. If you have two accounts on one provider, it moves to the healthy account first.
- `default`, `task` and `slow` fall back to Sonnet 5.5. If every Claude account is out, the request fails and you see the error. Coding never moves to Sol.
- `smol` falls back to Opus 5.5.
- `anthropic/claude-fable-5-2` falls back to Opus, then Sonnet, so the `deep` preset does not drop straight to Sonnet.
- `openai-codex/gpt-6.1-sol` and `muse-code/muse-wonder-full-1.0` have empty chains. `sol-loop` and `council` forbid a silent swap of the reviewer's model. A chain keyed on an exact model wins over a role chain, so these empty chains also cover the `advisor` and `review` roles. A failed review shows as an error and does not run on Claude.
- `providers.anthropic.slowMode: auto`. When a Claude limit hits, OMP uses Anthropic's low-priority lane, which keeps the session on Claude.

### The advisor reviews every turn

`advisor.enabled: true` pairs the main session with a second model (the `advisor` role, Sol). The advisor reads each turn and adds notes. It has read-only tools.

`advisor.syncBacklog: "3"` makes the main session wait for advice only when three reviews are queued. With `1`, the main session waits often.

`task.agentAdvisor` turns the advisor on for the `task` and `slice-implementer` subagents too, because those subagents write code.

### Service tiers

`tier.openai: priority` and `tier.advisor: priority` run Sol in OpenAI's fast lane, so review loops finish sooner. `tier.anthropic: none` keeps Claude on the normal tier. `task.agentServiceTierOverrides` gives the same fast lane to the agents that run on Sol: `sol`, `reviewer`, `slice-reviewer` and `security-reviewer`.

### Subagents

- `task.agentModelOverrides` pins the built-in agents to roles: `task` to `@task`, `scout` and `sonic` to `@smol`, and `reviewer` to `@review`. `security-reviewer` runs on Sol at `xhigh`, because security review is review work.
- `task.isolation.enabled: true` adds an `isolated` option to each subagent dispatch. It does not isolate subagents by default. Ask for isolation when two subagents edit files at once. Leave reviewers unisolated so they see your uncommitted changes.
- `task.showResolvedModelBadge: true` shows which model each subagent actually ran on.

### Code intelligence

- `lsp.enabled`, `task.enableLsp`, `lsp.diagnosticsOnWrite` and `lsp.diagnosticsOnEdit` are on. The agent sees type errors right after each edit.
- `lsp.formatOnWrite: false`. In a repo without a formatter config, format-on-write reformats whole files. That adds unrelated lines to every diff. The repo's own formatter runs in its checks instead.
- `prewalk.enabled: false`. Prewalk hands the session to the `smol` model at the first edit. That saves cost but moves editing off the main model.

### Safety

`bash.gitGuard: true` makes OMP refuse git commands that discard work or move the working tree: `stash`, `reset --hard`, a branch switch and a path restore. Reviewers run bash in your checkout, and this guard stops them from losing your changes. The guard also applies to the main session. To run one of those commands, use your own terminal.

`secrets.enabled: true` makes OMP hide configured secrets and redact credential-shaped tokens before it sends text to a model provider. `checkpoint.enabled: true` gives the agent checkpoint and rewind tools.

### Memory and learning

- `memory.backend: mnemopi` turns on long-term memory. The default is `off`.
- `mnemopi.scoping: per-project-tagged` writes each memory to the current project's store. Recall also sees memories from other projects.
- `autolearn.enabled: true`. After the agent stops, OMP prompts it to save lessons to memory and to create or update managed skills. Managed skills stay on your machine.

### Isolation from other tools

`enabledProviders: []` stops OMP from loading Claude Code's or Codex's user-level skills, plugins and context files. The skills live in `~/.agents/skills`, which OMP reads natively. Without this setting, OMP can load a skill twice.

### Other settings

| Setting | Value | Why |
|---|---|---|
| `features.unexpectedStopDetection` | `smart` | OMP recovers when the model stops without a visible message. `smart` also uses a small model to classify stops that end with text only. |
| `branchSummary.enabled` | `true` | OMP offers to summarize a session branch when you leave it. |
| `compaction.handoffSaveToDisk` | `true` | OMP saves each handoff document as a markdown file. |
| `github.enabled` | `true` | Turns on OMP's GitHub tool for repositories, issues, pull requests and Actions. |
| `codexResets.autoRedeem` | `"no"` | OMP does not spend saved Codex usage resets on its own. |
| `marketplace.autoUpdate` | `auto` | OMP checks for plugin updates at startup and installs them. |
| `update.auto` | `true` | OMP updates itself. |
| `dev.autoqa` | `false` | Turns off OMP's automatic tool-issue reports, which are on by default. |
| `theme`, `symbolPreset`, `statusLine`, `composer` | various | Personal taste. `symbolPreset: nerd` needs a Nerd Font in your terminal. |
