# maxim-pain.github.io

Personal site and resume for Max Pain — embedded systems tech lead. Plain HTML, CSS and JS.
No build step, no dependencies, no framework. Lives at <https://maxim-pain.github.io>.

```
index.html            home — headline, portrait, stat strip, "what I am proudest of", AI, technologies
projects.html         selected work — AR glasses platform in depth, GM build framework,
                      AV central compute, EVA avionics, Munters IoT platform
resume.html           full resume, 11 roles across 25 years — prints to a clean 5-page PDF
contact.html          email / phone / LinkedIn / GitHub
404.html              styled not-found page (GitHub Pages serves this automatically)

assets/style.css      the whole design system — role-based tokens, dark + light
assets/main.js        theme toggle, scroll reveal, active nav, print button
assets/max-pain.jpg   headshot (home hero + resume header)
assets/favicon.svg    the dual-core mark

.nojekyll             tells GitHub Pages to serve files verbatim (see below)
robots.txt            allows crawling, points at the sitemap
sitemap.xml           the four real pages
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

Edit a file, save, reload. Responses carry no-cache headers so you never look at a stale
stylesheet. `Ctrl-C` to stop. Needs nothing but `python3`.

---

## First-time setup (once per machine)

### 1. Make a Personal Access Token

GitHub has not accepted account passwords over HTTPS since 2021, so "username + password" is
not an option — you need a **Personal Access Token**, used *as* the password.

1. <https://github.com/settings/tokens?type=beta> → **Generate new token**
2. **Repository access** → *Only select repositories* → `maxim-pain.github.io`
3. **Permissions** → *Repository permissions* → **Contents: Read and write**
4. Expiration: 90 days is a reasonable default
5. **Generate token** and copy it — GitHub shows it exactly once

### 2. Fill in your config

```bash
cp deploy.conf.example deploy.conf
chmod 600 deploy.conf
nano deploy.conf          # paste username + token
```

`deploy.conf` is gitignored, so it is never committed or pushed. The scripts additionally
refuse to push if they ever find it tracked by git.

### 3. Run setup

```bash
./setup.sh
```

Checks your token against the GitHub API, says specifically what is wrong if it fails,
initialises the repo, points `origin` at GitHub and makes the first commit. It does not push.

---

## Publish

```bash
./push.sh                        # auto message
./push.sh "rewrote the resume"   # your own message
```

Stages everything, commits, rebases on anything new from GitHub, pushes. Live in about a
minute at <https://maxim-pain.github.io>.

```bash
./pull.sh                        # bring down edits made on github.com
```

---

## What GitHub Pages actually does (and what this repo does about it)

Pages is a **static file host** — no server-side code, no custom headers, no redirects. This
site is static HTML/CSS/JS, so it is fully compatible. The specifics that matter:

| Pages behaviour | How this repo handles it |
| --- | --- |
| **Runs your repo through Jekyll by default**, which can transform or skip files (anything starting with `_` or `.` is dropped) | **`.nojekyll`** at the repo root turns Jekyll off entirely — files are served byte-for-byte, and builds are faster |
| Repo named `<user>.github.io` serves at the **domain root**; a project repo serves under `/<repo>/` | All links are **relative** (`assets/style.css`, not `/assets/style.css`), so the site works either way |
| Paths are **case-sensitive** on the server even if your local filesystem is not | Everything is lowercase and verified to match |
| **HTTPS only** — mixed content is blocked | The only external resource is Google Fonts over HTTPS |
| Serves **`404.html`** for unknown paths | Included, styled to match, `noindex` |
| No custom cache headers | `serve.sh` sets no-cache locally only; nothing depends on it in production |
| Limits: 1 GB repo, 100 MB per file, 100 GB/month soft bandwidth | The whole site is ~270 KB |
| Pages is enabled automatically for a `<user>.github.io` repo | Nothing to configure — if it 404s after a few minutes, check **Settings → Pages**: *Deploy from a branch*, branch `main`, folder `/ (root)` |

Build status: <https://github.com/maxim-pain/maxim-pain.github.io/actions>

**The site also works with JavaScript switched off.** The scroll-reveal effect only hides
content when the `js` class is present on `<html>`, which the inline head script sets. If JS
never runs — blocked, broken, or a crawler that does not execute it — every element renders
visible instead of the page appearing blank. Verified by stripping all JS and rendering.

---

## Where the token lives

The scripts never write the token into `.git/config`, never put it in the remote URL, and
never pass it as a command-line argument (where `ps aux` would expose it). It is handed to git
through a short-lived `GIT_ASKPASS` helper in a `mktemp` file, deleted when the script exits.
`git remote -v` shows a clean `https://github.com/...` URL.

If a token leaks: revoke it at <https://github.com/settings/tokens> and generate a new one.

---

## Editing the content

The site is built from your LinkedIn export, your CV (v0.1.7) and the AR-glasses brief. Two
facts are **inferred rather than sourced**, both marked with an `EDIT:` comment in
`resume.html` and appearing nowhere else on the site:

1. The **Snke XR start year** (`2025 — present`)
2. The **Baxter Healthcare end year** (`2024 — 2025`)

Correct those two and the whole site is accurate.

Deliberately kept off the public site: silicon part numbers and product names for the current
AR platform, internal repo paths, and port mappings. The site describes the *work* ("primary
SoC", "secondary SoC") without publishing the platform. Everything about GM, Baxter, Elbit,
BVR and the rest comes from your own CV, so it is already public.

Where to add things as you go:

- **New achievement** → an `.ach` block in `index.html` §01. Keep every one to a concrete
  outcome with a number or a "first" — never a duty.
- **New project write-up** → a numbered section in `projects.html`, same `.ach` pattern.
- **New role** → a `.tl-item` in `resume.html`. Recent roles get bullets and a `.tl-stack`
  tech line; older ones use `.tl-item.is-brief` with a single paragraph.

## Changing how it looks

Read [docs/DESIGN.md](docs/DESIGN.md) first. Short version: colour is assigned by role, not by
hex; the tokens are at the top of `assets/style.css`; saturated colour appears only when it
means something (`--primary` = interactive, `--main`/`--sub` = which compute core,
`--ok`/`--warn`/`--error` = status). Both themes are maintained — if you touch one, check the
other with the toggle in the nav. After editing `resume.html`, check the print layout with
Ctrl-P; the print stylesheet flattens the palette to black-on-white and collapses chip grids
into flowing text so the PDF stays tight.

Local design skills live in `.claude/skills/` (gitignored, never published) so any Claude Code
session in this repo picks up the same rules.
