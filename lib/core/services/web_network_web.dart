import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

bool isWebPlatform() => true;

bool getWebNavigatorOnline() {
  try {
    return web.window.navigator.onLine;
  } catch (_) {
    return true;
  }
}

Stream<bool>? getWebConnectivityStream() {
  StreamController<bool>? controller;
  JSFunction? onOnlineHandler;
  JSFunction? onOfflineHandler;

  controller = StreamController<bool>.broadcast(
    onListen: () {
      try {
        final onOnlineCallback = ((web.Event _) {
          controller?.add(true);
        }).toJS;
        final onOfflineCallback = ((web.Event _) {
          controller?.add(false);
        }).toJS;

        onOnlineHandler = onOnlineCallback;
        onOfflineHandler = onOfflineCallback;

        web.window.addEventListener('online', onOnlineHandler);
        web.window.addEventListener('offline', onOfflineHandler);
      } catch (_) {}
    },
    onCancel: () {
      try {
        if (onOnlineHandler != null) {
          web.window.removeEventListener('online', onOnlineHandler);
        }
        if (onOfflineHandler != null) {
          web.window.removeEventListener('offline', onOfflineHandler);
        }
      } catch (_) {}
    },
  );

  return controller.stream;
}
