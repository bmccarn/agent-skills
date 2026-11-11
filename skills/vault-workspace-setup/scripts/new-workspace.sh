#!/bin/bash
# Create a project workspace with its vault, or only check for duplicates.
#
#   new-workspace.sh <ws> [--repo owner/repo] [--extra "owner/a owner/b"] [--check-only]
#
# Layout under this machine's projects root (~/.config/project-vault*.json):
#   <ws>/AGENTS.md              workspace rules (CLAUDE.md links to it)
#   <ws>/.claude/settings.local.json   Claude Code Stop hook (vault review gate)
#   <ws>/<ws>/                  main checkout (git init when --repo is not given)
#   <ws>/<repo>/                extra checkouts
#   <ws>/<ws>-vault/            the vault, pushed to private GitHub repo vault-<ws>
#
# Exit 0 created (or no duplicate with --check-only), 3 duplicate found, 1 error.
# Tests set VAULT_SETUP_REMOTE to a bare repo path instead of creating a GitHub
# repo, and VAULT_FIND_FIXTURE for the vault list.
set -u
die() { echo "STOP: $*" >&2; exit 1; }
HERE="$(cd "$(dirname "$0")/.." && pwd -P)"
TEMPLATE="$HERE/template"
FIND="$HERE/../project-vault/scripts/vault-find.py"
HOOK_CMD='bash "$HOME/.claude/skills/project-vault/hooks/vault-review-stop.sh"'

WS="" REPO="" EXTRA="" CHECK_ONLY=0
while [ $# -gt 0 ]; do
  case "$1" in
    --repo) REPO="$2"; shift 2 ;;
    --extra) EXTRA="$2"; shift 2 ;;
    --check-only) CHECK_ONLY=1; shift ;;
    -*) die "unknown option $1" ;;
    *) WS="$1"; shift ;;
  esac
done
[ -n "$WS" ] || die "usage: new-workspace.sh <ws> [--repo owner/repo] [--extra \"o/r ...\"] [--check-only]"
case "$WS" in *[!a-z0-9-]*) die "workspace name must be lowercase letters, digits and dashes" ;; esac
[ -d "$TEMPLATE" ] && [ -f "$FIND" ] || die "template or vault-find.py missing next to this skill"
for c in git jq python3; do command -v "$c" >/dev/null || die "$c is missing"; done
[ -n "$(git config user.email)" ] || die "git has no user.email; set it with git config --global user.email <address>"
GH=$(command -v gh || ls /opt/homebrew/bin/gh /usr/local/bin/gh 2>/dev/null | head -1)
[ -n "${VAULT_SETUP_REMOTE:-}" ] || [ -n "$GH" ] || die "gh is missing"

SETTINGS=$(python3 "$FIND" --settings) || die "cannot read project-vault settings"
BASE=$(printf '%s' "$SETTINGS" | jq -r .root)
OWNER=$(printf '%s' "$SETTINGS" | jq -r .owner)
ROOT="$BASE/$WS" VAULT="$BASE/$WS/$WS-vault" VREPO="$OWNER/vault-$WS"

# --- 1. Duplicate check: registry, GitHub, this machine ------------------------
DUP=0
dup() { echo "DUPLICATE: $*"; DUP=1; }
[ ! -e "$ROOT" ] || dup "$ROOT already exists"
LIST=$(python3 "$FIND" --list) || die "vault list failed (gh signed in?)"
for want in "$WS" $REPO $EXTRA; do
  hit=$(printf '%s\n' "$LIST" | jq -r --arg w "$want" 'select(.name == $w or ([.repositories[] | ascii_downcase] | index($w | ascii_downcase))) | .repo + " (" + .path + ")"')
  [ -z "$hit" ] || dup "$want already has a vault: $hit"
done
if [ -z "${VAULT_SETUP_REMOTE:-}" ] && "$GH" repo view "$VREPO" >/dev/null 2>&1; then dup "GitHub repo $VREPO exists"; fi
LOCAL=$(bash "$HERE/scripts/find-local-vaults.sh" "$BASE" "$HOME" 2>/dev/null | grep -i -- "$WS" | sort -u)
[ -z "$LOCAL" ] || dup "vault folders on this machine mention $WS:
$LOCAL"
[ "$DUP" = 0 ] || { echo "Nothing was created. Decide with the user whether one of these is the vault."; exit 3; }
echo "no duplicate vault for $WS on this machine or on GitHub ($OWNER)"
[ "$CHECK_ONLY" = 0 ] || exit 0

# --- 2. Workspace and checkouts ------------------------------------------------
mkdir -p "$ROOT/.claude" || die "cannot create $ROOT"
if [ -n "$REPO" ]; then "$GH" repo clone "$REPO" "$ROOT/$WS" -- -q || die "clone $REPO failed"
else git init -q -b main "$ROOT/$WS"; fi
for r in $EXTRA; do "$GH" repo clone "$r" "$ROOT/${r#*/}" -- -q || die "clone $r failed"; done

# --- 3. Vault -------------------------------------------------------------------
cp -R "$TEMPLATE" "$VAULT"
python3 - "$VAULT/vault.json" "$WS" $REPO $EXTRA <<'PY'
import json, sys
json.dump({"name": sys.argv[2], "repositories": sys.argv[3:]}, open(sys.argv[1], "w"), indent=2)
open(sys.argv[1], "a").write("\n")
PY
git -C "$VAULT" init -q -b main
git -C "$VAULT" config core.hooksPath .githooks
git -C "$VAULT" add -A
git -C "$VAULT" commit -qm "vault: initial" || die "first vault commit failed"
if [ -n "${VAULT_SETUP_REMOTE:-}" ]; then
  git -C "$VAULT" remote add origin "$VAULT_SETUP_REMOTE"
  git -C "$VAULT" push -q -u origin main || die "push to $VAULT_SETUP_REMOTE failed"
