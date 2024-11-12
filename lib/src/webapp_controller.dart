import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:window_manager/window_manager.dart';

import 'webapp_config.dart';
import 'webapp_webview_tab.dart';
import 'webapp_webview.dart';

class WebappValue {
  WebappValue();

  String title = '';
  int tabIndex = 0;
  bool fullScreen = false;
  bool max = false;

  List<WebappWebviewTab> tabs = [];
}

class WebappController extends ValueNotifier<WebappValue> {
  WebappController() : super(WebappValue()) {
    title = _title;
  }

  final String _title = webappConfig.title;
  String get title => value.title;
  set title(String title) {
    value.title = title;
    notifyListeners();
  }

  void resetTitle(String title) {
    if (!webappConfig.sysTitleHide) {
      windowManager.setTitle(_title == '' ? title : '$_title - $title');
      return;
    }
    if (title != '') {
      this.title = _title == '' ? title : '$_title - $title';
    }
  }

  void resetTitle_() async {
    String? title = await getTitle();
    resetTitle(title ?? '');
  }

  bool get max => value.max;
  set max(bool max) {
    value.max = max;
    notifyListeners();
  }

  bool get fullScreen => value.fullScreen;
  set fullScreen(bool fullScreen) {
    value.fullScreen = fullScreen;
    notifyListeners();
  }

  Future<void> setFullScreen(bool fill) async {
    fullScreen = fill;
    if (webappConfig.isDesktop()) {
      await windowManager.setFullScreen(fullScreen);
      max = await windowManager.isMaximized();
    }
  }

  int get tabIndex => value.tabIndex;
  set tabIndex(int index) {
    value.tabIndex = index;
    notifyListeners();
  }

  List<WebappWebviewTab> get tabs => value.tabs;
  void addTab(WebappWebviewTab tab) {
    value.tabs.add(tab);
    value.tabIndex = tabs.length - 1;
  }

  void removeTab(WebappWebviewTab tab) {
    int index = tabs.indexOf(tab);
    if (index != -1) {
      tab.dispose();
      tabs.remove(tab);
      value.tabIndex--;
    }
  }

  WebappWebviewTab? currentTab;

  void selectTab(int index) {
    value.tabIndex = index;
    currentTab = tabs[index];
    notifyListeners();
  }

  List<WebappWebview> getWebviews() {
    List<WebappWebview> webviews = [];
    for (var tab in tabs) {
      webviews.add(tab.webview);
    }
    return webviews;
  }

  void loadUrl(String url) {
    currentTab?.webViewController?.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
  }

  void back() {
    currentTab?.webViewController?.goBack();
  }

  void home() {
    loadUrl(currentTab?.url ?? '');
  }

  void refresh() {
    currentTab?.webViewController?.reload();
  }

  Future<String?>? getTitle() {
    return currentTab?.webViewController?.getTitle();
  }

}
