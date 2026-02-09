import 'dart:io';
import 'package:path/path.dart' as path;

/// Manages paths to embedded scrcpy and adb binaries
class ResourcePaths {
  static String get basePath {
    if (Platform.isWindows) {
      // 1. Production Mode: Check relative to the .exe location 
      // Structure: Release/frame_link.exe -> Release/data/resources/
      final exePath = Platform.resolvedExecutable;
      final exeDir = path.dirname(exePath);
      final prodPath = path.join(exeDir, 'data', 'resources');
      
      if (Directory(prodPath).existsSync()) {
        return prodPath;
      }

      // 2. Development Mode: Check relative to project root
      // We use Directory.current as a fallback for when running from IDE
      final debugPath = path.join(Directory.current.path, 'windows', 'runner', 'resources');
      if (Directory(debugPath).existsSync()) {
        return debugPath;
      }
      
      // Fallback to prodPath structure even if directory doesn't exist yet (for build time checks)
      return prodPath;
    } else if (Platform.isLinux) {
      return 'linux/flutter/resources';
    } else if (Platform.isMacOS) {
      return 'macos/Runner/resources';
    }
    throw UnsupportedError('Platform not supported');
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

  /// Verify all required binaries exist
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
    
    return 'Missing required files: ${missing.join(', ')}\n'
        'Expected location: $basePath';
  }
}
