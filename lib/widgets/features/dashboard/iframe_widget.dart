import 'package:flutter/material.dart';
import 'package:webviewx_plus/webviewx_plus.dart';

class IFrameWidget extends StatefulWidget {
  const IFrameWidget({super.key});

  @override
  State<IFrameWidget> createState() => _IFrameWidgetState();
}

class _IFrameWidgetState extends State<IFrameWidget> {
  late WebViewXController webviewController;

  @override
  Widget build(BuildContext context) {
    return WebViewX(
      height: 500,
      width: MediaQuery.of(context).size.width,
      initialSourceType: SourceType.url,
      onWebViewCreated: (controller) {
        controller.loadContent(
          'https://flutter.dev',
        );
        return webviewController = controller;
      },
    );
  }
}
