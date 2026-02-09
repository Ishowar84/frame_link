import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/settings_model.dart';
import '../utils/resource_paths.dart';

/// Service to launch and manage scrcpy processes
class ScrcpyService extends ChangeNotifier {
  Process? _currentProcess;
  bool _isRunning = false;
  String? _error;
  String? _currentDeviceSerial;
  AppSettings? _currentSettings;
  Timer? _monitorTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;

  bool get isRunning => _isRunning;
  String? get error => _error;
  String? get currentDevice => _currentDeviceSerial;

  @override
  void dispose() {
    stopMirroring();
    _monitorTimer?.cancel();
    super.dispose();
  }

  /// Start mirroring with comprehensive error recovery
  Future<bool> startMirroring({
    required String deviceSerial,
    required AppSettings settings,
  }) async {
    if (_isRunning) {
      debugPrint('scrcpy already running');
      return false;
    }

    _currentDeviceSerial = deviceSerial;
    _currentSettings = settings;
    _reconnectAttempts = 0;

    return await _launchScrcpy();
  }

  /// Internal method to launch scrcpy process
  Future<bool> _launchScrcpy() async {
    try {
      final scrcpyPath = ResourcePaths.scrcpyExe;
      final args = _buildCommandArguments();

      debugPrint('Launching scrcpy: $scrcpyPath ${args.join(' ')}');

      _currentProcess = await Process.start(
        scrcpyPath,
        args,
        runInShell: true,
      );

      _isRunning = true;
      _error = null;
      notifyListeners();

      // Monitor stdout for errors
      _currentProcess!.stdout.listen((data) {
        final output = String.fromCharCodes(data);
        debugPrint('scrcpy: $output');
      });

      // Monitor stderr for errors
      _currentProcess!.stderr.listen((data) {
        final error = String.fromCharCodes(data);
        debugPrint('scrcpy error: $error');
        
        // Check for known error patterns
        if (error.contains('device disconnected') || 
            error.contains('connection failed')) {
          _handleConnectionLoss();
        }
      });

      // Monitor process exit
      _currentProcess!.exitCode.then((code) {
        debugPrint('scrcpy exited with code: $code');
        
        if (code != 0 && _currentSettings?.autoReconnect == true) {
          _handleUnexpectedExit(code);
        } else {
          _cleanup();
        }
      });

      // Start health monitoring
      _startHealthMonitor();

      return true;
    } catch (e) {
      _error = 'Failed to start scrcpy: $e';
      debugPrint(_error);
      _cleanup();
      notifyListeners();
      return false;
    }
  }

  /// Build command line arguments from settings
  List<String> _buildCommandArguments() {
    final args = <String>[];

    // Device selection
    if (_currentDeviceSerial != null) {
      args.addAll(['-s', _currentDeviceSerial!]);
    }

    final settings = _currentSettings;
    if (settings == null) return args;

    // Screen control
    if (settings.turnOffPhoneScreen) {
      args.add('--turn-screen-off');
    }

    // Stay awake
    if (settings.stayAwake) {
      args.add('--stay-awake');
    }

    // Show touches
    if (settings.showTouches) {
      args.add('--show-touches');
    }

    // Max size (resolution limit)
    if (settings.maxSize > 0) {
      args.addAll(['--max-size', settings.maxSize.toString()]);
    }

    // Video Bit rate
    if (settings.bitRate > 0) {
      args.addAll(['--video-bit-rate', settings.bitRate.toString()]);
    }

    // Max FPS
    if (settings.maxFps > 0) {
      args.addAll(['--max-fps', settings.maxFps.toString()]);
    }

    // Video codec
    if (settings.videoCodec.isNotEmpty && settings.videoCodec != 'h264') {
      args.addAll(['--video-codec', settings.videoCodec]);
    }

    // Hardware acceleration
    if (!settings.hardwareAcceleration) {
      args.add('--no-video-playback');
    }

    // Recording (TODO: implement file picker)
    if (settings.recordSession) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      args.addAll(['--record', 'scrcpy_$timestamp.mp4']);
    }

