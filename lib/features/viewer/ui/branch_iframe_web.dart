// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

class BranchIFrame extends StatelessWidget {
  BranchIFrame({
    super.key,
    required this.url,
    required this.viewType,
  }) {
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
      final element = html.IFrameElement()
        ..src = url
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..allow =
            'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture'
        ..allowFullscreen = true;
      return element;
    });
  }

  final String url;
  final String viewType;

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: viewType);
  }
}
