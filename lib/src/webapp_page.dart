import 'package:flutter/material.dart';

import 'webapp_appbar.dart';
import 'webapp_config.dart';
import 'webapp_controller.dart';
import 'webapp_webview_tab.dart';

class WebappPage extends StatefulWidget {
  final List<String> urls;

  const WebappPage(this.urls, {super.key});

  @override
  State<StatefulWidget> createState() => _WebappPageState();
}

class _WebappPageState extends State<WebappPage> {
  final _controller = WebappController();

  PreferredSizeWidget? bottom;

  @override
  void initState() {
    super.initState();

    if (webappConfig.bottom != null) {
      bottom = webappConfig.bottom!(_controller);
    }

    if (_controller.tabs.isEmpty) {
      for (var i = 0; i < widget.urls.length; i++) {
        WebappWebviewTab tab = WebappWebviewTab(
            key: GlobalKey(),
            controller: _controller,
            url: widget.urls[i],
            tabIndex: i);
        _controller.addTab(tab);
      }
      _controller.selectTab(0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> titleReset(WebappController controller) async {
    Future.delayed(const Duration(milliseconds: 200), () {
      var tab = controller.tabs[controller.tabIndex];
      if (tab.title != null) {
        webappConfig.delegate.onTitleChanged!(controller, tab.title);
      } else {
        titleReset(controller);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    titleReset(_controller);

    return Scaffold(
      appBar: !webappConfig.titleHide
          ? WebappAppbar(
              controller: _controller,
              bottom: bottom,
              toolbarHeight: webappConfig.toolbarHeight,
            )
          : null,
      body: Center(
        child: _webview(),
      ),
      bottomNavigationBar: webappConfig.isApp()
          ? webappConfig.navigation(_controller)
          : const SizedBox.shrink(),
    );
  }

  Widget _webview() {
    return ValueListenableBuilder(
      valueListenable: _controller,
      builder: (BuildContext context, value, Widget? child) {
        return IndexedStack(
          index: value.tabIndex,
          children: _controller.getWebviews(),
        );
      },
    );
  }
}
