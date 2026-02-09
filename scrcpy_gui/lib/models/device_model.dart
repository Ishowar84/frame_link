/// Represents an Android device detected by ADB
class AndroidDevice {
  final String serial;
  final String model;
  final String androidVersion;
  final ConnectionType connectionType;
  final DeviceState state;

  AndroidDevice({
    required this.serial,
    this.model = 'Unknown',
    this.androidVersion = 'Unknown',
    this.connectionType = ConnectionType.usb,
    this.state = DeviceState.device,
  });

  bool get isWireless => 
      connectionType == ConnectionType.wireless || 
      serial.contains(':');

  bool get isConnected => 
      state == DeviceState.device || 
      state == DeviceState.authorizing;

  @override
  String toString() => 'Device($serial, $model, $state)';

  factory AndroidDevice.fromAdbLine(String line) {
    // Parse line like: "ABC123    device product:sdk_gphone64_arm64 model:Pixel_8 device:emu64a"
    final parts = line.split(RegExp(r'\s+'));
    if (parts.isEmpty) {
      throw FormatException('Invalid ADB device line: $line');
    }

    final serial = parts[0];
    final stateStr = parts.length > 1 ? parts[1] : 'offline';
    final state = DeviceState.fromString(stateStr);
    
    String model = 'Unknown';
    String androidVersion = 'Unknown';
    
    // Extract model from extra info
    final modelMatch = RegExp(r'model:([^\s]+)').firstMatch(line);
    if (modelMatch != null) {
      model = modelMatch.group(1)!.replaceAll('_', ' ');
    }

    final connectionType = serial.contains(':') 
        ? ConnectionType.wireless 
        : ConnectionType.usb;

    return AndroidDevice(
      serial: serial,
      model: model,
      androidVersion: androidVersion,
      connectionType: connectionType,
      state: state,
    );
  }

  /// Copy with updated fields
  AndroidDevice copyWith({
    String? serial,
    String? model,
    String? androidVersion,
    ConnectionType? connectionType,
    DeviceState? state,
  }) {
    return AndroidDevice(
      serial: serial ?? this.serial,
      model: model ?? this.model,
      androidVersion: androidVersion ?? this.androidVersion,
      connectionType: connectionType ?? this.connectionType,
      state: state ?? this.state,
    );
  }
}

enum ConnectionType {
  usb,
  wireless,
}

enum DeviceState {
  device,
  offline,
  unauthorized,
  authorizing,
  connecting,
  unknown;

  static DeviceState fromString(String state) {
    switch (state.toLowerCase()) {
      case 'device':
        return DeviceState.device;
      case 'offline':
        return DeviceState.offline;
      case 'unauthorized':
        return DeviceState.unauthorized;
      case 'authorizing':
        return DeviceState.authorizing;
      default:
        return DeviceState.unknown;
    }
  }

  String get displayName {
    switch (this) {
      case DeviceState.device:
        return 'Connected';
      case DeviceState.offline:
        return 'Offline';
      case DeviceState.unauthorized:
        return 'Unauthorized';
      case DeviceState.authorizing:
        return 'Authorizing...';
      case DeviceState.connecting:
        return 'Connecting...';
      case DeviceState.unknown:
        return 'Unknown';
    }
  }
}
