import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Thin, testable wrapper around [Connectivity] that exposes a simple
/// bool online/offline stream instead of raw connectivity-type lists.
class NetPulseConnectivity {
  NetPulseConnectivity._internal();
  static final NetPulseConnectivity instance = NetPulseConnectivity._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _controller =
      StreamController<bool>.broadcast();
  StreamSubscription? _sub;
  bool _isOnline = true;
  bool _started = false;

  bool get isOnline => _isOnline;
  Stream<bool> get onStatusChange => _controller.stream;

  void start() {
    if (_started) return;
    _started = true;
    _sub = _connectivity.onConnectivityChanged.listen((results) {
      final online = !results.contains(ConnectivityResult.none);
      if (online != _isOnline) {
        _isOnline = online;
        _controller.add(online);
      }
    });
    // Prime initial state.
    _connectivity.checkConnectivity().then((results) {
      _isOnline = !results.contains(ConnectivityResult.none);
    });
  }

  void dispose() {
    _sub?.cancel();
    _controller.close();
    _started = false;
  }
}
