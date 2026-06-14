# Lull

Lull is a calm productivity app: a pomodoro and three daily essentials, nothing more. You choose what matters today, you sit with one timer, and the app rewards real focus — quietly, and only when it actually happened. There are no streak scolds, no badges shouting for attention. Just a steady place to work.

**Status:** pre-release, milestone M0.

## Stack

- **Flutter everywhere** — one codebase for web, macOS, iOS, and Android.
- **Supabase** — Postgres, auth, and edge functions; the server is the source of truth for anything earned.

## Repository layout

| Path | Contents |
|---|---|
| `app/` | The Flutter app (package `lull`) |
| `supabase/` | Migrations, edge functions, and database tests |
| `DESIGN.md` | Product and technical design — start here |

## Quickstart

```sh
cd app
flutter run -d chrome   # or: flutter run -d macos
```

For the full picture — what we're building and why — read [DESIGN.md](DESIGN.md).

## Principles

- **Server-authoritative rewards.** Focus is verified and rewarded by the backend, never claimed by the client. What you earned is what you did.
- **Anchor-based timers.** Timers are computed from fixed timestamps, not ticking counters — a backgrounded tab or a sleeping laptop never lies about elapsed time.
- **Beauty as a feature.** Calm is not a coat of paint. The interface earns quiet through restraint, and we treat that as a requirement, not a polish pass.
