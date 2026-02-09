import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/device_model.dart';
import '../services/adb_service.dart';

class WirelessSetupScreen extends StatefulWidget {
  final AndroidDevice device;

  const WirelessSetupScreen({
    super.key,
    required this.device,
  });

  @override
  State<WirelessSetupScreen> createState() => _WirelessSetupScreenState();
}

class _WirelessSetupScreenState extends State<WirelessSetupScreen> {
  String? _deviceIp;
  bool _isEnabling = false;
  bool _isConnecting = false;
  String? _error;
  final _manualIpController = TextEditingController();

  @override
  void dispose() {
    _manualIpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wireless Setup'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDeviceInfo(),
            const SizedBox(height: 32),
            _buildSteps(),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.phone_android,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.device.model,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.device.serial,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSteps() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStep1EnableWireless(),
        const SizedBox(height: 24),
        if (_deviceIp != null) ...[
          _buildStep2QRCode(),
          const SizedBox(height: 24),
          _buildStep3Connect(),
        ],
        if (_error != null) ...[
          const SizedBox(height: 16),
          _buildError(),
        ],
        const SizedBox(height: 32),
        _buildManualConnection(),
      ],
    );
  }

  Widget _buildStep1EnableWireless() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildStepNumber(1),
                const SizedBox(width: 12),
                const Text(
                  'Enable Wireless Mode',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Keep your device connected via USB and enable TCP/IP mode.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isEnabling ? null : _enableWireless,
                icon: _isEnabling
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.wifi_tethering),
                label: Text(_isEnabling ? 'Enabling...' : 'Enable Wireless'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            if (_deviceIp != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Wireless enabled • IP: $_deviceIp',
                      style: const TextStyle(color: Colors.green),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2QRCode() {
    final connectionString = '$_deviceIp:5555';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                _buildStepNumber(2),
                const SizedBox(width: 12),
                const Text(
                  'Scan QR Code (Optional)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: QrImageView(
                data: connectionString,
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              connectionString,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: connectionString));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard')),
                );
              },
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copy'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep3Connect() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildStepNumber(3),
                const SizedBox(width: 12),
                const Text(
                  'Disconnect USB & Connect',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              '1. Unplug the USB cable from your device\n'
              '2. Click the button below to connect wirelessly',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isConnecting ? null : _connectWireless,
                icon: _isConnecting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.link),
                label: Text(_isConnecting ? 'Connecting...' : 'Connect Wirelessly'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualConnection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Manual Connection',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Already know your device IP?',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _manualIpController,
              decoration: const InputDecoration(
                labelText: 'IP Address',
                hintText: '192.168.1.100',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.wifi),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final ip = _manualIpController.text.trim();
                  if (ip.isNotEmpty) {
                    _connectToIp(ip);
                  }
                },
                child: const Text('Connect'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Card(
      color: Colors.red[900]!.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepNumber(int number) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '$number',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Future<void> _enableWireless() async {
    setState(() {
      _isEnabling = true;
      _error = null;
    });

    final adbService = context.read<AdbService>();
    final ip = await adbService.enableWireless(widget.device.serial);

    setState(() {
      _isEnabling = false;
      if (ip != null) {
        _deviceIp = ip;
      } else {
        _error = 'Failed to enable wireless mode. Make sure Wi-Fi is enabled on your device.';
      }
    });
  }

  Future<void> _connectWireless() async {
    if (_deviceIp == null) return;
    await _connectToIp(_deviceIp!);
  }

  Future<void> _connectToIp(String ip) async {
    setState(() {
      _isConnecting = true;
      _error = null;
    });

    final adbService = context.read<AdbService>();
    final success = await adbService.connectWireless(ip);

    setState(() {
      _isConnecting = false;
      if (success) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.of(context).pop();
        messenger.showSnackBar(
          SnackBar(
            content: Text('Connected to $ip:5555'),
            backgroundColor: Colors.green[700],
          ),
        );
      } else {
        _error = 'Connection failed. Make sure:\n'
            '• USB cable is unplugged\n'
            '• Device is on the same Wi-Fi network\n'
            '• IP address is correct';
      }
    });
  }
}
