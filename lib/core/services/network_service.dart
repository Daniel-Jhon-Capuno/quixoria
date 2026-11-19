import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'web_network_stub.dart'
    if (dart.library.html) 'web_network_web.dart' as web_net;

/// Real-time Network Monitoring Service for Quixoria.
/// Actively detects Wi-Fi/Internet connectivity in real time, emits changes to listeners,
/// and allows auto-dismissal of offline dialogues when the realm connection is restored.
/// Fully CORS-compliant for Web (Chrome/Edge/Firefox) and native platforms (Android/iOS/Desktop).
class NetworkMonitorService {
  NetworkMonitorService._();
  static final NetworkMonitorService instance = NetworkMonitorService._();

  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  Stream<bool> get onConnectivityChanged => _controller.stream;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  Timer? _pollingTimer;
  StreamSubscription<bool>? _webSubscription;
  bool _isChecking = false;
  bool? _manualOverride;
  int _consecutiveFailures = 0;

  /// Start real-time background connectivity polling
  void startMonitoring({Duration interval = const Duration(seconds: 6)}) {
    _pollingTimer?.cancel();
    _webSubscription?.cancel();

    // On Web, hook into native browser online/offline window events for instant reaction
    final webStream = web_net.getWebConnectivityStream();
    if (webStream != null) {
      _webSubscription = webStream.listen((online) {
        if (!online) {
          _consecutiveFailures = 2;
          _updateStatus(false);
        } else {
          _consecutiveFailures = 0;
          checkConnection();
        }
      });
    }

    checkConnection();
    _pollingTimer = Timer.periodic(interval, (_) => checkConnection());
  }

  void stopMonitoring() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _webSubscription?.cancel();
    _webSubscription = null;
  }

  /// Manually force or override connectivity status (e.g. user toggles in Settings or test simulation)
  void setOverride(bool? override) {
    _manualOverride = override;
    if (override != null) {
      _consecutiveFailures = override ? 0 : 2;
      _updateStatus(override);
    } else {
      checkConnection();
    }
  }

  /// Check connectivity in real-time with full CORS & Android background-resume resilience
  Future<bool> checkConnection() async {
    if (_manualOverride != null) {
      _updateStatus(_manualOverride!);
      return _manualOverride!;
    }

    // In web browsers, navigator.onLine provides an immediate check
    if (kIsWeb && !web_net.getWebNavigatorOnline()) {
      _consecutiveFailures = 2;
      _updateStatus(false);
      return false;
    }

    if (_isChecking) return _isOnline;
    _isChecking = true;

    bool online = false;
    try {
      // Primary check: Google Public DNS JSON endpoint (CORS-compliant)
      final response = await http
          .get(
            Uri.parse('https://dns.google/resolve?name=google.com'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(milliseconds: 4000));

      if (response.statusCode == 200) {
        online = true;
      }
    } catch (_) {
      // Secondary fallback: Cloudflare DNS or Google 204 endpoint
      try {
        final fallback = await http
            .get(
              Uri.parse(kIsWeb
                  ? 'https://cloudflare-dns.com/dns-query?name=cloudflare.com&type=A'
                  : 'https://www.google.com/generate_204'),
              headers: {'Accept': 'application/dns-json'},
            )
            .timeout(const Duration(milliseconds: 3500));
        online = (fallback.statusCode == 200 || fallback.statusCode == 204);
      } catch (_) {
        online = false;
      }
    } finally {
      _isChecking = false;
      if (online) {
        _consecutiveFailures = 0;
        _updateStatus(true);
      } else {
        _consecutiveFailures += 1;
        // Require 2 consecutive failures to avoid false alarms when Android resumes from background
        if (_consecutiveFailures >= 2) {
          _updateStatus(false);
        }
      }
    }

    return _isOnline;
  }

  void _updateStatus(bool newStatus) {
    if (_isOnline != newStatus) {
      _isOnline = newStatus;
      _controller.add(_isOnline);
      if (kDebugMode) {
        debugPrint('[NetworkMonitorService] Real-time connectivity changed: isOnline=$_isOnline');
      }
    }
  }
}
