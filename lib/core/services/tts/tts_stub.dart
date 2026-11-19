void platformSpeak(String text, double rate, String persona, void Function() onDone) {
  // No-op on non-web / VM targets (e.g. unit tests, desktop)
}

void platformStop() {}

void platformPause() {}

void platformResume() {}
