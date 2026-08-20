# bulky

Windows and macOS app that queues a folder of videos and schedules them on YouTube through [Nuke](https://app.nukemarketing.in).

Release downloads always talk to **https://api.nukemarketing.in**. Debug can point at a local server with a `.env` file.

## What you need

1. A Nuke account at [app.nukemarketing.in](https://app.nukemarketing.in)
2. An active plan (trial is fine)
3. A connected YouTube channel on that same website

Open bulky, sign in, and it checks those three things. If anything is missing, it logs you out and opens the website so you can finish setup, then you sign in again.

## What it does

- You pick a folder. Every real video goes into a local queue.
- Nothing publishes immediately. Videos are **scheduled** only.
- Cap: **15 videos per day**, **15 minutes apart**. Add a folder at 2:00 → first slot 2:15, then 2:30, and so on.
- Extra videos start the next day, 24 hours after that first slot.
- The computer needs to stay on until each video is booked on Nuke.
- Failed jobs are not retried.

ffmpeg is downloaded automatically the first time you open the app (needed for still images and 360 stitching).

## Download (unsigned)

GitHub Releases has zips:

- `bulky-<version>-macos.zip` — unzip and drag `bulky.app` to Applications
- `bulky-<version>-windows.zip` — unzip and run `bulky.exe`

These builds are not Apple-notarized or Windows-signed. That is expected:

- **Mac:** right-click the app → Open → Open. Gatekeeper may say the developer is unidentified.
- **Windows:** SmartScreen may warn. Click More info → Run anyway. Google login needs [WebView2](https://developer.microsoft.com/microsoft-edge/webview2/) (already on most Windows 10/11 PCs).

## Run from source (debug)

```
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d macos
flutter run -d windows
```

To hit a local Nuke API instead of production, copy `.env.example` to `.env` and set `NUKE_BASE_URL`. Leave it empty for live. **`.env` is ignored in release builds** — GitHub zips always use production.

```
make macos        # release .app on a Mac
make dist-macos   # zip that .app into dist/
make test
make analyze
```

Windows release zips are built on GitHub Actions (this Mac cannot compile Windows). Tag `v1.0.0` (or later) to publish both platforms.

## Media

Videos (mp4, mov, webm, …) upload as-is. Images become an 8-second clip. Insta360 `.insv` / `.insp` are stitched with ffmpeg (seam can show; no FlowState). `.lrv` is skipped. Max file size is **5 GB**.
