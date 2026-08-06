#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  Pull the latest version down from GitHub.
#
#      ./pull.sh
#
#  Use this when you edited a file directly on github.com, or when you are
#  working from a second machine. Uncommitted local edits are stashed, the
#  remote commits are applied, then your edits go back on top.
# ─────────────────────────────────────────────────────────────────────────────
. "$(dirname "$0")/scripts/lib.sh"

load_conf
need_repo
setup_auth
sync_remote

step "Fetching $GITHUB_USER/$GITHUB_REPO"
g fetch origin "$BRANCH"

if ! g rev-parse --verify HEAD >/dev/null 2>&1; then
  step "No local history — checking out $BRANCH from GitHub"
  g checkout -b "$BRANCH" "origin/$BRANCH"
  say ""; step "Done."; exit 0
fi

behind="$(g rev-list --count "HEAD..origin/$BRANCH" 2>/dev/null || echo 0)"
ahead="$(g rev-list --count "origin/$BRANCH..HEAD" 2>/dev/null || echo 0)"
dim "local is $ahead commit(s) ahead, $behind behind"

if [ "$behind" = "0" ]; then
  step "Already up to date"
else
  step "Rebasing your work on top of GitHub's"
  if ! g pull --rebase --autostash origin "$BRANCH"; then
    die "Conflict during rebase. Resolve the marked files, then:
    git add <files> && git rebase --continue"
  fi
  dim "$(g log --oneline -3)"
fi

if ! g diff --quiet || ! g diff --cached --quiet; then
  say ""
  warn "You have uncommitted local changes. ./push.sh will include them."
fi
say ""
