## 0.2.0

- Added request priorities so queued work can be retried in high, normal,
  and low priority order.
- Added TTL-based expiry for queued requests, with expired items dropped and
  reported through the retry-failure hook.
- Added queue lifecycle hooks for queued, retry-success, and retry-failed
  events so apps can track offline request behavior.
- Made maximum retry attempts configurable during setup.
- Added a manual retry trigger so queues can be drained on demand.
- Expanded the example, tests, and documentation for the new release.

## 0.1.0

- Initial release.
- `NetPulseClient`: HTTP client with automatic offline queueing and retry
  with exponential backoff (persisted across app restarts).
- `NetPulseBanner`: zero-config animated online/offline status banner.
- `NetPulse.init()` bootstrap, `NetPulse.pendingCount`, `NetPulse.isOnline`,
  `NetPulse.onConnectivityChange`.
