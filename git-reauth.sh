#!/bin/bash

# === git-reauth.sh ===
# Safely rewrite Git history to fix author/committer info.
# Supports multiple mappings: old_email:new_name:new_email
# Usage:
#   ./git-reauth.sh old1@example.com:New Name:new@example.com [more...]

set -euo pipefail

# Check for git repo
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
  echo "❌ Not inside a Git repository."
  exit 1
fi

# Check for arguments
if [ "$#" -eq 0 ]; then
  echo "Usage: $0 old_email1:new_name1:new_email1 [old_email2:new_name2:new_email2 ...]"
  exit 1
fi

echo "🔁 Rewriting Git history for the following mappings:"
for entry in "$@"; do
  echo " - $entry"
done

# Warn about filter-branch
echo
echo "⚠️ WARNING: 'git filter-branch' is considered outdated and can produce mangled history."
echo "It's recommended to use 'git filter-repo' instead:"
echo "  https://github.com/newren/git-filter-repo"
echo
read -p "Do you want to continue using 'git filter-branch'? [y/N] " confirm
confirm=${confirm:-n}
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
  echo "Aborting."
  exit 0
fi

# Warn if refs/original exists
if git show-ref --quiet refs/original; then
  echo
  echo "⚠️ WARNING: A backup already exists in 'refs/original/'."
  echo "This can prevent filter-branch from running again."
  read -p "Delete previous backup and force filter-branch to proceed? [y/N] " confirm2
  confirm2=${confirm2:-n}
  if [[ "$confirm2" == "y" || "$confirm2" == "Y" ]]; then
    echo "Removing refs/original/..."
    git update-ref -d refs/original/refs/heads/*
    git for-each-ref --format="%(refname)" refs/original/ | xargs -n 1 git update-ref -d || true
  else
    echo "Aborting to prevent overwrite. You can manually delete refs/original and retry."
    exit 1
  fi
fi

# Build env filter script
env_filter_script=$(mktemp)
echo "#!/bin/sh" > "$env_filter_script"

for entry in "$@"; do
  OLD_EMAIL=$(echo "$entry" | cut -d: -f1)
  NEW_NAME=$(echo "$entry" | cut -d: -f2)
  NEW_EMAIL=$(echo "$entry" | cut -d: -f3)

  cat >> "$env_filter_script" <<EOF

if [ "\$GIT_COMMITTER_EMAIL" = "$OLD_EMAIL" ]; then
  export GIT_COMMITTER_NAME="$NEW_NAME"
  export GIT_COMMITTER_EMAIL="$NEW_EMAIL"
fi
if [ "\$GIT_AUTHOR_EMAIL" = "$OLD_EMAIL" ]; then
  export GIT_AUTHOR_NAME="$NEW_NAME"
  export GIT_AUTHOR_EMAIL="$NEW_EMAIL"
fi
EOF
done

chmod +x "$env_filter_script"

echo
echo "🛠️ Rewriting history using git filter-branch..."
FILTER_BRANCH_SQUELCH_WARNING=1 git filter-branch -f --env-filter "$(cat "$env_filter_script")" \
  --tag-name-filter cat -- --branches --tags

rm "$env_filter_script"

echo
echo "✅ Done."
echo "🚨 You must now force-push your branches and tags if this repo is shared:"
echo "  git push --force --all"
echo "  git push --force --tags"

