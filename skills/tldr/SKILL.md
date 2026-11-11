---
name: tldr
description: "Use when the user says tldr, tl;dr, \"short version\", \"too long\" or asks for the gist. Rewrites your previous message (or what they name) in a few lines that keep every action, risk and open question."
---

# tldr

The user wants the point of your last message without reading all of it. Rewrite that message short. Do not re-answer the question, redo the work or run tools. If you find that the message was wrong, say so in the first line instead of summarizing it.

The target is your previous message, unless the user names something else: a file, a PR, a doc or pasted text.

## Keep these, always

A tl;dr that drops one of these leaves the user with a false picture, so it stays even if the tl;dr gets longer:

1. What the user must do or decide, with your recommendation.
2. A correction or reversal of something you said earlier.
3. What failed, what is blocked, and what is still unverified or was skipped.
4. Risk: destructive or irreversible steps, money, security, and anything that waits on a merge or deploy.
5. The exact names they act on: PR numbers, commands, paths, machine names.

## Cut these

How you found it, evidence detail, tables, background, context they already have, and options you rejected.

## Shape

- Plain text where markdown does not render (a terminal). Elsewhere, short markdown is fine.
- First line: the result or the answer. Then at most four lines, one item per line, no sub-bullets.
- Each line is one sentence. State the item; leave out why it is true or how you know, unless that changes what the user does.
- Merge related items into one line. Order them: what the user must do or decide first, then risks, failures and unverified items.
- Aim for about 60 words and stay under 100. Go over only for the items under "Keep these, always".
- Use the original's names for things. Add no claim, number or advice that the original does not contain.
- No lead-in ("Here's the tl;dr") and no closing offer.

Ideas from [SurefireStudios/tldr](https://github.com/SurefireStudios/tldr) (MIT): demote, don't delete, and a list of things never to compress.
