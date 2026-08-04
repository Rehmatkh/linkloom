/// linkloom — connectivity-aware HTTP with automatic offline retry
/// queueing, plus a zero-config online/offline UI banner.
library linkloom;

export 'src/linkloom_client.dart';
export 'src/linkloom_banner.dart';
export 'src/models.dart' show
    NetPulseResult,
    NetPulseMethod,
    NetPulsePriority,
    NetPulseQueuedCallback,
    NetPulseRetrySuccessCallback,
    NetPulseRetryFailedCallback;
