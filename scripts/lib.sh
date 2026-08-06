#!/usr/bin/env bash
# Shared helpers for setup.sh / push.sh / pull.sh / serve.sh.
# Not meant to be run directly — the other scripts source it.

set -euo pipefail

# Repo root = parent of this scripts/ directory.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONF="$ROOT/deploy.conf"

# ── pretty output ────────────────────────────────────────────────────────────
if [ -t 1 ]; then
  C_OK=$'\033[32m'; C_ERR=$'\033[31m'; C_WARN=$'\033[33m'
  C_DIM=$'\033[2m'; C_B=$'\033[1m'; C_OFF=$'\033[0m'
else
  C_OK=''; C_ERR=''; C_WARN=''; C_DIM=''; C_B=''; C_OFF=''
fi
say()  { printf '%s\n' "$*"; }
step() { printf '%s==>%s %s%s%s\n' "$C_OK" "$C_OFF" "$C_B" "$*" "$C_OFF"; }
dim()  { printf '%s%s%s\n' "$C_DIM" "$*" "$C_OFF"; }
warn() { printf '%s!!%s  %s\n' "$C_WARN" "$C_OFF" "$*" >&2; }
die()  { printf '%sERROR%s %s\n' "$C_ERR" "$C_OFF" "$*" >&2; exit 1; }

# ── config ───────────────────────────────────────────────────────────────────
load_conf() {
  if [ ! -f "$CONF" ]; then
    die "No deploy.conf yet.

  Create it and fill in your username + token:

      cp \"$ROOT/deploy.conf.example\" \"$CONF\"
      chmod 600 \"$CONF\"
      \${EDITOR:-nano} \"$CONF\"
"
  fi

  # shellcheck disable=SC1090
  . "$CONF"

  : "${GITHUB_USER:?GITHUB_USER is empty in deploy.conf}"
  : "${GITHUB_REPO:?GITHUB_REPO is empty in deploy.conf}"
  : "${GIT_NAME:=$GITHUB_USER}"
  : "${GIT_EMAIL:=$GITHUB_USER@users.noreply.github.com}"
  : "${BRANCH:=main}"
  : "${PORT:=8000}"

  if [ -z "${GITHUB_TOKEN:-}" ]; then
    die "GITHUB_TOKEN is empty in deploy.conf.

  GitHub does not accept account passwords over HTTPS — you need a Personal
  Access Token. Instructions are in the comments of deploy.conf.example.
  Short version: https://github.com/settings/tokens?type=beta
                 → repo access: $GITHUB_REPO → Contents: Read and write"
  fi

  REMOTE_URL="https://github.com/$GITHUB_USER/$GITHUB_REPO.git"
  PAGES_URL="https://$GITHUB_USER.github.io"
  case "$GITHUB_REPO" in
    "$GITHUB_USER.github.io") ;;                       # user site → bare domain
    *) PAGES_URL="$PAGES_URL/$GITHUB_REPO" ;;          # project site → subpath
  esac

  # Warn if the file is world-readable — it contains a token.
  local perms
  perms="$(stat -c '%a' "$CONF" 2>/dev/null || echo '')"
  case "$perms" in
    600|400) ;;
    '') ;;
    *) warn "deploy.conf is mode $perms. Tightening to 600."; chmod 600 "$CONF" ;;
  esac
}

# ── auth ─────────────────────────────────────────────────────────────────────
# Feed the token to git via GIT_ASKPASS instead of putting it in the remote URL.
# That keeps it out of .git/config, out of `git remote -v`, and out of the
# process list (`ps aux`) where a URL-embedded token would be visible.
ASKPASS_FILE=""
setup_auth() {
  ASKPASS_FILE="$(mktemp)"
  chmod 700 "$ASKPASS_FILE"
  {
    printf '#!/usr/bin/env bash\n'
    printf 'case "$1" in\n'
    printf '  *[Uu]sername*) printf %%s %s ;;\n' "$(printf '%q' "$GITHUB_USER")"
    printf '  *) printf %%s %s ;;\n'             "$(printf '%q' "$GITHUB_TOKEN")"
    printf 'esac\n'
  } > "$ASKPASS_FILE"

  export GIT_ASKPASS="$ASKPASS_FILE"
  export GIT_TERMINAL_PROMPT=0   # fail loudly instead of hanging on a prompt
  trap clear_auth EXIT INT TERM
}
clear_auth() {
  [ -n "$ASKPASS_FILE" ] && rm -f "$ASKPASS_FILE"
  ASKPASS_FILE=""
}

# Run git with the commit identity from deploy.conf, without touching global config.
g() {
  git -C "$ROOT" \
    -c "user.name=$GIT_NAME" \
    -c "user.email=$GIT_EMAIL" \
    -c credential.helper= \
    "$@"
}

need_repo() {
  [ -d "$ROOT/.git" ] || die "Not a git repo yet. Run ./setup.sh first."
}

# Make sure origin exists and points where deploy.conf says it should.
sync_remote() {
  local current
  current="$(g remote get-url origin 2>/dev/null || true)"
  if [ -z "$current" ]; then
    g remote add origin "$REMOTE_URL"
    dim "added remote origin -> $REMOTE_URL"
  elif [ "$current" != "$REMOTE_URL" ]; then
    g remote set-url origin "$REMOTE_URL"
    dim "remote origin updated -> $REMOTE_URL"
  fi
}
