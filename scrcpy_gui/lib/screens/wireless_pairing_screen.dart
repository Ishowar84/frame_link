import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/adb_service.dart';

class WirelessPairingScreen extends StatefulWidget {
  const WirelessPairingScreen({super.key});

  @override
  State<WirelessPairingScreen> createState() => _WirelessPairingScreenState();
}

class _WirelessPairingScreenState extends State<WirelessPairingScreen> {
  final _addressController = TextEditingController();
  final _codeController = TextEditingController();
  final _connectAddressController = TextEditingController();
  
  bool _isPairing = false;
  bool _isConnecting = false;
  String? _error;
  bool _pairedSuccessfully = false;

  @override
  void dispose() {
    _addressController.dispose();
    _codeController.dispose();
    _connectAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Android 11+ Wireless Pairing'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInfoCard(),
            const SizedBox(height: 24),
            if (!_pairedSuccessfully) _buildPairingStep() else _buildConnectionStep(),
            if (_error != null) ...[
              const SizedBox(height: 16),
              _buildErrorCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'How to use Wireless Debugging:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '1. Go to Developer Options on your phone.\n'
              '2. Enable "Wireless Debugging".\n'
              '3. Tap on "Wireless Debugging" text.\n'
              '4. Select "Pair device with pairing code".',
              style: TextStyle(height: 1.5, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPairingStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Step 1: Pair Device',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _addressController,
          decoration: const InputDecoration(
            labelText: 'IP address & Port (from "Pair device...")',
            hintText: '192.168.1.100:37845',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.network_ping),
          ),
          keyboardType: TextInputType.text,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _codeController,
          decoration: const InputDecoration(
            labelText: 'Wi-Fi pairing code',
            hintText: '123456',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.vpn_key),
          ),
          keyboardType: TextInputType.number,
          maxLength: 6,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _isPairing ? null : _handlePairing,
            icon: _isPairing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.link),
            label: const Text('Pair Device'),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green),
          ),
          child: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Successfully paired! Now connect to the device.',
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Step 2: Connect to Device',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const Text(
          'Input the IP:Port shown on the main "Wireless Debugging" screen (NOT the pairing port).',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _connectAddressController,
          decoration: const InputDecoration(
            labelText: 'IP address & Port (Connection Port)',
            hintText: '192.168.1.100:41235',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.wifi),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _isConnecting ? null : _handleConnection,
            icon: _isConnecting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.power_settings_new),
            label: const Text('Connect to Device'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        TextButton(
          onPressed: () => setState(() => _pairedSuccessfully = false),
          child: const Text('Back to Pairing'),
        ),
      ],
    );
  }

  Widget _buildErrorCard() {
    return Card(
      color: Colors.red[900]!.withOpacity(0.2),
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

  Future<void> _handlePairing() async {
    final address = _addressController.text.trim();
    final code = _codeController.text.trim();

    if (address.isEmpty || code.isEmpty) {
      setState(() => _error = 'Please fill in both IP:Port and Pairing Code');
      return;
    }

    setState(() {
      _isPairing = true;
      _error = null;
    });

    final adbService = context.read<AdbService>();
    final success = await adbService.pairDevice(address, code);

    setState(() {
      _isPairing = false;
      if (success) {
        _pairedSuccessfully = true;
        // Pre-fill connection address with pairing address (IP is usually same, port changes)
        final host = address.split(':').first;
        _connectAddressController.text = '$host:';
      } else {
        _error = adbService.error ?? 'Pairing failed. Check if details are correct and on same network.';
      }
    });
  }

  Future<void> _handleConnection() async {
    final address = _connectAddressController.text.trim();
    if (address.isEmpty) {
      setState(() => _error = 'Please enter the connection IP:Port');
      return;
    }

    setState(() {
      _isConnecting = true;
      _error = null;
    });

    final parts = address.split(':');
    final host = parts[0];
    final port = parts.length > 1 ? int.tryParse(parts[1]) ?? 5555 : 5555;

    final adbService = context.read<AdbService>();
    final success = await adbService.connectWireless(host, port: port);

    setState(() {
      _isConnecting = false;
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connected to $address'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _error = adbService.error ?? 'Connection failed. Ensure the main Wireless Debugging screen is open.';
      }
    });
  }
}
