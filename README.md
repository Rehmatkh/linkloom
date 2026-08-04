# linkloom

[![pub package](https://img.shields.io/pub/v/linkloom.svg)](https://pub.dev/packages/linkloom)

Connectivity-aware HTTP client for Flutter that **never silently drops a
request**, plus a **zero-config offline/online banner** — in one package.

Most apps need two separate packages (`connectivity_plus` + some retry
logic you hand-roll) to handle this correctly. `linkloom` combines both:

- 📡 **Auto offline queue** — requests made while offline (or that fail)
  are persisted to disk and retried automatically with exponential backoff
  as soon as the connection returns — survives app restarts.
- 🎨 **Zero-config UI banner** — wrap your app once, get an animated
  "You're offline" / "Back online" banner with no manual `StreamBuilder`.
- 🧩 Drop-in replacement for basic `http` GET/POST/PUT/PATCH/DELETE calls.

Built with courier/delivery and field-work apps in mind — where drivers
lose signal mid-route and you can't afford to lose an order update.

## Install

```yaml
dependencies:
  linkloom: ^0.2.0
```

## Usage

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NetPulse.init(
    maxAttempts: 8,
    ttl: const Duration(hours: 1),
    onQueued: (request) => debugPrint('Queued: ${request.id}'),
    onRetrySuccess: (request, statusCode) =>
        debugPrint('Retry succeeded: $statusCode'),
    onRetryFailed: (request, reason) =>
        debugPrint('Retry failed: $reason'),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: NetPulseBanner(       // <- automatic offline banner
        child: const HomePage(),
      ),
    );
  }
}
```

Making a request:

```dart
final client = NetPulseClient();

final result = await client.post(
  'https://example.com/api/orders',
  headers: {'Content-Type': 'application/json'},
  body: '{"orderId": 123}',
  priority: NetPulsePriority.high,
);

if (result.queued) {
  // Device was offline (or the request failed) — it's safely
  // queued on disk and will retry automatically.
  print('Queued. Pending: ${NetPulse.pendingCount}');
} else if (result.isSuccess) {
  print('Sent! ${result.statusCode}');
} else {
  print('Failed: ${result.error}');
}
```

## Priority

Use the optional `priority` parameter on any request to influence retry order.
High-priority items are retried first, then normal, then low priority.

```dart
await client.post(
  'https://example.com/api/orders',
  body: '{"orderId": 123}',
  priority: NetPulsePriority.high,
);
```

## API overview

| Symbol | Purpose |
|---|---|
| `NetPulse.init()` | One-time setup — call before `runApp`. |
| `NetPulse.isOnline` | Current connectivity state. |
| `NetPulse.pendingCount` | Number of requests waiting to retry. |
| `NetPulse.onConnectivityChange` | Stream of `bool` connectivity changes. |
| `NetPulseClient` | HTTP client with `.get/.post/.put/.patch/.delete`. |
| `NetPulseBanner` | Widget — wrap any screen for an automatic status banner. |

## Customizing the banner

```dart
NetPulseBanner(
  offlineMessage: "No internet connection",
  backOnlineMessage: "Connected",
  offlineColor: Colors.red,
  backOnlineColor: Colors.green,
  child: const HomePage(),
)
```

## Contributing

Issues and PRs welcome — see [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT — see [LICENSE](LICENSE).
