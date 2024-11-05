import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'webapp_controller.dart';

class WebappSysBar extends StatefulWidget {
  const WebappSysBar({super.key, required this.controller});

  final WebappController controller;

  @override
  State<StatefulWidget> createState() => _WebappSysBarState();
}

class _WebappSysBarState extends State<WebappSysBar> {
  ButtonStyle style = ButtonStyle(
      shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))));

  @override
  void initState() {
    super.initState();
  }

  Future<void> maxOrRestore() async {
    if (widget.controller.max) {
      await windowManager.restore();
    } else {
      await windowManager.maximize();
    }
  }

  Future<void> restore() async {
    await windowManager.restore();
  }

  void close() {
    windowManager.close();
  }

  void minimize() {
    windowManager.minimize();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: widget.controller,
        builder: (context, value, child) {
          return Row(
            children: [
              setMinimize(),
              const SizedBox(
                width: 6,
              ),
              setMaximize(),
              const SizedBox(
                width: 6,
              ),
              IconButton(
                onPressed: close,
                icon: const Icon(
                  Icons.close,
                ),
                style: style,
                color: Colors.white,
              )
            ],
          );
        });
  }

  Widget setMaximize() {
    return widget.controller.max
        ? IconButton(
            onPressed: maxOrRestore,
            icon: const Icon(
              Icons.fullscreen_exit,
            ),
            style: style,
            color: Colors.white,
          )
        : IconButton(
            onPressed: maxOrRestore,
            icon: const Icon(
              Icons.fullscreen,
            ),
            style: style,
            color: Colors.white,
          );
  }

  Widget setMinimize() {
    return IconButton(
      onPressed: minimize,
      icon: const Icon(Icons.remove),
      style: style,
      color: Colors.white,
    );
  }
}
