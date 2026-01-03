import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:beat_check/features/tap_tempo/presentation/screens/tap_tempo_screen.dart';
import 'package:beat_check/features/tap_tempo/presentation/providers/tap_tempo_provider.dart';

void main() {
  group('TapTempoScreen', () {
    late TapTempoProvider provider;

  setUp(() {
    provider = TapTempoProvider();
  });

  tearDown(() {
    provider.dispose();
  });

    Widget createTestWidget() {
      return MaterialApp(
        home: ChangeNotifierProvider.value(
          value: provider,
          child: const TapTempoScreen(),
        ),
      );
    }

    testWidgets('shows "Tap to Start" in idle state', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.text('TAP\nTO START'), findsOneWidget);
    });

    testWidgets('has full-screen tap area', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('has reset button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('tapping screen records tap', (tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump();

      expect(provider.result.tapCount, 1);
      provider.reset();
    });

    testWidgets('shows tap count after first tap', (tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump();

      expect(find.textContaining('1'), findsWidgets);
      provider.reset();
    });

    testWidgets('reset button clears state', (tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump();

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();

      expect(provider.result.tapCount, 0);
      expect(find.text('TAP\nTO START'), findsOneWidget);
    });
  });
}
