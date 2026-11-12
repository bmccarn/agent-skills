---
alwaysApply: true
agents: [main]
---
When you dispatch two or more subagents that edit files at the same time, set `isolated: true` on each so their changes come back as patches instead of colliding in the checkout. Run read-only agents (reviewers, `sol`, `muse`, scouts) without isolation: they must see the uncommitted working tree they are reviewing.
