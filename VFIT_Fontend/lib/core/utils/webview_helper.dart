import 'webview_helper_stub.dart'
    if (dart.library.js) 'webview_helper_web.dart' as helper;

bool checkAndHandleWebViewGoogleLogin() {
  return helper.handleGoogleLoginWebView();
}
