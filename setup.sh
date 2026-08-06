#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  One-time setup. Run this once on a new machine.
#
#      ./setup.sh
#
#  It initialises the git repo, points it at your GitHub repo, verifies that
#  your token actually works, and makes the first commit. It does NOT push —
#  run ./push.sh for that, so you get to look at things first.
# ─────────────────────────────────────────────────────────────────────────────
. "$(dirname "$0")/scripts/lib.sh"

load_conf
setup_auth

say ""
say "  repo    $GITHUB_USER/$GITHUB_REPO"
say "  branch  $BRANCH"
say "  author  $GIT_NAME <$GIT_EMAIL>"
say "  live at $PAGES_URL"
say ""

# ── 1. does the token work, and does the repo exist? ─────────────────────────
step "Checking your token against GitHub"
if command -v curl >/dev/null 2>&1; then
  code="$(curl -sS -o /dev/null -w '%{http_code}' \
            -H "Authorization: Bearer $GITHUB_TOKEN" \
            -H "Accept: application/vnd.github+json" \
            "https://api.github.com/repos/$GITHUB_USER/$GITHUB_REPO" || echo 000)"
  case "$code" in
    200)
      dim "ok — token is valid and $GITHUB_REPO exists"
      ;;
    404)
      die "Token works, but repo '$GITHUB_USER/$GITHUB_REPO' was not found.

  Either the repo does not exist yet, or your fine-grained token was not
  granted access to it.

  Create it:  https://github.com/new
              Name it exactly: $GITHUB_REPO
              Visibility: Public
              Do NOT add a README or .gitignore (keep it empty)

  Or fix token access:
              https://github.com/settings/tokens?type=beta
              → your token → Repository access → include $GITHUB_REPO"
      ;;
    401|403)
      die "GitHub rejected the token (HTTP $code).

  Common causes:
    • the token was copied with a trailing space or newline
    • it expired
    • it is a fine-grained token without 'Contents: Read and write'
    • it is scoped to different repositories

  Make a fresh one: https://github.com/settings/tokens?type=beta"
      ;;
    000)
      warn "Could not reach api.github.com — skipping the check (offline?)."
      ;;
    *)
      warn "Unexpected response from GitHub API (HTTP $code). Continuing anyway."
      ;;
  esac
else
  warn "curl not found — skipping the token check."
fi

# ── 2. git repo ──────────────────────────────────────────────────────────────
if [ -d "$ROOT/.git" ]; then
  step "Git repo already initialised"
else
  step "Initialising git repo"
  g init -q
  g symbolic-ref HEAD "refs/heads/$BRANCH"
fi

# Keep line endings sane and stop git from nagging about pull strategy.
g config pull.rebase true
g config core.autocrlf input

sync_remote

# ── 3. first commit ──────────────────────────────────────────────────────────
if g rev-parse --verify HEAD >/dev/null 2>&1; then
  step "History already exists — nothing to commit here"
  dim "$(g log --oneline -1)"
else
  step "Making the first commit"
  g add -A
  g commit -q -m "Personal site"
  dim "$(g log --oneline -1)"
fi

# ── 4. safety net ────────────────────────────────────────────────────────────
if g ls-files --error-unmatch deploy.conf >/dev/null 2>&1; then
  die "deploy.conf is staged for commit — that would publish your token.
  Run:  git rm --cached deploy.conf   and check .gitignore."
fi

say ""
step "Done. Next:"
say "    ./serve.sh          # look at it locally first"
say "    ./push.sh \"message\"  # publish to GitHub"
say ""
