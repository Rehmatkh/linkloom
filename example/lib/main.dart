import 'package:flutter/material.dart';
import 'package:net_pulse/net_pulse.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NetPulse.init(); // one-time setup
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'net_pulse example',
      home: NetPulseBanner(  // <- zero-config offline banner
        child: HomePage(),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _client = NetPulseClient();
  String _status = 'Idle';

  Future<void> _sendOrder() async {
    setState(() => _status = 'Sending...');
    final result = await _client.post(
      'https://example.com/api/orders',
      headers: {'Content-Type': 'application/json'},
      body: '{"orderId": 123}',
    );

    setState(() {
      if (result.queued) {
        _status = 'Offline — queued (${NetPulse.pendingCount} pending), '
            'will auto-retry when connection returns.';
      } else if (result.isSuccess) {
        _status = 'Sent! Status ${result.statusCode}';
      } else {
        _status = 'Failed: ${result.error}';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('net_pulse example')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_status, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _sendOrder,
              child: const Text('Send order'),
            ),
          ],
        ),
      ),
    );
  }
}
