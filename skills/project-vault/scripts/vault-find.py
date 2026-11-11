#!/usr/bin/env python3
"""Find a project vault and its local clone.

A project vault is a private GitHub repo with the topic `vault`. Its root
`vault.json` names the project, its code repositories and, optionally, where
the clone lives under this machine's projects root:

    {"name": "acme", "repositories": ["your-org/acme"]}
    {"name": "widgets", "path": "widgets/vault", "repositories": ["your-org/widgets"]}

The default local path is <root>/<name>/<name>-vault. A vault without
vault.json can be described in ~/.config/project-vault.json under "vaults".

~/.config/project-vault.json is optional:

    {"root": "~/development", "owners": ["your-github-login"]}

root is the folder that holds the workspaces (default ~/development). owners
are the GitHub accounts whose vault repos are listed (default: the account gh
is signed in as). ~/.config/project-vault/local.json may set a different root
for one machine.

Usage:
  vault-find.py --list                  every vault, as JSON lines
  vault-find.py --settings              this machine's projects root and vault owner
  vault-find.py <query> [--clone]       the vault for a code repo (owner/repo or
                                        repo), workspace name or vault repo;
                                        --clone clones it if missing and arms
                                        the commit guard.
Exit codes: 0 found, 1 no match, 2 error. Stdlib only (macOS Python 3.9).
"""
import base64
import json
import os
import shutil
import subprocess
import sys

HOME = os.path.expanduser("~")
CONFIG = os.path.join(HOME, ".config", "project-vault.json")
LOCAL = os.path.join(HOME, ".config", "project-vault", "local.json")


def load(path):
    try:
        with open(path) as f:
            return json.load(f)
    except FileNotFoundError:
        return {}


def gh_bin():
    found = shutil.which("gh")
    if found:
        return found
    for p in ("/opt/homebrew/bin/gh", "/usr/local/bin/gh"):
        if os.access(p, os.X_OK):
            return p
    sys.exit("vault-find: gh not found")


def gh(*args):
    r = subprocess.run([gh_bin()] + list(args), capture_output=True, text=True, timeout=60)
    return r.returncode, r.stdout


def settings():
    cfg, local = load(CONFIG), load(LOCAL)
    root = os.path.expanduser(local.get("root") or cfg.get("root") or "~/development")
    owners = cfg.get("owners")
    if not owners:  # default: the account gh is signed in as
        rc, out = gh("api", "user", "--jq", ".login")
        if rc != 0 or not out.strip():
            sys.exit("vault-find: set \"owners\" in %s, or run gh auth login" % CONFIG)
        owners = [out.strip()]
    return root, owners, cfg.get("vaults") or {}


def vaults():
    root, owners, overrides = settings()
    if os.environ.get("VAULT_FIND_FIXTURE"):  # tests: a JSON list instead of GitHub
        with open(os.environ["VAULT_FIND_FIXTURE"]) as f:
            listed = json.load(f)
    else:
        listed = []
        for owner in owners:
            rc, out = gh("repo", "list", owner, "--topic", "vault", "--limit", "200",
                         "--json", "nameWithOwner,isArchived")
            if rc != 0:
                sys.exit("vault-find: gh repo list %s failed (signed in?)" % owner)
            for r in json.loads(out):
                if r["isArchived"]:
                    continue
                meta = overrides.get(r["nameWithOwner"])
                if meta is None:
                    rc, out = gh("api", "repos/%s/contents/vault.json" % r["nameWithOwner"], "--jq", ".content")
                    meta = json.loads(base64.b64decode(out)) if rc == 0 and out.strip() else {}
                listed.append(dict(meta, repo=r["nameWithOwner"]))
    result = []
    for v in listed:
        name = v.get("name") or v["repo"].split("/")[1].replace("vault-", "", 1)
        path = os.path.join(root, v.get("path") or os.path.join(name, name + "-vault"))
        result.append({
            "name": name,
            "repo": v["repo"],
            "path": path,
            "cloned": os.path.isdir(os.path.join(path, ".git")),
            "repositories": v.get("repositories", []),
        })
    return result


def matches(v, q):
    q = q.lower().rstrip("/")
    keys = {v["name"].lower(), v["repo"].lower(), v["repo"].split("/")[1].lower()}
    for r in v["repositories"]:
        keys.add(r.lower())
        keys.add(r.split("/")[-1].lower())
    return q in keys


def clone(v):
    path = v["path"]
    if v["cloned"]:
        rc = subprocess.run(["git", "-C", path, "remote", "get-url", "origin"],
                            capture_output=True, text=True)
        if v["repo"].lower() not in rc.stdout.lower():
            sys.exit("vault-find: %s exists but its origin is not %s; leaving it alone" % (path, v["repo"]))
        return
    if os.path.exists(path):
        sys.exit("vault-find: %s exists and is not a git clone; leaving it alone" % path)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    if subprocess.run([gh_bin(), "repo", "clone", v["repo"], path, "--", "-q"]).returncode != 0:
        sys.exit("vault-find: clone of %s failed" % v["repo"])
    subprocess.run(["git", "-C", path, "config", "core.hooksPath", ".githooks"], check=True)
    v["cloned"] = True


def main(argv):
    if argv[:1] == ["--settings"]:
        root, owners, _ = settings()
        print(json.dumps({"root": root, "owner": owners[0]}))
        return 0
    if argv[:1] == ["--list"]:
        for v in vaults():
            print(json.dumps(v))
        return 0
    want_clone = "--clone" in argv
    args = [a for a in argv if a != "--clone"]
    if len(args) != 1:
        print(__doc__, file=sys.stderr)
        return 2
    found = [v for v in vaults() if matches(v, args[0])]
    if not found:
        print("vault-find: no vault for %s" % args[0], file=sys.stderr)
        return 1
    if len(found) > 1:
        print("vault-find: %s matches several vaults: %s" % (args[0], ", ".join(v["repo"] for v in found)), file=sys.stderr)
        return 2
    if want_clone:
        clone(found[0])
    print(json.dumps(found[0]))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
