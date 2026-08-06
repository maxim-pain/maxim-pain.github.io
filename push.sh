#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  Commit everything and publish to GitHub Pages.
#
#      ./push.sh                      # auto commit message
#      ./push.sh "rewrote the resume"  # your own message
#
#  Safe to run repeatedly. If GitHub has newer commits it rebases yours on top
#  instead of forcing over them.
# ─────────────────────────────────────────────────────────────────────────────
. "$(dirname "$0")/scripts/lib.sh"

load_conf
need_repo
setup_auth
sync_remote

MSG="${1:-Update site ($(date '+%Y-%m-%d %H:%M'))}"

# ── never publish the token ──────────────────────────────────────────────────
if g ls-files --error-unmatch deploy.conf >/dev/null 2>&1; then
  die "deploy.conf is tracked by git — pushing would publish your token.
  Fix it:  git rm --cached deploy.conf && git commit -m 'stop tracking secrets'"
fi

# ── stage + commit ───────────────────────────────────────────────────────────
g add -A
if g diff --cached --quiet; then
  step "No local changes to commit"
else
  step "Committing"
  g -c commit.gpgsign=false commit -q -m "$MSG"
  dim "$(g log --oneline -1)"
fi

# ── bring in anything that happened on GitHub (e.g. web edits) ───────────────
step "Syncing with GitHub"
if g ls-remote --exit-code --heads origin "$BRANCH" >/dev/null 2>&1; then
  if ! g pull --rebase --autostash origin "$BRANCH"; then
    die "Rebase hit a conflict. Resolve the marked files, then:
    git add <files> && git rebase --continue && ./push.sh"
  fi
else
  dim "branch '$BRANCH' does not exist on GitHub yet — this will create it"
fi

# ── push ─────────────────────────────────────────────────────────────────────
step "Pushing to $GITHUB_USER/$GITHUB_REPO ($BRANCH)"
g push -u origin "HEAD:$BRANCH"

say ""
step "Pushed."
say "  Live in ~1 minute at   $PAGES_URL"
say "  Build status:          https://github.com/$GITHUB_USER/$GITHUB_REPO/actions"
say ""
say "  First push ever? Check Settings -> Pages is set to:"
say "    Source: Deploy from a branch | Branch: $BRANCH | Folder: / (root)"
say ""
