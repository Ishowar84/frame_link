import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';

class ResourceManager {
  static const String _windowsAssetPath = 'assets/bin/windows';
  
  static final List<String> _windowsFiles = [
    'AdbWinApi.dll',
    'AdbWinUsbApi.dll',
    'SDL2.dll',
    'adb.exe',
    'avcodec-61.dll',
    'avformat-61.dll',
    'avutil-59.dll',
    'libusb-1.0.dll',
    'scrcpy-server',
    'scrcpy.exe',
    'swresample-5.dll',
  ];

  static Future<String> get localResourcePath async {
    final supportDir = await getApplicationSupportDirectory();
    final resourceDir = Directory(path.join(supportDir.path, 'bin'));
    if (!await resourceDir.exists()) {
      await resourceDir.create(recursive: true);
    }
    return resourceDir.path;
  }

  static Future<void> extractResources() async {
    final targetPath = await localResourcePath;
    
    if (Platform.isWindows) {
      for (final fileName in _windowsFiles) {
        final targetFile = File(path.join(targetPath, fileName));
        
        // In debug mode, we might want to always extract for testing changes, 
        // but for now let's check existence to be efficient.
        if (!await targetFile.exists()) {
          try {
            final byteData = await rootBundle.load('$_windowsAssetPath/$fileName');
            await targetFile.writeAsBytes(byteData.buffer.asUint8List());
            debugPrint('Extracted $fileName to $targetPath');
          } catch (e) {
            debugPrint('Error extracting $fileName: $e');
          }
        }
      }
    }
  }

  /// Force extraction (e.g., after an app update)
  static Future<void> forceExtractResources() async {
    final targetPath = await localResourcePath;
    final dir = Directory(targetPath);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    await extractResources();
  }
}
