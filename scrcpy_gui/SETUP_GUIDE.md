# 📦 SETUP GUIDE - Complete Instructions

Follow these steps to get scrcpy GUI running on your Windows machine.

## ⚡ Quick Start (5 minutes)

### Step 1: Download scrcpy Binaries

1. Open your browser and go to:
   ```
   https://github.com/Genymobile/scrcpy/releases/latest
   ```

2. Download the file: `scrcpy-win64-vX.X.X.zip` (where X.X.X is the latest version, currently 3.3.4)

3. Extract the ZIP file

4. Copy **ALL FILES** from the extracted folder to:
   ```
   d:\scrcpy_clone\scrcpy\scrcpy_gui\windows\runner\resources\
   ```

   You should see these files after copying:
   - scrcpy.exe
   - scrcpy-server
   - adb.exe
   - AdbWinApi.dll
   - AdbWinUsbApi.dll
   - SDL2.dll
   - avcodec-60.dll
   - avformat-60.dll
   - avutil-58.dll
   - swresample-4.dll
   - swscale-7.dll
   - (and other DLL files)

### Step 2: Verify Resources Folder

Check that the resources folder exists and has files:
```powershell
cd d:\scrcpy_clone\scrcpy\scrcpy_gui
dir windows\runner\resources
```

You should see at least 15+ files including scrcpy.exe and adb.exe

### Step 3: Run the App

```powershell
cd d:\scrcpy_clone\scrcpy\scrcpy_gui
flutter run -d windows
```

That's it! The app should launch.

---

## 🔧 Detailed Setup

### Prerequisites Check

1. **Flutter installed?**
   ```bash
   flutter --version
   ```
   If not installed, get it from: https://docs.flutter.dev/get-started/install/windows

2. **Windows desktop enabled?**
   ```bash
   flutter config --enable-windows-desktop
   flutter doctor
   ```

### Building Release Version

For a standalone .exe:

```bash
cd d:\scrcpy_clone\scrcpy\scrcpy_gui
flutter build windows --release
```

The executable will be at:
```
d:\scrcpy_clone\scrcpy\scrcpy_gui\build\windows\x64\runner\Release\scrcpy_gui.exe
```

You can copy the entire `Release` folder anywhere and it will work!

### Creating Windows Installer (MSIX)

```bash
flutter pub run msix:create
```

This creates a Windows app package that can be installed like any other Windows app.

---

## 📱 Android Device Setup

### Enable USB Debugging

1. On your Android device:
   - Go to **Settings** > **About Phone**
   - Tap **Build Number** 7 times (enables Developer Options)
   - Go back to **Settings** > **Developer Options**
   - Enable **USB Debugging**

2. Connect device via USB

3. You'll see a prompt "Allow USB Debugging?" - tap **Allow**

### For Xiaomi/MIUI Devices

Also enable:
- **USB debugging (Security settings)**
- **Install via USB**

(Found in Developer Options)

---

## 🎯 First Run

1. Launch scrcpy_gui.exe
2. Connect your Android phone via USB
3. You should see your device appear in the list
4. Click **Mirror** button
5. Enjoy!

---

## 🚨 Common Issues

### "No devices connected"

**Solutions:**
1. Make sure USB Debugging is enabled
2. Check USB cable (try different cable/port)
3. Click **Refresh** button
4. Restart ADB from the error dialog

### "Resources not found" error on startup

**Solutions:**
1. Make sure you copied ALL files from scrcpy release to `windows/runner/resources/`
2. The folder should have ~15-20 files
3. Rebuild:
   ```bash
   flutter clean
   flutter pub get
   flutter run -d windows
   ```

### scrcpy window doesn't appear

**Solutions:**
1. Check if phone shows "Allow USB Debugging" prompt - tap Allow
2. Try `adb devices` in terminal to verify connection
3. Restart both phone and computer
4. Check Windows Firewall settings

### "Device unauthorized"

**Solution:**
- Unplug device
- Revoke USB debugging authorizations on phone
- Plug back in and allow when prompted

---

## 🎨 Distribution

### Sharing the App

If you want to share the app with others:

1. Build release version:
   ```bash
   flutter build windows --release
   ```

2. Copy the entire `Release` folder:
   ```
   build\windows\x64\runner\Release\
   ```

3. Share this folder - it contains everything needed!

### Creating Installer

For a professional installer:

1. Install: `flutter pub add msix`
2. Run: `flutter pub run msix:create`
3. Find installer in: `build\windows\x64\runner\Release\`
4. Users can install it like any Windows app!

---

## 💡 Tips

### Run Faster (Skip Debug Checks)

```bash
flutter run -d windows --release
```

### Auto-open DevTools

```bash
flutter run -d windows --dart-define=FLUTTER_WEB_AUTO_DETECT=true
```

### Check for Issues

```bash
flutter analyze
```

---

## 📞 Need Help?

1. Check the main README.md
2. Check scrcpy FAQ: https://github.com/Genymobile/scrcpy/blob/master/FAQ.md
3. Open an issue with your error message and setup details

---

**Happy Mirroring! 🎉**
