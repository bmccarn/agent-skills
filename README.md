# Agent skills

Sixteen skills for coding agents (Claude Code, Codex, OMP), the project vault template that three of them read and write, and the OMP configuration they were written against. In the skill text, "the user" is the person who runs the agent.

A skill is a folder with a `SKILL.md` file. The agent always sees the description at the top of that file. It reads the rest when the description matches your request.

To copy the whole setup, read two pages:

- [docs/how-it-works.md](docs/how-it-works.md) explains each part and why it is there: the skills, the global instructions, the OMP agents and rules, and the project vault.
- [docs/omp-setup.md](docs/omp-setup.md) installs everything in OMP, and explains each setting.

## Install the skills

Clone the repo and copy the skill folders into your agent's skills folder.

```bash
git clone https://github.com/bmccarn/agent-skills.git
cd agent-skills
mkdir -p ~/.claude/skills ~/.agents/skills
cp -R skills/* ~/.claude/skills/     # Claude Code
cp -R skills/* ~/.agents/skills/     # Codex and OMP
```

Check that Claude Code found them:

```bash
claude -p 'Is a skill named tee-up available to you? Answer YES or NO.'
```

Skills call each other by name. If you install only some of them, also install the skills in the "Uses" column.

## The skills

| Skill | You say | What the agent does | Uses |
|---|---|---|---|
| `tee-up` | "tee up" plus an issue, a vault ticket or a task | Reproduces the problem, fixes it in a worktree, proves the fix, gets two reviews, opens a PR and watches CI. It leaves the PR unmerged. | `sol-loop`, `ponytail-review`, `unslop`, `babysit-pr`, `project-vault` |
| `vet` | "vet" plus a PR or branch | Reviews someone else's change against its stated intent without touching it. Reports each confirmed finding as a question for the author. | `ponytail-review`, `sol-loop`, `unslop` |
| `scope` | "scope" plus an idea | Interviews you until the plan is agreed, writes a spec, has a second model review it, and files tickets in the project's tracker. | `grilling`, `to-spec`, `to-tickets`, `unslop`, `project-vault` |
| `sol-loop` | "sol loop" | Has a second model review your change in rounds (three by default) and answers each finding. | |
| `council` | "council" | Asks three models from three providers to review the work and reports their scores. | |
| `babysit-pr` | "babysit this PR", "watch the PR" | Waits for CI and review bots with the bundled `scripts/pr-wait`, and handles their findings. | `unslop` |
| `blast-radius` | "blast radius of X", "what could this break" | Looks for what a change could break outside the diff, and proves the key safety fact by running code. | `council` or `sol-loop` for a wide change |
| `grilling` | "grill me" | Questions you about a plan, one round of questions at a time, until you agree on it. | |
| `to-spec` | `/to-spec`, or through `scope` | Turns the conversation into a spec. | |
| `to-tickets` | `/to-tickets`, or through `scope` | Cuts a spec into tickets that each name their blockers. | |
| `technical-writing` | Loads for docs, guides, RFCs and READMEs | Applies four sets of writing rules. | `unslop` |
| `unslop` | Loads for prose that other people read | Removes formulaic phrasing and filler. | |
| `tldr` | "tldr", "short version" | Rewrites its last message in a few lines that keep every action, risk and open question. | |
| `project-vault` | "update the vault", "journal this". Also loads at session start and end in a vault workspace. | Reads the project vault at session start and writes state and a journal block back at session end. | |
| `vault-sweep` | "run a vault sweep" | Checks vault notes against GitHub and other primary sources, and corrects the notes that are out of date. | `project-vault` |
| `vault-workspace-setup` | "set up a workspace with a vault for X" | Creates a workspace folder, a private vault repo on GitHub and the Claude Code hook settings. | `project-vault` |

## The project vault

A project vault is an Obsidian vault in a private git repo. Agents read it when a session starts. When a session ends, they write the current state and a journal block back, then commit. The vault holds one note for each project, tracked pull request, deployment and ticket, and a dashboard of what is open.

