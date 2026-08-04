import 'dart:convert';

/// HTTP method supported by a queued request.
enum NetPulseMethod { get, post, put, patch, delete }

/// Priority for queued requests. Higher priority requests are retried first.
enum NetPulsePriority { low, normal, high }

/// A callback invoked whenever a request is queued.
typedef NetPulseQueuedCallback = void Function(QueuedRequest request);

/// A callback invoked when a queued request succeeds during retry.
typedef NetPulseRetrySuccessCallback = void Function(
  QueuedRequest request,
  int statusCode,
);

/// A callback invoked when a queued request is dropped permanently.
typedef NetPulseRetryFailedCallback = void Function(
  QueuedRequest request,
  String reason,
);

NetPulseMethod methodFromString(String value) {
  return NetPulseMethod.values.firstWhere(
    (m) => m.name == value,
    orElse: () => NetPulseMethod.get,
  );
}

int _priorityRank(NetPulsePriority priority) {
  return switch (priority) {
    NetPulsePriority.high => 0,
    NetPulsePriority.normal => 1,
    NetPulsePriority.low => 2,
  };
}

/// Sorts requests so that high priority items are handled before normal and
/// low priority items, with older items first inside the same tier.
List<QueuedRequest> sortByPriority(List<QueuedRequest> requests) {
  final sorted = List<QueuedRequest>.from(requests);
  sorted.sort((a, b) {
    final priorityComparison = _priorityRank(a.priority).compareTo(
      _priorityRank(b.priority),
    );
    if (priorityComparison != 0) {
      return priorityComparison;
    }
    return a.createdAt.compareTo(b.createdAt);
  });
  return sorted;
}

/// A single request that failed (or was made while offline) and is
/// waiting to be retried once connectivity is restored.
class QueuedRequest {
  final String id;
  final NetPulseMethod method;
  final String url;
  final Map<String, String> headers;
  final String? body;
  final DateTime createdAt;
  final NetPulsePriority priority;
  int attempts;

  QueuedRequest({
    required this.id,
    required this.method,
    required this.url,
    required this.headers,
    required this.attempts,
    this.body,
    this.priority = NetPulsePriority.normal,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'method': method.name,
        'url': url,
        'headers': headers,
        'body': body,
        'createdAt': createdAt.toIso8601String(),
        'attempts': attempts,
        'priority': priority.name,
      };

  factory QueuedRequest.fromJson(Map<String, dynamic> json) => QueuedRequest(
        id: json['id'] as String,
        method: methodFromString(json['method'] as String),
        url: json['url'] as String,
        headers: Map<String, String>.from(json['headers'] as Map),
        body: json['body'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        attempts: json['attempts'] as int,
        priority: json['priority'] == null
            ? NetPulsePriority.normal
            : NetPulsePriority.values.firstWhere(
                (priority) => priority.name == json['priority'],
                orElse: () => NetPulsePriority.normal,
              ),
      );

  bool isExpired(Duration? ttl) {
    if (ttl == null) {
      return false;
    }
    return DateTime.now().difference(createdAt) > ttl;
  }

  static String encodeList(List<QueuedRequest> items) =>
      jsonEncode(items.map((e) => e.toJson()).toList());

  static List<QueuedRequest> decodeList(String raw) {
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => QueuedRequest.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

/// Result of a NetPulseClient call — either a live response or
/// confirmation that the request was queued for later.
class NetPulseResult {
  final bool queued;
  final int? statusCode;
  final String? body;
  final Object? error;

  const NetPulseResult.success(this.statusCode, this.body)
      : queued = false,
        error = null;

  const NetPulseResult.queuedForRetry()
      : queued = true,
        statusCode = null,
        body = null,
        error = null;

  const NetPulseResult.failure(this.error)
      : queued = false,
        statusCode = null,
        body = null;

  bool get isSuccess => !queued && error == null && statusCode != null;
}