else
  "$GH" repo create "$VREPO" --private --source "$VAULT" --remote origin --push \
    --description "Obsidian work vault for $WS (agent-maintained, private)" >/dev/null || die "gh repo create $VREPO failed"
  "$GH" repo edit "$VREPO" --add-topic vault --add-topic obsidian --add-topic work-journal >/dev/null || die "adding topics failed"
fi

# --- 4. Workspace instructions and Claude Code wiring -----------------------------
VAULT_WHERE="GitHub \`$VREPO\`, private"
[ -z "${VAULT_SETUP_REMOTE:-}" ] || VAULT_WHERE="remote \`$VAULT_SETUP_REMOTE\`"
if [ -n "$REPO" ]; then MAIN="\`$WS\` (GitHub \`$REPO\`)"; else MAIN="\`$WS\` (local only, no remote)"; fi
for r in $EXTRA; do MAIN="$MAIN, \`${r#*/}\` (GitHub \`$r\`)"; done
cat > "$ROOT/AGENTS.md" <<EOF
# $WS workspace

Repos: $MAIN, plus the project vault \`$WS-vault\` ($VAULT_WHERE).

## Project vault — read this first

\`$WS-vault/\` is the canonical cross-session journal for this workspace. Use the \`project-vault\` skill at session start (pull, then read HOME.md and the journal) and at session end (write back, commit, push). The vault's own \`AGENTS.md\` is the contract.
EOF
ln -s AGENTS.md "$ROOT/CLAUDE.md"
jq -n --arg cmd "$HOOK_CMD" --arg msg "$WS vault session-end review gate" \
  '{hooks:{Stop:[{hooks:[{type:"command",command:$cmd,timeout:15,statusMessage:$msg}]}]}}' > "$ROOT/.claude/settings.local.json"
for c in "$ROOT"/*/; do
  c=${c%/}; [ "$c" = "$VAULT" ] && continue; [ -e "$c/.git" ] || continue
  mkdir -p "$c/.claude"
  ln -s ../../.claude/settings.local.json "$c/.claude/settings.local.json"
  echo /.claude/settings.local.json >> "$(git -C "$c" rev-parse --path-format=absolute --git-common-dir)/info/exclude"
done

# --- 5. Obsidian ------------------------------------------------------------------
OBS="$HOME/.config/obsidian/obsidian.json"
[ "$(uname)" = Darwin ] && OBS="$HOME/Library/Application Support/obsidian/obsidian.json"
if pgrep -x obsidian >/dev/null 2>&1 || pgrep -x Obsidian >/dev/null 2>&1; then
  echo "manual: Obsidian is running; open $VAULT with 'Open folder as vault'"
elif [ -d "$(dirname "$OBS")" ] || [ -n "${VAULT_SETUP_REMOTE:-}" ]; then
  mkdir -p "$(dirname "$OBS")"
  python3 - "$OBS" "$VAULT" <<'PY'
import json, os, secrets, sys, time
path, vault = sys.argv[1], sys.argv[2]
data = {"vaults": {}}
if os.path.exists(path) and os.path.getsize(path):
    data = json.load(open(path))
data.setdefault("vaults", {})[secrets.token_hex(8)] = {"path": vault, "ts": int(time.time() * 1000)}
json.dump(data, open(path + ".tmp", "w")); os.replace(path + ".tmp", path)
PY
fi

# --- 6. Self-checks ----------------------------------------------------------------
FAIL=0
check() { if eval "$2" >/dev/null 2>&1; then echo "PASS  $1"; else echo "FAIL  $1"; FAIL=1; fi; }
HOOK="$HERE/../project-vault/hooks/vault-review-stop.sh"
probe() { (cd "$1" && echo '{"session_id":"setup-probe","stop_hook_active":false}' | bash "$HOOK"); rm -f "${TMPDIR:-/tmp}/claude-vault-stop-setup-probe"; }
check "Stop hook asks for a review in the workspace" 'probe "$ROOT" | jq -e ".decision == \"block\""'
check "Stop hook asks for a review in the main checkout" 'probe "$ROOT/$WS" | jq -e ".decision == \"block\""'
check "Stop hook is silent outside the workspace" '[ -z "$(probe /)" ]'
check "checkout shares the workspace hook settings" '[ -f "$ROOT/$WS/.claude/settings.local.json" ]'
check "vault.json names the workspace" 'jq -e --arg w "$WS" ".name == \$w" "$VAULT/vault.json"'
P="$VAULT/inbox/setup-probe.md"
printf -- '---\ntype: note\n---\nPRs #12/#13\n' > "$P"; git -C "$VAULT" add inbox/setup-probe.md
check "commit guard rejects '#12/#13'" '! git -C "$VAULT" commit -qm probe'
git -C "$VAULT" rm -q --cached -f inbox/setup-probe.md; rm -f "$P"
check "vault is clean and pushed" '[ -z "$(git -C "$VAULT" status --porcelain)" ] && [ "$(git -C "$VAULT" rev-parse HEAD)" = "$(git -C "$VAULT" rev-parse @{u})" ]'
if [ -z "${VAULT_SETUP_REMOTE:-}" ]; then
  check "vault-find resolves $WS to $VAULT" 'python3 "$FIND" "$WS" | jq -e --arg p "$VAULT" ".path == \$p"'
fi
echo
[ "$FAIL" = 0 ] || { echo "SETUP INCOMPLETE: fix each FAIL line" >&2; exit 1; }
echo "created $ROOT (vault $VREPO)"