The blank vault is in `skills/vault-workspace-setup/template/`. The `vault-workspace-setup` skill creates a vault from it. [VAULT.md](VAULT.md) has the same steps by hand.

## What the skills need

### Command-line tools

- `git`, and `gh` signed in (`gh auth status`). Every PR and issue step goes through `gh`.
- `jq` and `python3`. The vault scripts, the Stop hook and `pr-wait` use them. The Python scripts need only the standard library.
- Obsidian, to read a project vault. The vault dashboards need the core Bases plugin.

### A second model for reviews

`sol-loop`, `tee-up`, `vet` and `scope` ask a model from another provider to review the work. "Sol" in the skill text is the OpenAI model that the Codex CLI runs.

- From Claude Code, the skills run `codex exec -s read-only`. Install the Codex CLI and sign in.
- From Codex, the skills run `claude -p --model opus`. Install Claude Code and sign in.
- From OMP, the skills call an agent named `sol`. `vet` also calls `ponytail-reviewer`, and `council` calls `muse`. The definitions are in `extras/omp/agents/`, with the rest of the OMP configuration. [docs/omp-setup.md](docs/omp-setup.md) installs them.

A skill that cannot reach the second model says so in its report. It does not substitute another model.

### The ponytail plugin

`tee-up` and `vet` call a skill named `ponytail-review`. The [ponytail plugin](https://github.com/DietrichGebert/ponytail) provides it. In Claude Code:

```
/plugin marketplace add DietrichGebert/ponytail
/plugin install ponytail@ponytail
```

### The global rules that the skills cite

`tee-up` and `scope` cite sections of a global instruction file by name: "Changing code", "Done means proven", "Git", "Public text" and "Cloud operations". `extras/AGENTS.md` is that file.

Copy the sections you want into `~/.claude/CLAUDE.md` for Claude Code, `~/.codex/AGENTS.md` for Codex, or `~/.omp/agent/AGENTS.md` for OMP. The skills run without them, but then nothing defines the rules they cite. The file holds one person's working rules, so read it before you adopt it.

### Settings for the vault skills

`project-vault` finds a vault by walking up from the working directory, so one vault needs no settings. `vault-find.py` and `vault-workspace-setup` also read `~/.config/project-vault.json`, which is optional:

```json
{"root": "~/development", "owners": ["your-github-login"]}
```

- `root` is the folder that holds your workspaces. The default is `~/development`.
- `owners` are the GitHub accounts whose vault repos the scripts list. The default is the account that `gh` is signed in as.

The Stop hook in `skills/project-vault/hooks/` works only in Claude Code. `vault-workspace-setup` registers it for each workspace it creates. [VAULT.md](VAULT.md) has the steps to register it by hand.

## Change these for your setup

- `council` ends with a "Local notes" section that names three models. Replace them with models you can reach.
- `babysit-pr` waits for a Greptile or Macroscope review by default. If your repositories use neither, the skill's `pr-wait --until green` mode waits for required checks only.
- `tee-up`, `vet` and `scope` name the question tools and CLI flags of Claude Code, Codex and OMP. Delete the routes for tools you do not use, or leave them.

## Where the skills come from

Nine skills are adapted from public collections. Each of those folders keeps the upstream `LICENSE` and an `upstream.json` that names the source repository and revision.

- `babysit-pr`, `council` and `sol-loop` come from [t3dotgg/tstack](https://github.com/t3dotgg/tstack).
- `blast-radius`, `technical-writing` and `unslop` come from [cursor/plugins](https://github.com/cursor/plugins).
- `grilling`, `to-spec` and `to-tickets` come from [mattpocock/skills](https://github.com/mattpocock/skills).

Several of the nine have local changes. Where a skill ends with a "Local notes" section, that section holds local additions.

The other seven were written for this repo: `tee-up`, `vet`, `scope`, `tldr`, `project-vault`, `vault-sweep` and `vault-workspace-setup`.

## License

The files written for this repo are under the MIT license in [LICENSE](LICENSE). Each adapted skill is under the MIT license in its own folder.
