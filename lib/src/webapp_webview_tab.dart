import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'webapp_controller.dart';
import 'webapp_webview.dart';

class WebappWebviewTab {
  WebappWebviewTab({
    required this.key,
    required this.controller,
    required this.tabIndex,
    this.url,
  }) {
    webview = WebappWebview(
      key: key,
      controller: controller,
      url: url ?? '',
      tab: this,
    );
  }

  final GlobalKey key;
  final WebappController controller;
  final int tabIndex;

  final String? url;

  int? windowId;
  InAppWebViewController? webViewController;
  String? title;

  late WebappWebview webview;

  Future<void> updateTitle(String title) async {
    this.title = title;
  }

  void updateWebViewController(InAppWebViewController webViewController) {
    this.webViewController = webViewController;
  }

  void updateWindowId(int windowId) {
    this.windowId = windowId;
  }

  void dispose() {
    webViewController = null;
  }
}
