import 'package:flutter/material.dart';
import '../../translations.dart';

class Translations {
  static Future<void> init() async {
    // Translations are loaded in main.dart
  }

  static String tr(
    BuildContext context,
    String key, {
    Map<String, String>? args,
  }) {
    return context.tr(key, args: args);
  }

  static String trWithParams(
    BuildContext context,
    String key,
    Map<String, String> args,
  ) {
    return context.tr(key, args: args);
  }

  static Widget get({Offset? offset, Widget? child}) {
    if (offset != null && child != null) {
      return Transform.translate(offset: offset, child: child);
    }
    return const SizedBox();
  }
}
