import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/device_model.dart';
import '../utils/resource_paths.dart';

/// Service to interact with Android Debug Bridge (ADB)
class AdbService extends ChangeNotifier {
  List<AndroidDevice> _devices = [];
  String? _error;
  bool _isScanning = false;
  Timer? _autoRefreshTimer;

  List<AndroidDevice> get devices => List.unmodifiable(_devices);
  String? get error => _error;
  bool get isScanning => _isScanning;
  bool get hasDevices => _devices.isNotEmpty;

  /// Start auto-refresh every 2 seconds
  void startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => refreshDevices(silent: true),
    );
  }

  /// Stop auto-refresh
  void stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }

  @override
  void dispose() {
    stopAutoRefresh();
    super.dispose();
  }

  /// Scan for connected Android devices
  Future<void> refreshDevices({bool silent = false}) async {
    if (!silent) {
      _isScanning = true;
      _error = null;
      notifyListeners();
    }

    try {
      final adbPath = ResourcePaths.adbExe;
      
      // Run 'adb devices -l' to get device list with details
      final result = await Process.run(
        adbPath,
        ['devices', '-l'],
        runInShell: true,
      );

      if (result.exitCode != 0) {
        throw Exception('ADB command failed: ${result.stderr}');
      }

      final output = result.stdout.toString();
      final lines = output.split('\n');

      final List<AndroidDevice> newDevices = [];

      for (final line in lines) {
        final trimmed = line.trim();
        // Skip empty lines and the header
        if (trimmed.isEmpty || trimmed.startsWith('List of devices')) {
          continue;
        }

        try {
          final device = AndroidDevice.fromAdbLine(trimmed);
          if (device.isConnected) {
            // Try to get additional info
            final enriched = await _enrichDeviceInfo(device);
            newDevices.add(enriched);
          }
        } catch (e) {
          debugPrint('Failed to parse device line: $trimmed - $e');
        }
      }

      _devices = newDevices;
      _error = null;
    } catch (e) {
      _error = 'Failed to scan devices: $e';
      debugPrint(_error);
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  /// Get additional device information
  Future<AndroidDevice> _enrichDeviceInfo(AndroidDevice device) async {
    try {
      final adbPath = ResourcePaths.adbExe;

      // Get Android version
      final versionResult = await Process.run(
        adbPath,
        ['-s', device.serial, 'shell', 'getprop', 'ro.build.version.release'],
        runInShell: true,
      );

      String androidVersion = device.androidVersion;
      if (versionResult.exitCode == 0) {
        androidVersion = versionResult.stdout.toString().trim();
      }

      return device.copyWith(androidVersion: androidVersion);
    } catch (e) {
      debugPrint('Failed to enrich device info: $e');
      return device;
    }
  }

  /// Enable TCP/IP mode on device
  Future<String?> enableWireless(String deviceSerial) async {
    try {
      final adbPath = ResourcePaths.adbExe;

      // Enable TCP/IP on port 5555
      final tcpipResult = await Process.run(
        adbPath,
        ['-s', deviceSerial, 'tcpip', '5555'],
        runInShell: true,
      );

      if (tcpipResult.exitCode != 0) {
        throw Exception('Failed to enable TCP/IP: ${tcpipResult.stderr}');
      }

      // Wait a bit for the service to start
      await Future.delayed(const Duration(milliseconds: 500));

      // Get device IP address
      final ipResult = await Process.run(
        adbPath,
        [
          '-s',
          deviceSerial,
          'shell',
          'ip',
          '-f',
          'inet',
          'addr',
          'show',
          'wlan0'
        ],
        runInShell: true,
      );

      if (ipResult.exitCode != 0) {
        throw Exception('Failed to get IP address: ${ipResult.stderr}');
      }

      final output = ipResult.stdout.toString();
      final ipMatch = RegExp(r'inet\s+(\d+\.\d+\.\d+\.\d+)').firstMatch(output);

      if (ipMatch == null) {
        throw Exception('Could not find IP address. Is Wi-Fi enabled?');
      }

      return ipMatch.group(1);
    } catch (e) {
      _error = 'Failed to enable wireless: $e';
      notifyListeners();
      return null;
    }
  }

  /// Connect to device wirelessly with custom port
  Future<bool> connectWireless(String ip, {int port = 5555}) async {
    try {
      final adbPath = ResourcePaths.adbExe;
      final address = '$ip:$port';

      debugPrint('Connecting to wireless device: $address');
      final result = await Process.run(
        adbPath,
        ['connect', address],
        runInShell: true,
      );

      final output = result.stdout.toString();
      final success = output.contains('connected') || output.contains('already connected');

      if (success) {
        // Refresh device list after connection
        await Future.delayed(const Duration(milliseconds: 1000));
        await refreshDevices();
      } else {
        throw Exception('Connection failed: $output');
      }

      return success;
    } catch (e) {
      _error = 'Failed to connect wirelessly: $e';
      notifyListeners();
      return false;
    }
  }

  /// Pair a device using Android 11+ Wireless Debugging pairing code
  Future<bool> pairDevice(String address, String pairingCode) async {
    try {
      final adbPath = ResourcePaths.adbExe;

      debugPrint('Pairing with device at $address using code $pairingCode');
      
      // result = adb pair [ip:port] [pairing_code]
      final result = await Process.run(
        adbPath,
        ['pair', address, pairingCode],
        runInShell: true,
      );

      if (result.exitCode != 0) {
        throw Exception('Pairing failed: ${result.stderr}');
      }

      final output = result.stdout.toString();
      if (output.contains('Successfully paired')) {
        return true;
      } else {
        throw Exception('Pairing failed: $output');
      }
    } catch (e) {
      _error = 'Pairing error: $e';
      notifyListeners();
      return false;
    }
  }

  /// Disconnect wireless device
  Future<bool> disconnectWireless(String deviceSerial) async {
    try {
      final adbPath = ResourcePaths.adbExe;

      final result = await Process.run(
        adbPath,
        ['disconnect', deviceSerial],
        runInShell: true,
      );

      await Future.delayed(const Duration(milliseconds: 300));
      await refreshDevices();

      return result.exitCode == 0;
    } catch (e) {
      _error = 'Failed to disconnect: $e';
      notifyListeners();
      return false;
    }
  }

  /// Restart ADB server (useful for troubleshooting)
  Future<bool> restartAdbServer() async {
    try {
      final adbPath = ResourcePaths.adbExe;

      // Kill server
      await Process.run(adbPath, ['kill-server'], runInShell: true);
      
      // Wait a bit
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Start server
      final result = await Process.run(
        adbPath,
        ['start-server'],
        runInShell: true,
      );

      if (result.exitCode == 0) {
        await refreshDevices();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Failed to restart ADB: $e';
      notifyListeners();
      return false;
    }
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
