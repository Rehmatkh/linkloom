import 'dart:async';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'connectivity_service.dart';
import 'models.dart';

/// Persists failed/offline requests to disk and automatically retries
/// them with exponential backoff as soon as connectivity returns.
class NetPulseQueue {
  NetPulseQueue._internal();
  static final NetPulseQueue instance = NetPulseQueue._internal();

  static const _storageKey = 'linkloom_queue_v1';
  static const int maxAttempts = 6;

  final List<QueuedRequest> _queue = [];
  final http.Client _http = http.Client();
  bool _initialized = false;
  bool _draining = false;
  StreamSubscription<bool>? _connSub;

  /// Called once (NetPulse.init does this for you) to load any
  /// requests that were queued before the app was last closed.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      _queue.addAll(QueuedRequest.decodeList(raw));
    }
    _connSub = NetPulseConnectivity.instance.onStatusChange.listen((online) {
      if (online) drain();
    });
    if (NetPulseConnectivity.instance.isOnline) {
      unawaited(drain());
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, QueuedRequest.encodeList(_queue));
  }

  Future<void> enqueue(QueuedRequest request) async {
    _queue.add(request);
    await _persist();
  }

  int get length => _queue.length;

  /// Attempts to send every queued request, in order, removing each
  /// on success. Uses exponential backoff between attempts per-item.
  Future<void> drain() async {
    if (_draining || _queue.isEmpty) return;
    _draining = true;
    try {
      final remaining = <QueuedRequest>[];
      for (final req in List<QueuedRequest>.from(_queue)) {
        if (!NetPulseConnectivity.instance.isOnline) {
          remaining.add(req);
          continue;
        }
        final delayMs = min(30000, 500 * pow(2, req.attempts).toInt());
        if (req.attempts > 0) {
          await Future.delayed(Duration(milliseconds: delayMs));
        }
        try {
          final response = await _send(req);
          if (response.statusCode >= 200 && response.statusCode < 300) {
            // success — drop from queue
            continue;
          } else {
            req.attempts++;
            if (req.attempts < maxAttempts) remaining.add(req);
          }
        } catch (_) {
          req.attempts++;
          if (req.attempts < maxAttempts) remaining.add(req);
        }
      }
      _queue
        ..clear()
        ..addAll(remaining);
      await _persist();
    } finally {
      _draining = false;
    }
  }

  Future<http.Response> _send(QueuedRequest req) {
    final uri = Uri.parse(req.url);
    switch (req.method) {
      case NetPulseMethod.get:
        return _http.get(uri, headers: req.headers);
      case NetPulseMethod.post:
        return _http.post(uri, headers: req.headers, body: req.body);
      case NetPulseMethod.put:
        return _http.put(uri, headers: req.headers, body: req.body);
      case NetPulseMethod.patch:
        return _http.patch(uri, headers: req.headers, body: req.body);
      case NetPulseMethod.delete:
        return _http.delete(uri, headers: req.headers, body: req.body);
    }
  }

  void dispose() {
    _connSub?.cancel();
    _http.close();
  }
}
