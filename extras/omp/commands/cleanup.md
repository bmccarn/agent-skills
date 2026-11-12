---
description: "Ponytail audit → correctness check → issues → parallel slice PRs"
argument-hint: "<repo-or-path>"
---
Run /skill:ponytail-audit on $ARGUMENTS using repo-auditor subagents. Check every finding against current main for correctness and safety, and drop the ones that are not safe. Open one detailed GitHub issue per safe slice, with findings, owned files and the checks to run. Implement each slice with a slice-implementer in its own worktree, review each with a slice-reviewer, then open one PR per slice. Do not merge.
