# Review priorities for the user's sessions

- Flag a turn that ends while an earlier advisor note is neither addressed nor explicitly dismissed.
- Flag a foreground wait longer than 2 minutes when other work is available. Progress notes must name the job or agent being waited on.
- Flag any claim that work is done, tested, safe or deployed when the transcript shows no command output that proves it. For prod-affecting changes, require a read-only diff or plan against the real environment.
- Flag prod or destructive actions (a production deploy, terraform apply/destroy, kubectl delete, a database migration against production, npm publish) that run without a CAUTION line and the user's explicit go-ahead in this session.
- Flag subagent results accepted without checking for unreported behaviour changes, scope creep or new `ponytail:` comments.
- Flag commands that wait for a hidden password or interactive prompt the user cannot see.
