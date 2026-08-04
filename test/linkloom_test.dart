import 'package:flutter_test/flutter_test.dart';
import 'package:linkloom/src/models.dart';

void main() {
  group('QueuedRequest serialization', () {
    test('round-trips through JSON', () {
      final req = QueuedRequest(
        id: '1',
        method: NetPulseMethod.post,
        url: 'https://example.com',
        headers: {'a': 'b'},
        body: '{"x":1}',
        attempts: 2,
        priority: NetPulsePriority.high,
      );
      final encoded = QueuedRequest.encodeList([req]);
      final decoded = QueuedRequest.decodeList(encoded);

      expect(decoded.length, 1);
      expect(decoded.first.id, '1');
      expect(decoded.first.method, NetPulseMethod.post);
      expect(decoded.first.url, 'https://example.com');
      expect(decoded.first.headers['a'], 'b');
      expect(decoded.first.body, '{"x":1}');
      expect(decoded.first.attempts, 2);
      expect(decoded.first.priority, NetPulsePriority.high);
    });

    test('defaults to normal priority when decoding older payloads', () {
      final decoded = QueuedRequest.fromJson({
        'id': '1',
        'method': 'post',
        'url': 'https://example.com',
        'headers': {'a': 'b'},
        'body': null,
        'createdAt': DateTime.now().toIso8601String(),
        'attempts': 0,
      });

      expect(decoded.priority, NetPulsePriority.normal);
    });
  });

  group('QueuedRequest priority sorting', () {
    test('sorts high priority before normal before low, with older first', () {
      final now = DateTime.now();
      final lowOlder = QueuedRequest(
        id: 'low-older',
        method: NetPulseMethod.get,
        url: 'https://example.com/low-older',
        headers: const {},
        attempts: 0,
        priority: NetPulsePriority.low,
        createdAt: now.add(const Duration(seconds: 2)),
      );
      final lowNewer = QueuedRequest(
        id: 'low-newer',
        method: NetPulseMethod.get,
        url: 'https://example.com/low-newer',
        headers: const {},
        attempts: 0,
        priority: NetPulsePriority.low,
        createdAt: now.add(const Duration(seconds: 4)),
      );
      final normalOlder = QueuedRequest(
        id: 'normal-older',
        method: NetPulseMethod.get,
        url: 'https://example.com/normal-older',
        headers: const {},
        attempts: 0,
        priority: NetPulsePriority.normal,
        createdAt: now.add(const Duration(seconds: 1)),
      );
      final normalNewer = QueuedRequest(
        id: 'normal-newer',
        method: NetPulseMethod.get,
        url: 'https://example.com/normal-newer',
        headers: const {},
        attempts: 0,
        priority: NetPulsePriority.normal,
        createdAt: now.add(const Duration(seconds: 3)),
      );
      final high = QueuedRequest(
        id: 'high',
        method: NetPulseMethod.get,
        url: 'https://example.com/high',
        headers: const {},
        attempts: 0,
        priority: NetPulsePriority.high,
        createdAt: now,
      );

      final sorted = sortByPriority([
        lowOlder,
        normalNewer,
        high,
        normalOlder,
        lowNewer,
      ]);

      expect(sorted.map((request) => request.id).toList(), [
        'high',
        'normal-older',
        'normal-newer',
        'low-older',
        'low-newer',
      ]);
    });
  });

  group('QueuedRequest TTL expiry', () {
    test('does not expire for a fresh request with a one-hour ttl', () {
      final request = QueuedRequest(
        id: 'fresh',
        method: NetPulseMethod.get,
        url: 'https://example.com',
        headers: const {},
        attempts: 0,
      );

      expect(request.isExpired(const Duration(hours: 1)), false);
    });

    test('expires after the ttl window has passed', () {
      final request = QueuedRequest(
        id: 'stale',
        method: NetPulseMethod.get,
        url: 'https://example.com',
        headers: const {},
        attempts: 0,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      );

      expect(request.isExpired(const Duration(hours: 1)), true);
    });

    test('returns false when ttl is null', () {
      final request = QueuedRequest(
        id: 'stale',
        method: NetPulseMethod.get,
        url: 'https://example.com',
        headers: const {},
        attempts: 0,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      );

      expect(request.isExpired(null), false);
    });
  });

  group('NetPulseResult', () {
    test('success result reports isSuccess true', () {
      const result = NetPulseResult.success(200, 'ok');
      expect(result.isSuccess, true);
      expect(result.queued, false);
    });

    test('queued result reports queued true, isSuccess false', () {
      const result = NetPulseResult.queuedForRetry();
      expect(result.queued, true);
      expect(result.isSuccess, false);
    });

    test('failure result carries the error', () {
      const result = NetPulseResult.failure('boom');
      expect(result.error, 'boom');
      expect(result.isSuccess, false);
    });
  });
}
