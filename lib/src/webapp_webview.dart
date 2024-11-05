import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

import 'webapp_javascript.dart';
import 'webapp_config.dart';
import 'webapp_controller.dart';
import 'webapp_webview_tab.dart';

class WebappWebview extends StatefulWidget {
  const WebappWebview(
      {super.key,
      required this.controller,
      required this.url,
      required this.tab});

  final WebappController controller;
  final String url;

  final WebappWebviewTab tab;

  @override
  State<WebappWebview> createState() => _WebappWebviewState();
}

class _WebappWebviewState extends State<WebappWebview>
    with WidgetsBindingObserver {
  InAppWebViewSettings settings = InAppWebViewSettings(
      // isInspectable: kDebugMode,
      mediaPlaybackRequiresUserGesture: false,
      allowsInlineMediaPlayback: true,
      iframeAllow: "camera; microphone",
      supportMultipleWindows: true,
      iframeAllowFullscreen: true);

  PullToRefreshController? pullToRefreshController;

  late WebappController controller;
  InAppWebViewController? webViewController;
  late String pageStart;

  double _progress = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    controller = widget.controller;

    pullToRefreshController = kIsWeb ||
            ![TargetPlatform.iOS, TargetPlatform.android]
                .contains(defaultTargetPlatform)
        ? null
        : PullToRefreshController(
            settings: PullToRefreshSettings(
              color: Colors.blue,
            ),
            onRefresh: () async {
              if (defaultTargetPlatform == TargetPlatform.android) {
                webViewController?.reload();
              } else if (defaultTargetPlatform == TargetPlatform.iOS) {
                webViewController?.loadUrl(
                    urlRequest:
                        URLRequest(url: await webViewController?.getUrl()));
              }
            },
          );

    pageStart = """
    (function() {                  
      function Webapp() {
        
      }
      Webapp.prototype.postMessage = function(name, args, callee) {
          var data = JSON.stringify(args);
          window.flutter_inappwebview.callHandler('_webapp', name, data)
            .then(function(data) {
              if (callee) {
                callee(data);
              }
            });
      };
      window.webapp = new Webapp();  
    })();      
    """;
    if (isWindows()) {
      pageStart += """
      document.addEventListener("fullscreenchange", (event) => {
        webapp.postMessage("fullscreen", document.fullscreenElement != null);
      });
      """;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  bool isAndroid() {
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  }

  bool isWindows() {
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (webViewController != null && (isAndroid() || isWindows())) {
      if (state == AppLifecycleState.paused) {
        pauseAll();
      } else {
        resumeAll();
      }
    }
  }

  void pauseAll() {
    if (isAndroid() || isWindows()) {
      webViewController?.pause();
    }
    pauseTimers();
  }

  void resumeAll() {
    if (isAndroid() || isWindows()) {
      webViewController?.resume();
    }
    resumeTimers();
  }

  void pause() {
    if (isAndroid() || isWindows()) {
      webViewController?.pause();
    }
  }

  void resume() {
    if (isAndroid() || isWindows()) {
      webViewController?.resume();
    }
  }

  void pauseTimers() {
    if (!isWindows()) {
      webViewController?.pauseTimers();
    }
  }

  void resumeTimers() {
    if (!isWindows()) {
      webViewController?.resumeTimers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          InAppWebView(
            webViewEnvironment: webappConfig.webViewEnvironment,
            initialUrlRequest: URLRequest(url: WebUri(widget.url)),
            initialSettings: settings,
            initialUserScripts: UnmodifiableListView<UserScript>([
              UserScript(
                  source: pageStart,
                  injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START),
            ]),
            pullToRefreshController: pullToRefreshController,
            onWebViewCreated: (controller) {
              webViewController = controller;
              widget.tab.webViewController = controller;

              controller.addJavaScriptHandler(
                  handlerName: '_webapp',
                  callback: (args) {
                    dynamic result;
                    if (args.length == 2) {
                      var name = args[0];
                      if (JavaScriptHandler.handles.containsKey(name)) {
                        var method = JavaScriptHandler.handles[name];
                        var data = jsonDecode(args[1]);
                        result = jsonEncode(method(widget.controller, data));
                      }
                    }
                    // return data to the JavaScript side!
                    return result;
                  });
            },
            onLoadStart: (controller, uri) {
              if (webappConfig.delegate.onLoadStart != null) {
                webappConfig.delegate.onLoadStart!(widget.controller, uri);
              }
            },
            onLoadStop: (controller, uri) {
              if (webappConfig.delegate.onLoadStop != null) {
                webappConfig.delegate.onLoadStop!(widget.controller, uri);
              }
            },
            onProgressChanged: (controller, progress) {
              if (webappConfig.delegate.onProgressChanged != null) {
                webappConfig.delegate.onProgressChanged!(
                    widget.controller, progress);
              } else {
                setState(() {
                  _progress = progress / 100;
                });
              }
            },
            onEnterFullscreen: (controller) {
              if (webappConfig.delegate.onEnterFullscreen != null) {
                webappConfig.delegate.onEnterFullscreen!(widget.controller);
              } else {
                widget.controller.setFullScreen(false);
              }
            },
            onExitFullscreen: (controller) {
              if (webappConfig.delegate.onExitFullscreen != null) {
                webappConfig.delegate.onExitFullscreen!(widget.controller);
              } else {
                widget.controller.setFullScreen(false);
              }
            },
            onTitleChanged: (controller, title) {
              widget.tab.title = title;
            },
            onReceivedHttpError: (controller, request, errorResponse) {
              if (webappConfig.delegate.onReceivedHttpError != null) {
                webappConfig.delegate.onReceivedHttpError!(
                    widget.controller, request, errorResponse);
              }
            },
            onDownloadStartRequest: (controller, request) {
              if (webappConfig.delegate.onDownloadStartRequest != null) {
                webappConfig.delegate.onDownloadStartRequest!(
                    widget.controller, request);
              }
            },
            shouldOverrideUrlLoading: (controller, navigationAction) async {
              var uri = navigationAction.request.url!;

              if (![
                "http",
                "https",
                "file",
                "chrome",
                "data",
                "javascript",
                "about"
              ].contains(uri.scheme)) {
                if (await canLaunchUrl(uri)) {
                  // Launch the App
                  await launchUrl(
                    uri,
                  );
                  // and cancel the request
                  return NavigationActionPolicy.CANCEL;
                }
              }

              return NavigationActionPolicy.ALLOW;
            },
            onPermissionRequest: (controller, request) async {
              return PermissionResponse(
                  resources: request.resources,
                  action: PermissionResponseAction.GRANT);
            },
            onConsoleMessage: (controller, message) {
              if (webappConfig.delegate.onConsoleMessage != null) {
                webappConfig.delegate.onConsoleMessage!(
                    widget.controller, message);
              }
            },
            onCreateWindow: (controller, createWindowAction) async {
              widget.tab.windowId = createWindowAction.windowId;
              return false;
            },
            onCloseWindow: (controller) {
              widget.controller.removeTab(widget.tab);
            },
          ),
          webappConfig.delegate.onProgressChanged == null
              ? _progress < 1.0
                  ? LinearProgressIndicator(
                      value: _progress,
                    )
                  : const SizedBox.shrink()
              : const SizedBox.shrink(),
        ],
      ),
    );
  }
}
