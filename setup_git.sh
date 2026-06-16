#!/usr/bin/env bash
#
# setup_git.sh
# One-time bootstrap: turn this folder into a git repo wired to a GitHub
# remote, using a chosen SSH key. Safe to re-run; it skips steps already done.
#
# Nothing personal is baked into this script. Everything is either derived
# at runtime or read from environment variables you set when you run it.
#
# Config (all optional, sensible defaults shown):
#   REPO_URL        git remote URL        default: git@github.com:gitjayson/discord-image-grabber.git
#   SSH_KEY         private key to use     default: $HOME/.ssh/pengo
#   GIT_USER_NAME   commit author name     default: your existing git config
#   GIT_USER_EMAIL  commit author email    default: your existing git config
#
# Example:
#   REPO_URL=git@github.com:me/myrepo.git SSH_KEY=~/.ssh/id_ed25519 ./setup_git.sh
#
# Prereq: create the empty repo on github.com first (no README/license/.gitignore).

set -euo pipefail

# --- Config (override via environment variables) ---
REPO_URL="${REPO_URL:-git@github.com:gitjayson/discord-image-grabber.git}"
SSH_KEY="${SSH_KEY:-$HOME/.ssh/pengo}"

# Run from the directory this script lives in, so it works no matter where
# the repo is cloned or where the script is called from.
cd "$(dirname "$(readlink -f "$0")")"

# Make every git operation in this script use the chosen key.
if [[ ! -f "$SSH_KEY" ]]; then
  echo "Error: SSH key not found at $SSH_KEY" >&2
  echo "Set SSH_KEY=/path/to/key, or create the key first." >&2
  exit 1
fi
export GIT_SSH_COMMAND="ssh -i ${SSH_KEY} -o StrictHostKeyChecking=accept-new"

# 1. Init repo
if [[ ! -d .git ]]; then
  echo "[1/6] git init"
  git init -q
else
  echo "[1/6] git repo already initialized"
fi

# 2. Commit identity, scoped to this repo only (not global).
#    Only set what you explicitly pass in; otherwise fall back to your
#    existing git config so nothing personal has to live in this file.
echo "[2/6] configuring commit identity (local)"
if [[ -n "${GIT_USER_NAME:-}" ]]; then
  git config user.name "$GIT_USER_NAME"
fi
if [[ -n "${GIT_USER_EMAIL:-}" ]]; then
  git config user.email "$GIT_USER_EMAIL"
fi
if ! git config user.name >/dev/null || ! git config user.email >/dev/null; then
  echo "Warning: no git user.name/user.email set (local or global)." >&2
  echo "Set GIT_USER_NAME and GIT_USER_EMAIL, or configure git globally." >&2
fi

# 3. Branch named main
echo "[3/6] ensuring branch 'main'"
git branch -M main 2>/dev/null || true

# 4. Remote
if git remote get-url origin >/dev/null 2>&1; then
  current="$(git remote get-url origin)"
  if [[ "$current" != "$REPO_URL" ]]; then
    echo "[4/6] updating remote 'origin' from $current to $REPO_URL"
    git remote set-url origin "$REPO_URL"
  else
    echo "[4/6] remote 'origin' already set to $REPO_URL"
  fi
else
  echo "[4/6] adding remote 'origin' -> $REPO_URL"
  git remote add origin "$REPO_URL"
fi

# 5. Initial stage + commit (only if there are no commits yet)
if ! git rev-parse --verify HEAD >/dev/null 2>&1; then
  echo "[5/6] staging files and creating initial commit"
  git add -A
  if git diff --cached --quiet; then
    echo "  nothing to commit (everything ignored?)"
  else
    git commit -q -m "Initial commit: discord-image-grabber"
  fi
else
  echo "[5/6] repo already has commits — skipping initial commit"
fi

# 6. First push (sets upstream)
echo "[6/6] pushing main to origin"
if git push -u origin main; then
  echo
  echo "Done. Repo is live at ${REPO_URL%.git}"
  echo "  (replace git@github.com: with https://github.com/ for the browser URL)"
else
  echo
  echo "Push failed. Common causes:"
  echo "  - The empty repo doesn't exist yet on github.com. Create it: https://github.com/new"
  echo "  - GitHub doesn't have the public half of $SSH_KEY yet."
  echo "    Add ${SSH_KEY}.pub at https://github.com/settings/keys"
  echo "    Test with: ssh -i $SSH_KEY -T git@github.com"
  exit 1
fi
