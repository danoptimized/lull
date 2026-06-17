# Data safety / App privacy — answers for the store forms

Use these when filling **Play Console → Data safety** and **App Store Connect →
App Privacy**. They reflect what the app actually does (no ads, no analytics SDK,
no tracking).

## Summary
- Data **collected**: email, user content (essentials/sessions), a device id +
  push token, timezone/settings.
- **Encrypted in transit:** Yes.
- **Deletion:** Users can delete their account + all data in-app (Settings →
  Delete account).
- **Sold / shared for ads/tracking:** No.
- **Used for tracking across apps/sites:** No.

## Google Play — Data safety
Collected, processed, **encrypted in transit**, **deletion available**:

| Category | Data type | Purpose | Linked to user? |
|---|---|---|---|
| Personal info | Email address | Account management, App functionality | Yes |
| App activity | Other user content (essentials, sessions) | App functionality | Yes |
| App info & performance | — (no crash/analytics SDK) | — | — |
| Device or other IDs | Device ID + push token | App functionality (sync, notifications) | Yes |

- Is any data **shared** with third parties? No. (Supabase/Google act as service
  providers/processors, not third-party recipients.)
- Is all data **encrypted in transit**? Yes.
- Can users **request deletion**? Yes — in-app.

## Apple — App Privacy ("nutrition label")
Data **linked to the user**, used for **App Functionality** only (not tracking):

| Type | Item |
|---|---|
| Contact Info | Email Address |
| User Content | Other User Content (essentials/sessions) |
| Identifiers | Device ID |

- **Used to Track You?** No.
- **Used for Third-Party Advertising / Developer's Marketing?** No.
- **Account deletion offered in app?** Yes (required by 5.1.1(v) — implemented).

## Notes
- Google Sign-In is optional; if used, Apple/Google handle the OAuth and we
  receive only the basic account email.
- Firebase Cloud Messaging is used only to deliver notifications you opt into;
  the push token is the only identifier it needs.
