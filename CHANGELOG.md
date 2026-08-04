## 0.1.0

- Initial release.
- `NetPulseClient`: HTTP client with automatic offline queueing and retry
  with exponential backoff (persisted across app restarts).
- `NetPulseBanner`: zero-config animated online/offline status banner.
- `NetPulse.init()` bootstrap, `NetPulse.pendingCount`, `NetPulse.isOnline`,
  `NetPulse.onConnectivityChange`.
