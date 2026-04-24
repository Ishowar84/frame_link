# FrameLink - Android Screen Mirroring

A beautiful, feature-rich GUI wrapper for [scrcpy](https://github.com/Genymobile/scrcpy) built with Flutter.

## 📥 Downloads
You can find the latest **Windows** and **Linux** versions on our [**Releases Page**](../../releases/latest).

1. Go to the [**Releases Page**](../../releases/latest).
2. Under **Assets**, download the `.zip` file for your platform.
3. **For Linux**: Unzip the folder and run `./setup_linux.sh` first to install dependencies.

## ✨ Features

### 🎯 Core Features
- ✅ **One-Click Mirroring**: Start mirroring with a single click
- ✅ **Wireless Connection**: Connect via Wi-Fi with QR code support
- ✅ **Auto-Reconnect**: Automatically reconnect if connection drops (fixes "stops working" issue)
- ✅ **Turn Off Phone Screen**: Save battery and privacy
- ✅ **Multiple Devices**: Manage multiple Android devices

### 🔧 Advanced Features
- Video quality control (resolution, bitrate, FPS)
- Hardware acceleration
- Touch visualization
- Stay awake mode
- Auto-save settings
- Beautiful dark theme UI

## 📦 Zero-Setup Portability
FrameLink is designed to be **truly portable**. You don't need to manually install scrcpy or ADB.

- **Self-Extracting**: On first launch, the app automatically unpacks the required scrcpy binaries into a safe system folder.
- **Single Binary**: You can share just the `.exe` or the `.msix` and it will work on any Windows computer.

## 📋 Prerequisites
- **Windows**: 10/11
- **Linux**: Any modern distribution (Arch, Ubuntu/Debian, Fedora, etc.)
- **Android device** with USB Debugging enabled
- **USB cable** for initial connection

### Step 2: Install Dependencies

#### Windows
On first launch, the app automatically extracts its own binaries. No manual installation needed.

#### Linux
Run the included setup script to install `scrcpy` and `adb`:
```bash
chmod +x setup_linux.sh
./setup_linux.sh
```

### Step 3: Run the App

```bash
# Debug mode
flutter run -d windows  # On Windows
flutter run -d linux    # On Linux

# Release mode
flutter build windows --release
flutter build linux --release
```

## 📦 Building Installer

To create a Windows installer (MSIX package):

```bash
flutter pub run msix:create
```

The installer will be in `build\windows\x64\runner\Release\`

## 🎮 Usage

### Basic Mirroring
1. Connect your Android device via USB
2. Enable USB Debugging in Developer Options
3. Click "Mirror" on the device card
4. Your phone screen will appear in a new window!

### Wireless Connection
1. Connect device via USB first
2. Click "Wireless" button
3. Follow the 3-step wizard:
   - Enable wireless mode
   - (Optional) Scan the QR code
   - Disconnect USB and click "Connect Wirelessly"
4. Done! Now you can use scrcpy without cables

### Turn Off Phone Screen
1. Enable "Turn off phone screen" in Quick Settings
2. Start mirroring
3. Your phone's physical screen will turn off
4. Content still displays on your PC!

## 🔧 Project Structure

```
lib/
├── main.dart                    # App entry point
├── models/
│   ├── device_model.dart       # Android device data model
│   └── settings_model.dart     # App settings model
├── services/
│   ├── adb_service.dart        # ADB wrapper with auto-refresh
│   ├── scrcpy_service.dart     # scrcpy launcher with auto-reconnect
│   └── settings_service.dart   # Settings persistence
├── screens/
│   ├── home_screen.dart        # Main device list & controls
│   ├── wireless_setup_screen.dart  # Wireless connection wizard
│   └── settings_screen.dart    # App settings
└── utils/
    └── resource_paths.dart     # Binary path resolution
```

## 🐛 Troubleshooting

### "No devices connected"
- Make sure USB Debugging is enabled
- Try a different USB cable/port
- Click "Restart ADB" in the error dialog

### "scrcpy stops working"
- Enable "Auto-reconnect" in Quick Settings (enabled by default)
- The app will automatically attempt to reconnect up to 5 times
- Check if your phone has aggressive battery saving enabled

### "Resources not found"
- Make sure you copied all files from scrcpy release to `windows/runner/resources/`
- Rebuild the app: `flutter clean && flutter build windows`

## 🎨 Customization

### Change Theme Colors
Edit `lib/main.dart`, find `_buildDarkTheme()`:
```dart
colorScheme: ColorScheme.fromSeed(
  seedColor: const Color(0xFF7C3AED), // Change this!
  brightness: Brightness.dark,
),
```

### Adjust Auto-Reconnect Behavior
Edit `lib/services/scrcpy_service.dart`:
```dart
static const int _maxReconnectAttempts = 5; // Change this
```

## 📝 License

This project is a GUI wrapper for scrcpy. 

- **scrcpy**: Apache License 2.0 - Copyright (C) 2018 Genymobile
- **This GUI wrapper**: MIT License

## 🙏 Credits

- [scrcpy](https://github.com/Genymobile/scrcpy) by [@rom1v](https://github.com/rom1v) and Genymobile
- Flutter team for the amazing framework
- All contributors and users!

## 🤝 Contributing

Contributions are welcome! Feel free to:
- Report bugs
- Suggest features
- Submit pull requests

## 📧 Support

If you encounter issues:
1. Check the [scrcpy FAQ](https://github.com/Genymobile/scrcpy/blob/master/FAQ.md)
2. Open an issue with details about your setup

---

**Made with ❤️ using Flutter**
