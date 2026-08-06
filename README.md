# maxim-pain.github.io

Personal site and resume for Max Pain. Plain HTML, CSS and JS — no build step, no
dependencies, no framework. Lives at <https://maxim-pain.github.io>.

```
index.html            home — headline, dual-SoC motif, the boot→release stack, skills
projects.html         work — six subsystems + "collaborative work: my part"
resume.html           printable resume (Ctrl-P gives a clean A4 PDF)
contact.html          email / LinkedIn / GitHub

assets/style.css      the whole design system (role-based tokens, dark + light)
assets/main.js         theme toggle, scroll reveal, active nav, print button
assets/favicon.svg    the dual-core mark

docs/DESIGN.md        the six visual rules — read before changing anything visual

setup.sh              one-time: init the repo, verify your token
serve.sh              run it locally
push.sh               commit + publish
pull.sh               fetch changes made on github.com
scripts/lib.sh        shared plumbing for the four scripts
deploy.conf.example   template for your credentials
```

---

## Run it locally

```bash
./serve.sh              # http://localhost:8000, opens your browser
./serve.sh 3000         # different port
```

Edit a file, save, reload. That's the loop — responses are sent with no-cache headers so you
never look at a stale stylesheet. `Ctrl-C` to stop. Needs nothing but `python3`.

This serves the files exactly the way GitHub Pages will, so if it looks right locally it will
look right live.

---

## First-time setup (once per machine)

### 1. Make a Personal Access Token

GitHub stopped accepting account passwords over HTTPS in 2021, so "username + password" is
not an option — you need a **Personal Access Token**, which you then use *as* the password.

1. Go to <https://github.com/settings/tokens?type=beta> → **Generate new token**
2. **Repository access** → *Only select repositories* → `maxim-pain.github.io`
3. **Permissions** → *Repository permissions* → **Contents: Read and write**
4. Expiration: 90 days is a reasonable default (you will need to redo this when it expires)
5. **Generate token**, then copy it — GitHub shows it exactly once

### 2. Fill in your config

```bash
cp deploy.conf.example deploy.conf
chmod 600 deploy.conf
nano deploy.conf          # paste username + token
```

`deploy.conf` is in `.gitignore`, so it never gets committed or pushed. The scripts also
refuse to push if they ever find it tracked by git.

### 3. Run setup

```bash
./setup.sh
```

It checks your token against the GitHub API, tells you specifically what is wrong if it
fails, initialises the repo, points `origin` at GitHub, and makes the first commit. It does
not push — look at the site first.

---

## Publish

```bash
./push.sh                        # auto message: "Update site (2026-08-06 21:14)"
./push.sh "rewrote the resume"   # your own message
```

Stages everything, commits, rebases on anything new from GitHub, then pushes. Live in about
a minute at <https://maxim-pain.github.io>.

## Pull

```bash
./pull.sh
```

For when you edited a file directly on github.com, or you're on a second machine. Local
uncommitted work is stashed and re-applied on top.

### Enabling Pages (once, after the first push)

For a repo named exactly `<username>.github.io` GitHub usually enables Pages automatically.
If the site 404s after a few minutes, check **Settings → Pages**:

- Source: **Deploy from a branch**
- Branch: **main**, folder: **/ (root)**

Build status is at
<https://github.com/maxim-pain/maxim-pain.github.io/actions>.

---

## Where the token lives

The scripts never write the token into `.git/config`, never put it in the remote URL, and
never pass it as a command-line argument (where `ps aux` would expose it). It is handed to
git through a short-lived `GIT_ASKPASS` helper in a `mktemp` file that is deleted when the
script exits. `git remote -v` shows a clean `https://github.com/...` URL.

If a token ever does leak: revoke it at <https://github.com/settings/tokens> and generate a
new one. Revoking is instant and free.

---

## Editing the content

Everything on the site is real content except three things, all marked with an `EDIT:`
comment in the HTML:

1. **`resume.html`** — employment **dates** and job titles (`[20XX] — present`), any earlier
   roles, and the **education** card. These are the only facts the site is guessing at.
2. **`resume.html`** — the spoken-languages chips.
3. **`projects.html`** — grow this page as you ship more subsystems. One `.card.sub-card` per
   subsystem; keep the identity chip honest (`chip-main` = core A, `chip-sub` = core B,
   `chip-both`).

Deliberately kept off the site: silicon part numbers, product names, internal repo paths and
port mappings. The public copy describes the *work* ("primary SoC", "secondary SoC") without
publishing the platform.

## Changing how it looks

Read [docs/DESIGN.md](docs/DESIGN.md) first. Short version: colour is assigned by role, not
by hex; the tokens are all at the top of `assets/style.css`; saturated colour only appears
when it means something (`--primary` = interactive, `--main`/`--sub` = which compute core,
`--ok`/`--warn`/`--error` = status). Both themes are maintained — if you touch one, check
the other with the toggle in the nav.

Local design skills sit in `.claude/skills/` (gitignored, never published) so any Claude Code
session in this repo picks up the same rules.
