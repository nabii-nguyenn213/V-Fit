import 'dart:js' as js;

bool handleGoogleLoginWebView() {
  try {
    return js.context.callMethod('handleGoogleLoginWebView') as bool;
  } catch (e) {
    return false;
  }
}
