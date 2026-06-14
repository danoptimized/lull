# Lull — Design Language ("calm deep-work")

The north star: **a quiet, pre-dawn room you want to sit in for 25 minutes.**
Dark-first, generous negative space, soft aurora-like gradients, slow breathing motion.
Nothing shouts. Reward moments are the only place we allow gentle celebration.

## Concept

- **Dark theme — "Pre-dawn"** (the hero): deep blue-charcoal surfaces, never pure black.
  Soft teal→lavender aurora accents. Warm off-white text.
- **Light theme — "Morning paper"**: warm paper white, ink text, the same aurora hues
  deepened for contrast.
- Microcopy is lowercase-leaning, brief, kind: "settle in", "three things for today",
  "break — breathe". Never exclamation marks.

## Color tokens

### Dark ("pre-dawn")
| Token | Value | Use |
|---|---|---|
| `bg0` | `#0A0E13` | deepest backdrop (focus screen base) |
| `bg1` | `#10161D` | app surface |
| `bg2` | `#161E27` | raised cards/slots |
| `hairline` | `#232E3A` | borders, dividers (1px, subtle) |
| `textPrimary` | `#E8EDF2` | primary text |
| `textSecondary` | `#9AA7B4` | secondary text |
| `textFaint` | `#5C6975` | hints, disabled |
| `accentTeal` | `#74C7B8` | primary accent ("mist") |
| `accentLavender` | `#8F86E8` | secondary accent ("dusk") |
| `auroraGradient` | `#74C7B8 → #8F86E8` | progress ring, focus glow (135°) |
| `breakWarm` | `#E8A87C` | break-phase hint (peach dusk) |
| `success` | `#E8C476` | celebration gold (soft, desaturated) |
| `danger` | `#D98A8A` | destructive/void (muted rose) |

### Light ("morning paper")
| Token | Value |
|---|---|
| `bg0` | `#F2F1EC` |
| `bg1` | `#F7F6F2` |
| `bg2` | `#FFFFFF` |
| `hairline` | `#E3E1D8` |
| `textPrimary` | `#1F2933` |
| `textSecondary` | `#5A6672` |
| `textFaint` | `#9AA29F` |
| `accentTeal` | `#2E8C7E` |
| `accentLavender` | `#6457C8` |
| `auroraGradient` | `#2E8C7E → #6457C8` |
| `breakWarm` | `#C97B45` |
| `success` | `#B98A2E` |
| `danger` | `#B95E5E` |

Focus-screen backdrop (dark): `bg0` with two large, very-low-opacity radial blooms that
drift/breathe — one teal (top-left-ish), one lavender (bottom-right-ish), ~8–12% opacity,
huge blur radius (pre-baked radial gradients, **never** BackdropFilter).

## Typography — Manrope (bundled, weights 300–800)

| Style | Size / weight / notes |
|---|---|
| `display` (countdown) | 88 / 300 / tabular feel — render digits in fixed-width slots so the clock never jitters |
| `title` | 28 / 700 / -0.5 letter-spacing |
| `heading` | 20 / 600 |
| `body` | 15 / 500 |
| `bodySoft` | 15 / 400, textSecondary |
| `caption` | 13 / 500, textSecondary |
| `label` | 11 / 700 / +0.8 letter-spacing, UPPERCASE, textFaint |

Line-height generous (~1.5 body). The countdown uses `FontFeature.tabularFigures()` AND
fixed-width digit boxes (belt and suspenders).

## Spacing / radii / elevation

- Spacing scale (4-base): `4, 8, 12, 16, 24, 32, 48, 64`. Default screen padding 24.
- Radii: `sm 10`, `md 14`, `lg 20`, `pill 999`. Cards use `lg`.
- Elevation = **soft glow-shadows**, never harsh: low opacity (≤12%), big blur (24–40),
  slight y-offset. Dark theme relies more on surface tone steps than shadows.

## Motion tokens

| Token | Duration | Curve |
|---|---|---|
| `instant` | 80ms | linear |
| `quick` | 160ms | easeOutCubic |
| `calm` | 320ms | easeOutCubic ("gentleOut") |
| `slow` | 640ms | easeInOutCubic |
| `breathing` | 6000ms loop | easeInOutSine, scale 1.00↔1.035 / opacity drift |

Rules: entrances fade+rise 12px with `calm`, staggered 40ms per item. Never bounce,
never overshoot. Reduced-motion (OS or app setting): looping/decorative motion stops
(breathing becomes static), entrances become simple 120ms fades, functional changes snap.

## Screen concepts (M0, mock data)

### Focus screen (`/focus`) — the hero, full-bleed, outside the nav shell
- Backdrop: `bg0` + the two breathing aurora blooms, slowly drifting (6s loop).
- Center: countdown `25:00` in `display` type; ~12px beneath it, the current essential's
  title in `bodySoft` ("finish the proposal draft"); above the countdown a `label`
  ("FOCUS · 1 OF 3").
- A thin (4px) circular **progress ring** (aurora gradient, round caps, faint track)
  wraps the countdown block, ~280px diameter, with a soft outer glow at the progress tip.
- Bottom center: one pill button ("begin" → "pause" visual states only in M0).
- Top-left: a quiet close/back chevron. Top-right: three tiny slot-dots showing today's
  essentials progress (filled/active/empty).
- M0 ships a *visually ticking* mock (local state only); the real anchor engine is M1.

### Today screen (`/today`) — default tab
- Header: "good evening" (time-aware), date line in `caption`, and a small **daily ring**
  (same ProgressRing, 56px) showing overall day progress.
- "three things for today" `label`, then three **slot cards** (`bg2`, radius `lg`):
  task title, target dots (e.g. ●●○ = 2 of 3 pomodoros done — dots are 8px, aurora-filled),
  a subtle checkmark state when complete. One slot rendered empty/ghost ("add your third
  essential", dashed hairline border) to show the state.
- Bottom: full-width pill CTA "begin a focus session" (aurora gradient fill, dark text).
- Cards enter staggered (fade+rise).

### Stats / Settings (`/stats`, `/settings`) — placeholder but composed
- Stats: "your week" placeholder with empty-state copy ("your story starts with one
  session") + a disabled-looking chart silhouette. Settings: theme mode + reduced motion
  toggles (functional, app-local for M0), an "about lull" footer.

### Navigation
- Phone: bottom nav, 3 tabs (today / stats / settings), minimal icons, no labels except
  selected. Focus screen pushes full-screen over everything.
- ≥900px width: slim left rail instead of bottom nav, content max-width ~560px centered.

## Voice

Calm, lowercase-leaning, second person, zero pressure. Examples:
"settle in" · "three things for today" · "break — breathe" · "that's one." ·
"day 4 — gently does it"
