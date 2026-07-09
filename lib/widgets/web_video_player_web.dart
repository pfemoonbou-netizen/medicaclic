// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

final _registered = <String>{};

Widget buildWebVideoPlayer(String url) {
  final viewId = 'reel-video-${url.hashCode}';
  if (!_registered.contains(viewId)) {
    _registered.add(viewId);
    ui_web.platformViewRegistry.registerViewFactory(viewId, (_) {
      return html.VideoElement()
        ..src = url
        ..autoplay = true
        ..loop = true
        ..muted = true
        ..setAttribute('playsinline', 'true')
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover';
    });
  }
  return HtmlElementView(viewType: viewId);
}
