import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'crash_reporter.dart';

/// Thin wrapper around [SharedPreferences] that stores the whole app state as
/// a versioned JSON document, scoped per account so multiple users on one device
/// never overwrite each other's local progress.
class PersistenceService {
  static const String _legacyStateKey = 'quixoria_state_v1';
  static const String _accountStatePrefix = 'quixoria_state_v2_';
  static const String _corruptBackupPrefix = 'quixoria_corrupt_backup_';

  final SharedPreferences _prefs;
  bool _hadCorruptSaveRecovery = false;

  PersistenceService._(this._prefs);

  static Future<PersistenceService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return PersistenceService._(prefs);
  }

  SharedPreferences get prefs => _prefs;

  bool get hadCorruptSaveRecovery => _hadCorruptSaveRecovery;

  String _keyForAccount(String? accountKey) {
    final normalized = (accountKey ?? '').trim().toLowerCase();
    if (normalized.isEmpty) return _legacyStateKey;
    return '$_accountStatePrefix$normalized';
  }

  Map<String, dynamic>? _decodeRaw(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (e, stack) {
      // Corrupt save: safely preserve the unparseable state in a backup key before starting fresh
      _hadCorruptSaveRecovery = true;
      final backupKey = '$_corruptBackupPrefix${DateTime.now().millisecondsSinceEpoch}';
      _prefs.setString(backupKey, raw);
      CrashReporter.instance.recordError(
        e,
        stack,
        source: 'persistence_recovery',
      );
      return null;
    }
  }

  Map<String, dynamic>? loadState({String? accountKey}) {
    final key = _keyForAccount(accountKey);
    final scoped = _decodeRaw(_prefs.getString(key));
    if (scoped != null) return scoped;

    // Fallback to legacy single-key save if loading default or migrating matching account
    if (key != _legacyStateKey) {
      final legacy = _decodeRaw(_prefs.getString(_legacyStateKey));
      if (legacy != null) {
        final legacyEmail = (legacy['profile'] is Map)
            ? (legacy['profile']['email']?.toString().trim().toLowerCase() ?? '')
            : '';
        final normalized = (accountKey ?? '').trim().toLowerCase();
        if (legacyEmail.isNotEmpty && legacyEmail == normalized) {
          return legacy;
        }
      }
      return null;
    }

    return _decodeRaw(_prefs.getString(_legacyStateKey));
  }

  Future<bool> saveState(Map<String, dynamic> state, {String? accountKey}) async {
    try {
      final encoded = jsonEncode(state);
      final key = _keyForAccount(accountKey);
      final ok = await _prefs.setString(key, encoded);
      if (key == _legacyStateKey) {
        return ok;
      }
      // Also mirror into legacy key only when no accountKey is set; keep accounts isolated
      return ok;
    } catch (e, stack) {
      CrashReporter.instance.recordError(
        e,
        stack,
        source: 'persistence_save',
      );
      return false;
    }
  }

  /// Wipes everything Quixoria stored on this device.
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
