---
description: Merge PRs safely, follow the deploy to completion, clean up branches
argument-hint: <pr-numbers> [staging|prod]
---
Ship $ARGUMENTS. For each PR: confirm CI is green and review comments are resolved, and work out the correct merge order (stacked PRs merge in order). Merge. Watch the resulting deploy workflow until it finishes, and report success or failure with the run URL. Never approve a production deployment gate yourself: stop, tell me it is waiting, and wait for me. After a successful deploy, delete the merged remote and local branches and their worktrees.