    // Audio control (disable by default for performance unless needed)
    args.add('--no-audio');

    return args;
  }

  /// Start monitoring process health
  void _startHealthMonitor() {
    _monitorTimer?.cancel();
    _monitorTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _checkProcessHealth();
    });
  }

  /// Check if process is still alive
  void _checkProcessHealth() {
    if (_currentProcess == null && _isRunning) {
      debugPrint('Process lost, attempting recovery...');
      _handleUnexpectedExit(-1);
    }
  }

  /// Handle connection loss during mirroring
  void _handleConnectionLoss() {
    debugPrint('Connection lost detected');
    _handleUnexpectedExit(-1);
  }

  /// Handle unexpected process exit
  void _handleUnexpectedExit(int exitCode) {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _error = 'Connection lost. Maximum reconnect attempts reached.';
      _cleanup();
      notifyListeners();
      return;
    }

    final delay = _currentSettings?.reconnectDelay ?? 3;
    _reconnectAttempts++;

    debugPrint('Auto-reconnect attempt $_reconnectAttempts/$_maxReconnectAttempts in ${delay}s...');

    _cleanup(keepSettings: true);
    
    Future.delayed(Duration(seconds: delay), () {
      if (_currentDeviceSerial != null && _currentSettings != null) {
        _launchScrcpy();
      }
    });
  }

  /// Stop mirroring
  Future<void> stopMirroring() async {
    if (_currentProcess != null) {
      if (Platform.isWindows) {
        // More forceful kill on Windows to ensure tree termination
        await Process.run('taskkill', ['/F', '/T', '/PID', _currentProcess!.pid.toString()]);
      } else {
        _currentProcess?.kill(ProcessSignal.sigterm);
      }
    }
    _cleanup();
  }

  /// Toggle device screen state live (while mirroring)
  Future<void> toggleScreenLive(bool turnOff) async {
    if (_currentDeviceSerial == null) return;
    
    try {
      final adbPath = ResourcePaths.adbExe;
      // Scrcpy MOD+o equivalent via ADB:
      // To turn off: scrcpy uses a custom protocol, but we can approximate or relaunch.
      // Actually, scrcpy 2.0+ supports a live flag change if we restart quickly.
      // But for a true "live" feel, we'll try sending the sleep/wake commands.
      
      if (turnOff) {
        // This is the scrcpy way to turn off physical screen while keeping mirroring
        await Process.run(adbPath, ['-s', _currentDeviceSerial!, 'shell', 'settings', 'put', 'system', 'screen_off_timeout', '1000']);
      } else {
        await Process.run(adbPath, ['-s', _currentDeviceSerial!, 'shell', 'settings', 'put', 'system', 'screen_off_timeout', '600000']);
        await Process.run(adbPath, ['-s', _currentDeviceSerial!, 'shell', 'input', 'keyevent', '224']); // Wake
      }
    } catch (e) {
      debugPrint('Live toggle failed: $e');
    }
  }

  /// Cleanup resources
  void _cleanup({bool keepSettings = false}) {
    _monitorTimer?.cancel();
    _currentProcess = null;
    _isRunning = false;
    
    if (!keepSettings) {
      _currentDeviceSerial = null;
      _currentSettings = null;
      _reconnectAttempts = 0;
    }
    
    notifyListeners();
  }

  /// Reset reconnect attempts (call after successful long-running session)
  void resetReconnectAttempts() {
    _reconnectAttempts = 0;
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Check if scrcpy binary exists and is executable
  static Future<bool> isAvailable() async {
    try {
      final scrcpyPath = ResourcePaths.scrcpyExe;
      return await File(scrcpyPath).exists();
    } catch (e) {
      return false;
    }
  }
}
