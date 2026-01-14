# Assets Folder

## Images

Place your app logo here:
- **logo.png** - Main app logo (recommended size: 512x512px)
- Use PNG format with transparent background
- High resolution for best quality

## Usage

The logo is used in:
1. Splash Screen - Large centered logo
2. Qibla Screen - Title bar logo
3. App Icon - Device home screen icon

## How to Add Logo

1. Save your logo as `logo.png` in this directory: `assets/images/logo.png`
2. The logo should be a PNG file with transparent background
3. Recommended size: 512x512 pixels or higher
4. The app will automatically use it in all screens

## Generate App Icons

After adding your logo, generate app icons using `flutter_launcher_icons`:

```bash
flutter pub add dev:flutter_launcher_icons
```

Then add this to `pubspec.yaml`:

```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/images/logo.png"
  adaptive_icon_background: "#0D1B0F"
  adaptive_icon_foreground: "assets/images/logo.png"
```

Run:
```bash
flutter pub get
flutter pub run flutter_launcher_icons
```

This will generate app icons for both Android and iOS automatically!
