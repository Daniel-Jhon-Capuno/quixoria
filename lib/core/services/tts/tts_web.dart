import 'dart:js_interop';

@JS('quixoriaSpeak')
external void _quixoriaSpeak(JSString text, JSNumber rate, JSString persona, JSFunction onDone);

@JS('quixoriaStop')
external void _quixoriaStop();

@JS('quixoriaPause')
external void _quixoriaPause();

@JS('quixoriaResume')
external void _quixoriaResume();

void platformSpeak(String text, double rate, String persona, void Function() onDone) {
  _quixoriaSpeak(text.toJS, rate.toJS, persona.toJS, (() {
    onDone();
  }).toJS);
}

void platformStop() {
  _quixoriaStop();
}

void platformPause() {
  _quixoriaPause();
}

void platformResume() {
  _quixoriaResume();
}
