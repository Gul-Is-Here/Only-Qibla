# 🕋 Only Qibla

A real-time Qibla compass app with **smart caching** and **instant loading**. Find the Qibla direction anywhere in the world, even offline!

## ✨ Features

### 🎯 Core Features
- **Real-time Compass**: 3D compass with accurate Qibla direction
- **Satellite Map View**: Full world map showing your location and Kaaba
- **Instant Loading**: < 1 second startup with smart caching
- **Offline Support**: Works without internet after first use
- **Background Updates**: Fresh data updates silently every 5 minutes
- **Distance Calculator**: Shows distance to Makkah in kilometers
- **Bearing Display**: Shows precise bearing angle

### 🚀 Smart Caching System
- **First Load**: Fetches GPS location (2-5 seconds)
- **Subsequent Loads**: Instant from cache (< 1 second)
- **Auto-Update**: Background refresh every 5 minutes
- **Manual Refresh**: Force fresh location anytime
- **Offline Ready**: Full functionality without internet

### 📱 User Experience
- **Smooth Onboarding**: Permission requests with explanations
- **Visual Feedback**: Status indicators for online/offline/updating
- **Calibration Guide**: Help for compass accuracy
- **Share Location**: Share Qibla direction with others
- **Nearby Mosques**: Find mosques near you (requires internet)

## 📸 Screenshots

[Add your screenshots here]

## 🔧 Technical Details

### Architecture
- **Flutter SDK**: ^3.10.4
- **Material Design 3**: Modern UI components
- **Smart Caching**: Background updates with instant loading
- **Service Layer**: Clean separation of concerns

### Key Dependencies
```yaml
flutter_qiblah: ^3.1.0+1      # Qibla calculation & compass
geolocator: ^13.0.2            # GPS location
google_maps_flutter: ^2.10.0  # Satellite map view
permission_handler: ^11.3.1    # Permission management
shared_preferences: ^2.3.3     # Local caching
share_plus: ^10.1.4            # Sharing functionality
url_launcher: ^6.3.1           # External links
```

### Services
- **OfflineLocationService**: Smart location caching with background updates
- **ConnectivityService**: Internet connectivity detection

## 🎨 Features in Detail

### Real-Time Compass
- 3D rotating compass needle
- Accurate bearing calculation
- Smooth animations
- Calibration assistance
- Works with device sensors

### Satellite Map View
- Full world satellite imagery
- Custom Kaaba marker (green dome)
- User location marker
- Dashed geodesic line showing shortest path
- Mini world map inset
- Auto-fit to show both locations
- Satellite/Normal map toggle

### Smart Caching
See [SMART_CACHING.md](SMART_CACHING.md) for complete documentation.

**How it works:**
1. First use: Fetches and caches GPS location
2. Subsequent uses: Loads cached instantly, updates in background
3. Every 5 minutes: Silent background update (if online)
4. Manual refresh: Force fresh location anytime

**Benefits:**
- ⚡ **Instant startup** - No waiting
- 📶 **Works offline** - Uses cached location
- 🔄 **Always fresh** - Background updates
- 🔋 **Battery efficient** - Smart update intervals

### Offline Mode
See [OFFLINE_MODE.md](OFFLINE_MODE.md) for details.

**Works Offline:**
✅ Real-time compass
✅ Qibla direction
✅ Distance calculation
✅ Bearing angle
✅ All core features

**Requires Internet:**
❌ Satellite map view
❌ Nearby mosques
❌ Background location updates

## 🚀 Getting Started

### Prerequisites
- Flutter SDK ^3.10.4 or higher
- Android Studio / Xcode (for platform builds)
- Google Maps API key (included)

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/Gul-Is-Here/Only-Qibla.git
cd Only-Qibla
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Run the app**
```bash
flutter run
```

### Build for Release

**Android APK:**
```bash
flutter build apk --release
```

**Android App Bundle:**
```bash
flutter build appbundle --release
```

**iOS:**
```bash
flutter build ios --release
```

## 🔑 Permissions

The app requires the following permissions:

### Android
- **Location**: Required for GPS positioning
- **Internet**: Optional (for maps and updates)

### iOS
- **Location When In Use**: Required for GPS positioning
- **Notifications**: Optional (for prayer time alerts)

## 📖 Documentation

- [SMART_CACHING.md](SMART_CACHING.md) - Complete caching system documentation
- [OFFLINE_MODE.md](OFFLINE_MODE.md) - Offline functionality guide
- [.github/copilot-instructions.md](.github/copilot-instructions.md) - Development guidelines

## 🏗️ Project Structure

```
lib/
├── main.dart                           # App entry point
├── screens/
│   ├── qibla_screen.dart              # Main compass/map screen
│   └── onboarding_screen.dart         # Permission onboarding
├── widgets/
│   ├── qibla_compass.dart             # 3D compass widget
│   ├── qibla_map_view.dart            # Satellite map widget
│   ├── location_error_widget.dart     # Error handling
│   └── compass_calibration_widget.dart # Calibration guide
└── services/
    ├── offline_location_service.dart   # Smart caching service
    └── connectivity_service.dart       # Internet detection
```

## 🧪 Testing

Run unit and widget tests:
```bash
flutter test
```

Run analyzer:
```bash
flutter analyze
```

## 🐛 Troubleshooting

### Location Not Loading
1. Grant location permission
2. Enable device GPS
3. Check internet connection (first use)
4. Try manual refresh button

### Compass Inaccurate
1. Calibrate compass (menu → Calibrate)
2. Move away from magnetic interference
3. Hold device flat
4. Clear cache and refresh

### App Loading Slow
- First launch requires GPS fetch (2-5 seconds)
- Subsequent launches should be instant (< 1 second)
- Check if background updates are enabled

## 📝 License

[Add your license here]

## 👥 Contributors

- [Your Name](https://github.com/Gul-Is-Here)

## 🙏 Acknowledgments

- Flutter team for amazing framework
- flutter_qiblah package maintainers
- Google Maps Platform
- Muslim community for feedback

## 📧 Contact

For issues, questions, or suggestions:
- GitHub Issues: [Create an issue](https://github.com/Gul-Is-Here/Only-Qibla/issues)
- Email: [Your email]

---

**Made with ❤️ for the Muslim community**

🕋 May Allah guide us all to the straight path

