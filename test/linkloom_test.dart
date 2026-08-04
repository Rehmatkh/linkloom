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
