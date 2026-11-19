import 'dart:async';

bool isWebPlatform() => false;
bool getWebNavigatorOnline() => true;
Stream<bool>? getWebConnectivityStream() => null;
