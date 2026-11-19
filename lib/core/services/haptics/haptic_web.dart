import 'dart:js_interop';

@JS('quixoriaVibrate')
external void _quixoriaVibrate(JSAny pattern);

void platformVibrate(int ms) {
  try {
    _quixoriaVibrate(ms.toJS);
  } catch (_) {}
}

void platformVibratePattern(List<int> pattern) {
  try {
    final jsList = pattern.map((e) => e.toJS).toList();
    _quixoriaVibrate(jsList.toJS);
  } catch (_) {}
}
