import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:beat_check/features/tap_tempo/presentation/providers/tap_tempo_provider.dart';
import 'package:beat_check/features/tap_tempo/presentation/screens/tap_tempo_screen.dart';
import 'package:beat_check/core/theme/beat_check_theme.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  runApp(const BeatCheckApp());
}

class BeatCheckApp extends StatelessWidget {
  const BeatCheckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TapTempoProvider(),
      child: MaterialApp(
        title: 'Beat Check',
        debugShowCheckedModeBanner: false,
        theme: BeatCheckTheme.theme,
        home: const TapTempoScreen(),
      ),
    );
  }
}
