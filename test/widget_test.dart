import 'dart:math' as math;

import 'package:beat_check/core/theme/beat_check_theme.dart';
import 'package:beat_check/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App launches and shows tap to start', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const BeatCheckApp());
    expect(find.text('TAP'), findsOneWidget);
  });

  testWidgets('BPM block composite accounts for shadow width', (
    WidgetTester tester,
  ) async {
    const screenSize = Size(400, 800);
    tester.view.physicalSize = screenSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const BeatCheckApp());

    final usableWidth = screenSize.width - 48;
    final blockWidth =
        math.max(220.0, math.min(usableWidth, 360.0)).toDouble();
    final blockHeight = math.max(160.0, blockWidth * 0.56).toDouble();
    final expectedWidth = blockWidth + BeatCheckMetrics.shadowOffset.dx;
    final expectedHeight = blockHeight + BeatCheckMetrics.shadowOffset.dy;

    final compositeFinder = find.byWidgetPredicate(
      (widget) =>
          widget is SizedBox &&
          widget.width != null &&
          widget.height != null &&
          (widget.width! - expectedWidth).abs() < 0.01 &&
          (widget.height! - expectedHeight).abs() < 0.01,
    );

    expect(compositeFinder, findsOneWidget);

    final compositeCenter = tester.getCenter(compositeFinder);
    expect(compositeCenter.dx, closeTo(screenSize.width / 2, 0.01));
  });
}
