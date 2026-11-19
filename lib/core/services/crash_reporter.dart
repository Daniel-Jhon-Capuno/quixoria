import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CrashRecord {
  final DateTime time;
  final String error;
  final String stack;
  final String source;

  CrashRecord({
    required this.time,
    required this.error,
    required this.stack,
    required this.source,
  });

  Map<String, dynamic> toJson() => {
        'time': time.toIso8601String(),
        'error': error,
        'stack': stack,
        'source': source,
      };

  factory CrashRecord.fromJson(Map<String, dynamic> j) => CrashRecord(
        time: DateTime.tryParse(j['time'] as String? ?? '') ?? DateTime.now(),
        error: j['error'] as String? ?? '',
        stack: j['stack'] as String? ?? '',
        source: j['source'] as String? ?? 'unknown',
      );

  String toShareableText() => '[$source] ${time.toIso8601String()}\n$error\n$stack';
}

/// On-device crash & error reporter.
///
/// Catches Flutter framework errors and uncaught async errors and keeps the
/// most recent ones on the device only (nothing is uploaded). The reader can
/// view, copy, and clear them from Settings > Diagnostics. When an online
/// crash service (e.g. Crashlytics) is added later, forward records from
/// [_record].
class CrashReporter {
  CrashReporter._();
  static final CrashReporter instance = CrashReporter._();

  static const String _key = 'quixoria_crash_log_v1';
  static const int _maxRecords = 30;

  SharedPreferences? _prefs;
  final List<CrashRecord> _records = [];

  List<CrashRecord> get records => List.unmodifiable(_records.reversed);

  void init(SharedPreferences prefs) {
    _prefs = prefs;
    _load();

    final previousFlutterHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      _record(details.exceptionAsString(), details.stack, 'flutter');
      if (previousFlutterHandler != null) {
        previousFlutterHandler(details);
      } else {
        FlutterError.presentError(details);
      }
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      _record(error.toString(), stack, 'async');
      return true; // handled: keep the app alive
    };
  }

  /// Manually log a caught error you still want visible in Diagnostics.
  void recordError(Object error, StackTrace? stack, {String source = 'caught'}) {
    _record(error.toString(), stack, source);
  }

  void _record(String error, StackTrace? stack, String source) {
    final trimmedStack = (stack?.toString() ?? '');
    _records.add(CrashRecord(
      time: DateTime.now(),
      error: error.length > 600 ? '${error.substring(0, 600)}...' : error,
      stack: trimmedStack.length > 2500 ? '${trimmedStack.substring(0, 2500)}...' : trimmedStack,
      source: source,
    ));
    while (_records.length > _maxRecords) {
      _records.removeAt(0);
    }
    _save();
  }

  void _load() {
    final raw = _prefs?.getString(_key);
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      _records
        ..clear()
        ..addAll(list.map((e) => CrashRecord.fromJson(e as Map<String, dynamic>)));
    } catch (_) {
      _records.clear();
    }
  }

  void _save() {
    final prefs = _prefs;
    if (prefs == null) return;
    prefs.setString(_key, jsonEncode(_records.map((r) => r.toJson()).toList()));
  }

  Future<void> clear() async {
    _records.clear();
    await _prefs?.remove(_key);
  }
}
