import 'dart:async';
import 'package:http/http.dart' as http;

import 'connectivity_service.dart';
import 'models.dart';
import 'request_queue.dart';

/// Call [NetPulse.init] once (e.g. in `main()`) before using [NetPulseClient].
class NetPulse {
  static Future<void> init({
    int maxAttempts = NetPulseQueue.defaultMaxAttempts,
    Duration? ttl,
    NetPulseQueuedCallback? onQueued,
    NetPulseRetrySuccessCallback? onRetrySuccess,
    NetPulseRetryFailedCallback? onRetryFailed,
  }) async {
    NetPulseConnectivity.instance.start();
    await NetPulseQueue.instance.init(
      maxAttempts: maxAttempts,
      ttl: ttl,
      onQueued: onQueued,
      onRetrySuccess: onRetrySuccess,
      onRetryFailed: onRetryFailed,
    );
  }

  static Future<void> retryNow() => NetPulseQueue.instance.drain();

  /// Number of requests currently waiting to be retried.
  static int get pendingCount => NetPulseQueue.instance.length;

  static bool get isOnline => NetPulseConnectivity.instance.isOnline;

  static Stream<bool> get onConnectivityChange =>
      NetPulseConnectivity.instance.onStatusChange;
}

/// Drop-in HTTP client. If the device is offline (or the request fails),
/// the request is automatically persisted and retried later instead of
/// throwing — call sites decide how to react via [NetPulseResult].
class NetPulseClient {
  final http.Client _inner;
  final Duration timeout;

  NetPulseClient({http.Client? inner, this.timeout = const Duration(seconds: 10)})
      : _inner = inner ?? http.Client();

  Future<NetPulseResult> get(
    String url, {
    Map<String, String>? headers,
    NetPulsePriority priority = NetPulsePriority.normal,
  }) =>
      _execute(NetPulseMethod.get, url, headers ?? const {}, null, priority);

  Future<NetPulseResult> post(
    String url, {
    Map<String, String>? headers,
    String? body,
    NetPulsePriority priority = NetPulsePriority.normal,
  }) =>
      _execute(NetPulseMethod.post, url, headers ?? const {}, body, priority);

  Future<NetPulseResult> put(
    String url, {
    Map<String, String>? headers,
    String? body,
    NetPulsePriority priority = NetPulsePriority.normal,
  }) =>
      _execute(NetPulseMethod.put, url, headers ?? const {}, body, priority);

  Future<NetPulseResult> patch(
    String url, {
    Map<String, String>? headers,
    String? body,
    NetPulsePriority priority = NetPulsePriority.normal,
  }) =>
      _execute(NetPulseMethod.patch, url, headers ?? const {}, body, priority);

  Future<NetPulseResult> delete(
    String url, {
    Map<String, String>? headers,
    String? body,
    NetPulsePriority priority = NetPulsePriority.normal,
  }) =>
      _execute(NetPulseMethod.delete, url, headers ?? const {}, body, priority);

  Future<NetPulseResult> _execute(
    NetPulseMethod method,
    String url,
    Map<String, String> headers,
    String? body,
    NetPulsePriority priority,
  ) async {
    if (!NetPulseConnectivity.instance.isOnline) {
      await _queueIt(method, url, headers, body, priority);
      return const NetPulseResult.queuedForRetry();
    }
    try {
      final uri = Uri.parse(url);
      late http.Response response;
      switch (method) {
        case NetPulseMethod.get:
          response = await _inner.get(uri, headers: headers).timeout(timeout);
          break;
        case NetPulseMethod.post:
          response = await _inner
              .post(uri, headers: headers, body: body)
              .timeout(timeout);
          break;
        case NetPulseMethod.put:
          response = await _inner
              .put(uri, headers: headers, body: body)
              .timeout(timeout);
          break;
        case NetPulseMethod.patch:
          response = await _inner
              .patch(uri, headers: headers, body: body)
              .timeout(timeout);
          break;
        case NetPulseMethod.delete:
          response = await _inner
              .delete(uri, headers: headers, body: body)
              .timeout(timeout);
          break;
      }
      if (response.statusCode >= 500) {
        // Server-side failure — worth queuing for retry too.
        await _queueIt(method, url, headers, body, priority);
        return const NetPulseResult.queuedForRetry();
      }
      return NetPulseResult.success(response.statusCode, response.body);
    } catch (e) {
      await _queueIt(method, url, headers, body, priority);
      return const NetPulseResult.queuedForRetry();
    }
  }

  Future<void> _queueIt(
    NetPulseMethod method,
    String url,
    Map<String, String> headers,
    String? body,
    NetPulsePriority priority,
  ) {
    final req = QueuedRequest(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      method: method,
      url: url,
      headers: headers,
      body: body,
      attempts: 0,
      priority: priority,
    );
    return NetPulseQueue.instance.enqueue(req);
  }

  void close() => _inner.close();
}
