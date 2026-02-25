import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Manages paths to extracted scrcpy and adb binaries
class ResourcePaths {
  static String? _extractedPath;

  /// Initialize the resource paths by finding the extraction directory.
  /// This should be called after ResourceManager.extractResources().
  static Future<void> init() async {
    final supportDir = await getApplicationSupportDirectory();
    _extractedPath = path.join(supportDir.path, 'bin');
  }

  static String get basePath {
    if (_extractedPath != null) {
      return _extractedPath!;
    }
    
    // Fallback/Safety check (should not be hit if init is called)
    if (Platform.isWindows) {
      final debugPath = path.join(Directory.current.path, 'windows', 'runner', 'resources');
      if (Directory(debugPath).existsSync()) {
        return debugPath;
      }
    }
    
    throw StateError('ResourcePaths not initialized. Call init() first.');
  }

  static String get scrcpyExe {
    final exe = Platform.isWindows ? 'scrcpy.exe' : 'scrcpy';
    return path.join(basePath, exe);
  }

  static String get adbExe {
    final exe = Platform.isWindows ? 'adb.exe' : 'adb';
    return path.join(basePath, exe);
  }

  static String get scrcpyServer {
    return path.join(basePath, 'scrcpy-server');
  }

  /// Verify all required binaries exist in the extracted location
  static Future<bool> verifyResources() async {
    try {
      final scrcpyExists = await File(scrcpyExe).exists();
      final adbExists = await File(adbExe).exists();
      final serverExists = await File(scrcpyServer).exists();
      
      return scrcpyExists && adbExists && serverExists;
    } catch (e) {
      return false;
    }
  }

  /// Get human-readable error message if resources are missing
  static Future<String?> getMissingResourcesMessage() async {
    final missing = <String>[];
    
    if (!await File(scrcpyExe).exists()) {
      missing.add('scrcpy executable');
    }
    if (!await File(adbExe).exists()) {
      missing.add('adb executable');
    }
    if (!await File(scrcpyServer).exists()) {
      missing.add('scrcpy-server');
    }
    
    if (missing.isEmpty) return null;
    
    return 'Missing required files in extracted location: ${missing.join(', ')}\n'
        'Location: $basePath';
  }
}
