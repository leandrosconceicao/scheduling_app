import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scheduling_app/src/core/themes/theme.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();

  return (max(la, lb) + .05) / (min(la, lb) + .05);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  test("o texto do FilledButton atinge o contraste AA sobre o fundo", () {
    final style = appTheme.filledButtonTheme.style!;

    final foreground = style.foregroundColor!.resolve({})!;
    final background = style.backgroundColor!.resolve({})!;

    expect(foreground, black);
    expect(style.iconColor!.resolve({}), black);
    expect(_contrast(foreground, background), greaterThanOrEqualTo(4.5));
  });
}
