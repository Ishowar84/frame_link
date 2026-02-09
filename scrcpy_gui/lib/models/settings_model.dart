/// Application settings and preferences
class AppSettings {
  // Mirroring settings
  final bool turnOffPhoneScreen;
  final bool recordSession;
  final bool stayAwake;
  final bool showTouches;
  final int maxSize;
  final int bitRate;
  final int maxFps;
  
  // Connection settings
  final bool autoReconnect;
  final int reconnectDelay;
  
  // Advanced settings
  final bool hardwareAcceleration;
  final String videoCodec;
  final String audioCodec;

  const AppSettings({
    this.turnOffPhoneScreen = false,
    this.recordSession = false,
    this.stayAwake = true,
    this.showTouches = false,
    this.maxSize = 0, // 0 means no limit
    this.bitRate = 8000000, // 8 Mbps
    this.maxFps = 0, // 0 means no limit
    this.autoReconnect = true,
    this.reconnectDelay = 3,
    this.hardwareAcceleration = true,
    this.videoCodec = 'h264',
    this.audioCodec = 'aac',
  });

  AppSettings copyWith({
    bool? turnOffPhoneScreen,
    bool? recordSession,
    bool? stayAwake,
    bool? showTouches,
    int? maxSize,
    int? bitRate,
    int? maxFps,
    bool? autoReconnect,
    int? reconnectDelay,
    bool? hardwareAcceleration,
    String? videoCodec,
    String? audioCodec,
  }) {
    return AppSettings(
      turnOffPhoneScreen: turnOffPhoneScreen ?? this.turnOffPhoneScreen,
      recordSession: recordSession ?? this.recordSession,
      stayAwake: stayAwake ?? this.stayAwake,
      showTouches: showTouches ?? this.showTouches,
      maxSize: maxSize ?? this.maxSize,
      bitRate: bitRate ?? this.bitRate,
      maxFps: maxFps ?? this.maxFps,
      autoReconnect: autoReconnect ?? this.autoReconnect,
      reconnectDelay: reconnectDelay ?? this.reconnectDelay,
      hardwareAcceleration: hardwareAcceleration ?? this.hardwareAcceleration,
      videoCodec: videoCodec ?? this.videoCodec,
      audioCodec: audioCodec ?? this.audioCodec,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'turnOffPhoneScreen': turnOffPhoneScreen,
      'recordSession': recordSession,
      'stayAwake': stayAwake,
      'showTouches': showTouches,
      'maxSize': maxSize,
      'bitRate': bitRate,
      'maxFps': maxFps,
      'autoReconnect': autoReconnect,
      'reconnectDelay': reconnectDelay,
      'hardwareAcceleration': hardwareAcceleration,
      'videoCodec': videoCodec,
      'audioCodec': audioCodec,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      turnOffPhoneScreen: json['turnOffPhoneScreen'] as bool? ?? false,
      recordSession: json['recordSession'] as bool? ?? false,
      stayAwake: json['stayAwake'] as bool? ?? true,
      showTouches: json['showTouches'] as bool? ?? false,
      maxSize: json['maxSize'] as int? ?? 0,
      bitRate: json['bitRate'] as int? ?? 8000000,
      maxFps: json['maxFps'] as int? ?? 0,
      autoReconnect: json['autoReconnect'] as bool? ?? true,
      reconnectDelay: json['reconnectDelay'] as int? ?? 3,
      hardwareAcceleration: json['hardwareAcceleration'] as bool? ?? true,
      videoCodec: json['videoCodec'] as String? ?? 'h264',
      audioCodec: json['audioCodec'] as String? ?? 'aac',
    );
  }
}
