import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          TextButton.icon(
            onPressed: () {
              _showResetDialog(context);
            },
            icon: const Icon(Icons.restore),
            label: const Text('Reset to Defaults'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<SettingsService>(
        builder: (context, settingsService, child) {
          final settings = settingsService.settings;
          
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildSection(
                context,
                'Mirroring',
                [
                  _buildSwitchTile(
                    context,
                    'Turn off phone screen',
                    'Save battery and privacy while mirroring',
                    Icons.phone_locked,
                    settings.turnOffPhoneScreen,
                    (value) => settingsService.updateSetting(
                      (s) => s.copyWith(turnOffPhoneScreen: value),
                    ),
                  ),
                  _buildSwitchTile(
                    context,
                    'Stay awake',
                    'Prevent device from sleeping',
                    Icons.brightness_high,
                    settings.stayAwake,
                    (value) => settingsService.updateSetting(
                      (s) => s.copyWith(stayAwake: value),
                    ),
                  ),
                  _buildSwitchTile(
                    context,
                    'Show touches',
                    'Visualize touch points on screen',
                    Icons.touch_app,
                    settings.showTouches,
                    (value) => settingsService.updateSetting(
                      (s) => s.copyWith(showTouches: value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSection(
                context,
                'Video Quality',
                [
                  _buildSliderTile(
                    context,
                    'Max Resolution',
                    settings.maxSize == 0 ? 'Unlimited' : '${settings.maxSize}p',
                    Icons.photo_size_select_large,
                    settings.maxSize.toDouble(),
                    0,
                    2160,
                    (value) => settingsService.updateSetting(
                      (s) => s.copyWith(maxSize: value.toInt()),
                    ),
                  ),
                  _buildSliderTile(
                    context,
                    'Bit Rate',
                    '${(settings.bitRate / 1000000).toStringAsFixed(1)} Mbps',
                    Icons.speed,
                    settings.bitRate.toDouble(),
                    1000000,
                    20000000,
                    (value) => settingsService.updateSetting(
                      (s) => s.copyWith(bitRate: value.toInt()),
                    ),
                  ),
                  _buildSliderTile(
                    context,
                    'Max FPS',
                    settings.maxFps == 0 ? 'Unlimited' : '${settings.maxFps} fps',
                    Icons.animation,
                    settings.maxFps.toDouble(),
                    0,
                    120,
                    (value) => settingsService.updateSetting(
                      (s) => s.copyWith(maxFps: value.toInt()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSection(
                context,
                'Connection',
                [
                  _buildSwitchTile(
                    context,
                    'Auto-reconnect',
                    'Automatically reconnect on disconnect',
                    Icons.autorenew,
                    settings.autoReconnect,
                    (value) => settingsService.updateSetting(
                      (s) => s.copyWith(autoReconnect: value),
                    ),
                  ),
                  if (settings.autoReconnect)
                    _buildSliderTile(
                      context,
                      'Reconnect Delay',
                      '${settings.reconnectDelay} seconds',
                      Icons.timer,
                      settings.reconnectDelay.toDouble(),
                      1,
                      10,
                      (value) => settingsService.updateSetting(
                        (s) => s.copyWith(reconnectDelay: value.toInt()),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ),
        Card(
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      secondary: Icon(icon),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _buildSliderTile(
    BuildContext context,
    String title,
    String valueLabel,
    IconData icon,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            valueLabel,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: ((max - min) / (max > 100 ? 1000000 : 10)).toInt(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
          'Are you sure you want to reset all settings to default values?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final messenger = ScaffoldMessenger.of(context);
              context.read<SettingsService>().resetToDefaults();
              Navigator.of(context).pop();
              messenger.showSnackBar(
                const SnackBar(content: Text('Settings reset to defaults')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
