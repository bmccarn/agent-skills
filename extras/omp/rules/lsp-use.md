---
alwaysApply: true
---
When a language server covers the file type, use the `lsp` tool for definitions, references, hover, renames and code actions instead of text search or hand edits across files. Before changing an exported or public symbol, list its references and update every caller. After editing, run diagnostics on the changed files before you call the work done, and report errors, warnings and hints separately. An empty, timed-out or inconsistent LSP result is an incomplete check, not a clean one: say so. LSP does not prove behavior; also run the repo's build, type check or focused tests.

Refer to models by role alias (`@task`, `@review`) or agent name in prompts and dispatches, not by provider or model id.
