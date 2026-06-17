# App icon

Drop the launcher icon here, then regenerate the platform icons.

## What to provide
- **`lull_icon.png`** — a **square PNG, ≥ 1024×1024**, no transparency needed.
  - This becomes the iOS/Android/web/macOS launcher icon.
  - It's also used as the Android **adaptive-icon foreground**, which a circular
    mask crops — so keep the important marks within the centre ~66% (leave a
    safe margin), or provide a separate padded foreground later.

## Generate (after dropping the file in)
```sh
cd app
dart run flutter_launcher_icons
```
This rewrites the native icon assets from `lull_icon.png` (config lives in
`pubspec.yaml` under `flutter_launcher_icons`). The adaptive background is the
brand dark `#0A0E13`.

## Splash
The launch screen is a calm solid colour (light `#F2F1EC` / dark `#0A0E13`) and
needs **no asset**. It's already generated; to change it, edit
`flutter_native_splash` in `pubspec.yaml` and run
`dart run flutter_native_splash:create`.
