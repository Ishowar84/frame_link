import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/adb_service.dart';
import '../services/scrcpy_service.dart';
import '../services/settings_service.dart';
import '../models/device_model.dart';
import '../models/settings_model.dart';
import 'wireless_setup_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    final adbService = context.read<AdbService>();
    await adbService.refreshDevices();
    adbService.startAutoRefresh();
  }

  @override
  void dispose() {
    context.read<AdbService>().stopAutoRefresh();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.phone_android, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            const Text('FrameLink'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
            tooltip: 'Settings',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          // Left panel - Device list
          Expanded(
            flex: 3,
            child: _buildDevicePanel(),
          ),
          // Right panel - Quick settings
          Expanded(
            flex: 2,
            child: _buildQuickSettings(),
          ),
        ],
      ),
    );
  }

  Widget _buildDevicePanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPanelHeader(),
          const SizedBox(height: 16),
          Expanded(child: _buildDeviceList()),
        ],
      ),
    );
  }

  Widget _buildPanelHeader() {
    return Consumer<AdbService>(
      builder: (context, adbService, child) {
        return Row(
          children: [
            Text(
              'Connected Devices',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Spacer(),
            if (adbService.isScanning)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => adbService.refreshDevices(),
                tooltip: 'Refresh',
              ),
          ],
        );
      },
    );
  }

  Widget _buildDeviceList() {
    return Consumer<AdbService>(
      builder: (context, adbService, child) {
        if (adbService.error != null) {
          return _buildErrorState(adbService.error!);
        }

        if (!adbService.hasDevices) {
          return _buildEmptyState();
        }

        return ListView.builder(
          itemCount: adbService.devices.length,
          itemBuilder: (context, index) {
            final device = adbService.devices[index];
            return _buildDeviceCard(device);
          },
        );
      },
    );
  }

  Widget _buildDeviceCard(AndroidDevice device) {
    return Consumer<ScrcpyService>(
      builder: (context, scrcpyService, child) {
        final isActive = scrcpyService.currentDevice == device.serial;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _handleDeviceTap(device),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        device.isWireless ? Icons.wifi : Icons.usb,
                        color: isActive 
                            ? Theme.of(context).colorScheme.primary 
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              device.model,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Android ${device.androidVersion} • ${device.state.displayName}',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'ACTIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    device.serial,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: scrcpyService.isRunning && isActive
                              ? null
                              : () => _startMirroring(device),
                          icon: const Icon(Icons.cast, size: 20),
                          label: const Text('Mirror'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _setupWireless(device),
                          icon: const Icon(Icons.wifi, size: 20),
                          label: const Text('Wireless'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.phone_android_outlined,
            size: 64,
            color: Colors.grey[700],
          ),
          const SizedBox(height: 16),
          Text(
            'No devices connected',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Connect your Android device via USB\nand enable USB Debugging',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.read<AdbService>().refreshDevices(),
            icon: const Icon(Icons.refresh),
            label: const Text('Scan for Devices'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text('Error', style: TextStyle(fontSize: 18, color: Colors.red[400])),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              context.read<AdbService>().clearError();
              context.read<AdbService>().refreshDevices();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSettings() {
    return Consumer2<SettingsService, ScrcpyService>(
      builder: (context, settingsService, scrcpyService, child) {
        final settings = settingsService.settings;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              left: BorderSide(
                color: Colors.grey[800]!,
                width: 1,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quick Settings',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              _buildQuickOption(
                'Turn off phone screen',
                'Save battery and privacy',
                Icons.phone_locked,
                settings.turnOffPhoneScreen,
                (value) {
                  settingsService.updateSetting(
                    (s) => s.copyWith(turnOffPhoneScreen: value),
                  );
                  if (scrcpyService.isRunning) {
                    scrcpyService.toggleScreenLive(value);
                  }
                },
              ),
              _buildQuickOption(
                'Stay awake',
                'Prevent phone from sleeping',
                Icons.brightness_high,
                settings.stayAwake,
                (value) => settingsService.updateSetting(
                  (s) => s.copyWith(stayAwake: value),
                ),
              ),
              _buildQuickOption(
                'Show touches',
                'Visualize touch points',
                Icons.touch_app,
                settings.showTouches,
                (value) => settingsService.updateSetting(
                  (s) => s.copyWith(showTouches: value),
                ),
              ),
              _buildQuickOption(
                'Auto-reconnect',
                'Reconnect on disconnect',
                Icons.autorenew,
                settings.autoReconnect,
                (value) => settingsService.updateSetting(
                  (s) => s.copyWith(autoReconnect: value),
                ),
              ),
              const Spacer(),
              const Divider(),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await context.read<AdbService>().restartAdbServer();
                    messenger.showSnackBar(
                      const SnackBar(content: Text('ADB Server Restarted')),
                    );
                  },
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('Restart ADB Service'),
                ),
              ),
              const SizedBox(height: 16),
              if (scrcpyService.isRunning) ...[
                const Divider(),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => scrcpyService.stopMirroring(),
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop Mirroring'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickOption(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
        secondary: Icon(icon),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  void _handleDeviceTap(AndroidDevice device) {
    if (context.read<ScrcpyService>().isRunning) {
      return; // Don't allow switching while mirroring
    }
    _startMirroring(device);
  }

  Future<void> _startMirroring(AndroidDevice device) async {
    final scrcpyService = context.read<ScrcpyService>();
    final settings = context.read<SettingsService>().settings;

    final messenger = ScaffoldMessenger.of(context);
    final success = await scrcpyService.startMirroring(
      deviceSerial: device.serial,
      settings: settings,
    );

    if (!success && scrcpyService.error != null && mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(scrcpyService.error!),
          backgroundColor: Colors.red[700],
          action: SnackBarAction(
            label: 'Dismiss',
            textColor: Colors.white,
            onPressed: () => scrcpyService.clearError(),
          ),
        ),
      );
    }
  }

  void _setupWireless(AndroidDevice device) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WirelessSetupScreen(device: device),
      ),
    );
  }
}
