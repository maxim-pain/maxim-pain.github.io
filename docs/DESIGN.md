# Design rules for this site

The site is styled by a role-based token system rather than per-page hex picks. If you
change anything visual, follow these six rules and it will stay coherent.

The full source of these rules lives locally in `.claude/skills/ui-color-system/`
(gitignored — it is internal). This file is the publishable summary and is enough to work
from.

## 1. Colour is assigned by role, never as a raw hex

Every token that can hold content has an `on-` partner that is guaranteed legible on it.
A button is `background: var(--primary); color: var(--on-primary)` — never a hand-picked
hex with white you hoped would read.

The families, all defined at the top of `assets/style.css`:

| Family | Tokens | Used for |
| --- | --- | --- |
| Surfaces | `--surface`, `--surface-container`, `--surface-container-high`, `--surface-container-highest` | backgrounds, in elevation steps |
| Text | `--on-surface`, `--on-surface-secondary`, `--on-surface-tertiary` | text and icons over surfaces |
| Primary | `--primary`, `--on-primary`, `--primary-container`, `--on-primary-container` | **interactive only** — links, buttons, focus, active nav |
| Semantic | `--ok`, `--warn`, `--error` (+ `-container`, `on-`) | **status only** |
| Identity | `--main` (indigo), `--sub` (teal) (+ `-container`, `-fill`, `on-`) | **identity only** — compute core A / core B |
| Lines | `--outline`, `--outline-variant`, `--separator` | borders and hairlines |

First question when colouring anything is "what *role* is this?", not "what colour do I
like?".

## 2. Hierarchy is one colour at graduated opacity

No new gray per level of de-emphasis. Body text is `--on-surface`, supporting text is
`--on-surface-secondary` (~64%), labels and metadata are `--on-surface-tertiary` (~40%).
Chip and input backgrounds come from the `--fill*` tiers. Because every tier derives from
one source colour, the page stays coherent on any surface.

## 3. Depth in dark mode is tone, not shadow

Higher surfaces are *lighter*. A card sits one step up from the page background
(`--surface-container`), a hovered or nested element one step above that. There are no drop
shadows in dark mode — hairline `--outline-variant` borders do the rest.

## 4. Interactions are state-layer overlays

Hover and press are a translucent overlay of the element's own foreground colour at fixed
opacities (`--state-hover` 8%, `--state-pressed` 12%), implemented as a `::after` layer —
not a second background colour per state. Keyboard focus is a 2px `--focus-ring` outline.
Defining this once is what makes every control feel like the same family.

## 5. Saturation is rationed to meaning

The overwhelming majority of the page is neutral surfaces and tiered text. Saturated colour
appears only where it carries meaning:

- **`--primary`** — this is interactive.
- **`--main` / `--sub`** — this belongs to compute core A / core B.
- **`--ok` / `--warn` / `--error`** — this is a status.

Two corollaries that are easy to break:

- Identity colours appear as a **container tint + hairline border + coloured text**, never
  as a solid fill. A solid fill reads "clickable", which is `--primary`'s job.
- Never decorate with a status colour. If something is green it must mean known-good.

## 6. Accessibility floor

The token pairs are contrast-verified: body text ≥ 4.5:1, large/UI text ≥ 3:1. Keep it that
way if you reseed a colour. Never encode meaning by colour alone — every identity chip and
status also carries a text label.

## Structural conventions

- **Mirrored cores.** Wherever the two SoCs appear together, core A is on the **left** in
  indigo and core B on the **right** in teal, with the inter-SoC link as a real element
  *between* them (`.cores` in `style.css`). This is the signature visual of the site.
- **Typography.** IBM Plex Sans for prose and UI, JetBrains Mono for anything numeric,
  label-like, or register-ish — layer tags, chips, eyebrows, dates.
- **Both themes.** Dark is the default; light is a companion palette rebuilt light-first,
  not an inversion. The site follows the OS until the visitor uses the toggle, which is then
  remembered in `localStorage`.
- **Print.** `resume.html` has a print stylesheet that flattens tokens to black-on-white and
  drops the nav, buttons and CTA. Check it with Ctrl-P after editing that page.
- **Motion.** Reveal-on-scroll only, and fully disabled under `prefers-reduced-motion`.
