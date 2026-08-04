import 'dart:async';
import 'package:flutter/material.dart';
import 'connectivity_service.dart';

/// Wrap your app's `home` (or any widget) with [NetPulseBanner] to get an
/// automatic animated "You're offline" / "Back online" banner with zero
/// extra wiring. Requires [NetPulse.init] to have been called first.
///
/// ```dart
/// MaterialApp(
///   home: NetPulseBanner(child: MyHomePage()),
/// )
/// ```
class NetPulseBanner extends StatefulWidget {
  final Widget child;
  final String offlineMessage;
  final String backOnlineMessage;
  final Color offlineColor;
  final Color backOnlineColor;
  final Duration backOnlineDisplayDuration;

  const NetPulseBanner({
    super.key,
    required this.child,
    this.offlineMessage = "You're offline",
    this.backOnlineMessage = 'Back online',
    this.offlineColor = const Color(0xFFB3261E),
    this.backOnlineColor = const Color(0xFF2E7D32),
    this.backOnlineDisplayDuration = const Duration(seconds: 2),
  });

  @override
  State<NetPulseBanner> createState() => _NetPulseBannerState();
}

class _NetPulseBannerState extends State<NetPulseBanner> {
  bool _visible = false;
  bool _isOfflineState = false;
  bool _lastKnownOnline = true;
  StreamSubscription<bool>? _sub;

  @override
  void initState() {
    super.initState();
    _lastKnownOnline = NetPulseConnectivity.instance.isOnline;
    _sub = NetPulseConnectivity.instance.onStatusChange.listen(_onChange);
  }

  void _onChange(bool online) {
    if (!mounted) return;
    if (!online) {
      setState(() {
        _visible = true;
        _isOfflineState = true;
      });
    } else if (!_lastKnownOnline) {
      setState(() {
        _visible = true;
        _isOfflineState = false;
      });
      Future.delayed(widget.backOnlineDisplayDuration, () {
        if (mounted) setState(() => _visible = false);
      });
    }
    _lastKnownOnline = online;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: _visible ? 32 : 0,
          color: _isOfflineState ? widget.offlineColor : widget.backOnlineColor,
          width: double.infinity,
          alignment: Alignment.center,
          child: _visible
              ? Text(
                  _isOfflineState
                      ? widget.offlineMessage
                      : widget.backOnlineMessage,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                )
              : null,
        ),
        Expanded(child: widget.child),
      ],
    );
  }
}
