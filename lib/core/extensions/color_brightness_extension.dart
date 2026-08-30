import 'package:flutter/material.dart';

extension ColorBrightness on Color {
  /// True when text on top of this colour should be dark. Used to pick status
  /// bar icon brightness against whatever colour the app bar happens to be.
  bool get isLight => computeLuminance() > 0.5;
}
