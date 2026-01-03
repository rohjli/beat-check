import 'dart:math' as math;

import 'package:beat_check/core/theme/beat_check_theme.dart';
import 'package:beat_check/features/tap_tempo/presentation/providers/tap_tempo_provider.dart';
import 'package:beat_check/features/tap_tempo/domain/entities/tap_tempo_result.dart';
import 'package:beat_check/features/tap_tempo/domain/entities/tap_tempo_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class TapTempoScreen extends StatefulWidget {
  const TapTempoScreen({super.key});

  @override
  State<TapTempoScreen> createState() => _TapTempoScreenState();
}

class _TapTempoScreenState extends State<TapTempoScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _outlineAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 140),
      vsync: this,
    );
    _scaleAnimation = TweenSequence<double>(
      [
        TweenSequenceItem(
          tween: Tween<double>(begin: 1.0, end: 0.98),
          weight: 45,
        ),
        TweenSequenceItem(
          tween: Tween<double>(begin: 0.98, end: 1.0),
          weight: 55,
        ),
      ],
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeOut));
    _outlineAnimation =
        TweenSequence<Color?>([
          TweenSequenceItem(
            tween: ColorTween(
              begin: BeatCheckColors.black,
              end: BeatCheckColors.acidGreen,
            ),
            weight: 50,
          ),
          TweenSequenceItem(
            tween: ColorTween(
              begin: BeatCheckColors.acidGreen,
              end: BeatCheckColors.black,
            ),
            weight: 50,
          ),
        ]).animate(
          CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
        );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handleTap() {
    final provider = context.read<TapTempoProvider>();
    provider.recordTap();
    if (provider.result.state != TapTempoState.ignored) {
      HapticFeedback.lightImpact();
    }
    _pulseController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            const _GridBackground(),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _handleTap,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final outlineColor =
                      _outlineAnimation.value ?? BeatCheckColors.black;
                  return Consumer<TapTempoProvider>(
                    builder: (context, provider, _) {
                      return _buildContent(
                        context,
                        provider.result,
                        outlineColor,
                        _scaleAnimation,
                      );
                    },
                  );
                },
              ),
            ),
            const Positioned(bottom: 24, right: 24, child: _ResetButton()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    TapTempoResult result,
    Color outlineColor,
    Animation<double> scaleAnimation,
  ) {
    final layout = _LayoutMetrics.from(context);

    switch (result.state) {
      case TapTempoState.idle:
        return _IdleContent(
          layout: layout,
          outlineColor: outlineColor,
          scaleAnimation: scaleAnimation,
        );
      case TapTempoState.collecting:
        return _CollectingContent(
          layout: layout,
          outlineColor: outlineColor,
          scaleAnimation: scaleAnimation,
          tapCount: result.tapCount,
        );
      case TapTempoState.stable:
        return _StableContent(
          layout: layout,
          outlineColor: outlineColor,
          scaleAnimation: scaleAnimation,
          bpm: result.bpm!,
          tapCount: result.tapCount,
        );
      case TapTempoState.ignored:
        return _IgnoredInputContent(
          layout: layout,
          outlineColor: outlineColor,
          scaleAnimation: scaleAnimation,
          bpm: result.bpm,
          tapCount: result.tapCount,
        );
    }
  }
}

class _LayoutMetrics {
  final double blockWidth;
  final double blockHeight;
  final double bpmFontSize;
  final double labelFontSize;
  final double badgeFontSize;
  final double spacingLarge;
  final double spacingSmall;

  const _LayoutMetrics({
    required this.blockWidth,
    required this.blockHeight,
    required this.bpmFontSize,
    required this.labelFontSize,
    required this.badgeFontSize,
    required this.spacingLarge,
    required this.spacingSmall,
  });

  factory _LayoutMetrics.from(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final usableWidth = size.width - 48;
    final blockWidth = math.max(220.0, usableWidth).toDouble();
    final blockHeight = math.max(160.0, blockWidth * 0.56).toDouble();
    final bpmFontSize = math.min(blockWidth * 0.42, 120.0).toDouble();

    return _LayoutMetrics(
      blockWidth: blockWidth,
      blockHeight: blockHeight,
      bpmFontSize: math.max(90.0, bpmFontSize).toDouble(),
      labelFontSize: 18,
      badgeFontSize: 15,
      spacingLarge: 24,
      spacingSmall: 12,
    );
  }
}

class _IdleContent extends StatelessWidget {
  final _LayoutMetrics layout;
  final Color outlineColor;
  final Animation<double> scaleAnimation;

  const _IdleContent({
    required this.layout,
    required this.outlineColor,
    required this.scaleAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return _CenteredColumn(
      children: [
        _ShadowAlignedBlock(
          width: layout.blockWidth,
          height: layout.blockHeight,
          scaleAnimation: scaleAnimation,
          child: _BrutalistBlock(
            borderColor: outlineColor,
            fillColor: BeatCheckColors.white,
            shadowColor: BeatCheckColors.acidGreen,
            child: Center(
              child: Text(
                'TAP\nTO START',
                textAlign: TextAlign.center,
                style: GoogleFonts.bungee(
                  fontSize: layout.bpmFontSize * 0.55,
                  height: 0.9,
                  color: BeatCheckColors.black,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: layout.spacingLarge),
        const _StatusBadge(text: 'READY', isActive: true),
      ],
    );
  }
}

class _CollectingContent extends StatelessWidget {
  final _LayoutMetrics layout;
  final Color outlineColor;
  final Animation<double> scaleAnimation;
  final int tapCount;

  const _CollectingContent({
    required this.layout,
    required this.outlineColor,
    required this.scaleAnimation,
    required this.tapCount,
  });

  @override
  Widget build(BuildContext context) {
    return _CenteredColumn(
      children: [
        _BpmBlock(
          layout: layout,
          outlineColor: outlineColor,
          scaleAnimation: scaleAnimation,
          bpmText: '--',
        ),
        SizedBox(height: layout.spacingLarge),
        Text(
          'KEEP TAPPING',
          style: GoogleFonts.spaceGrotesk(
            fontSize: layout.labelFontSize,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
            color: BeatCheckColors.warmGray,
          ),
        ),
        SizedBox(height: layout.spacingSmall),
        _StatusBadge(text: '$tapCount TAPS'),
      ],
    );
  }
}

class _StableContent extends StatelessWidget {
  final _LayoutMetrics layout;
  final Color outlineColor;
  final Animation<double> scaleAnimation;
  final double bpm;
  final int tapCount;

  const _StableContent({
    required this.layout,
    required this.outlineColor,
    required this.scaleAnimation,
    required this.bpm,
    required this.tapCount,
  });

  @override
  Widget build(BuildContext context) {
    return _CenteredColumn(
      children: [
        _BpmBlock(
          layout: layout,
          outlineColor: outlineColor,
          scaleAnimation: scaleAnimation,
          bpmText: bpm.round().toString(),
        ),
        SizedBox(height: layout.spacingLarge),
        _StatusBadge(text: '$tapCount TAPS'),
      ],
    );
  }
}

class _IgnoredInputContent extends StatelessWidget {
  final _LayoutMetrics layout;
  final Color outlineColor;
  final Animation<double> scaleAnimation;
  final double? bpm;
  final int tapCount;

  const _IgnoredInputContent({
    required this.layout,
    required this.outlineColor,
    required this.scaleAnimation,
    required this.bpm,
    required this.tapCount,
  });

  @override
  Widget build(BuildContext context) {
    return _CenteredColumn(
      children: [
        Opacity(
          opacity: 0.55,
          child: _BpmBlock(
            layout: layout,
            outlineColor: outlineColor,
            scaleAnimation: scaleAnimation,
            bpmText: bpm?.round().toString() ?? '--',
          ),
        ),
        SizedBox(height: layout.spacingLarge),
        const _WarningStrip(text: 'TAP TOO FAST'),
        SizedBox(height: layout.spacingSmall),
        _StatusBadge(text: '$tapCount TAPS'),
      ],
    );
  }
}

class _CenteredColumn extends StatelessWidget {
  final List<Widget> children;

  const _CenteredColumn({required this.children});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: children,
      ),
    );
  }
}

class _BpmBlock extends StatelessWidget {
  final _LayoutMetrics layout;
  final Color outlineColor;
  final Animation<double> scaleAnimation;
  final String bpmText;

  const _BpmBlock({
    required this.layout,
    required this.outlineColor,
    required this.scaleAnimation,
    required this.bpmText,
  });

  @override
  Widget build(BuildContext context) {
    final shadowOffset = BeatCheckMetrics.shadowOffset;
    return _ShadowAlignedBlock(
      width: layout.blockWidth,
      height: layout.blockHeight,
      scaleAnimation: scaleAnimation,
      child: _BrutalistBlock(
        borderColor: outlineColor,
        width: layout.blockWidth + shadowOffset.dx,
        height: layout.blockHeight + shadowOffset.dy,
        fillColor: BeatCheckColors.white,
        shadowColor: BeatCheckColors.acidGreen,
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                bpmText,
                maxLines: 1,
                style: GoogleFonts.bungee(
                  fontSize: layout.bpmFontSize,
                  height: 0.95,
                  color: BeatCheckColors.black,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'BPM',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: layout.labelFontSize,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                  color: BeatCheckColors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShadowAlignedBlock extends StatelessWidget {
  final double width;
  final double height;
  final Animation<double> scaleAnimation;
  final Widget child;

  const _ShadowAlignedBlock({
    required this.width,
    required this.height,
    required this.scaleAnimation,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final shadowOffset = BeatCheckMetrics.shadowOffset;
    return ScaleTransition(
      scale: scaleAnimation,
      alignment: Alignment.center,
      child: SizedBox(
        width: width + shadowOffset.dx,
        height: height + shadowOffset.dy,
        child: child,
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String text;
  final bool isActive;

  const _StatusBadge({required this.text, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return _BrutalistBlock(
      borderColor: BeatCheckColors.black,
      fillColor: isActive ? BeatCheckColors.acidGreen : BeatCheckColors.white,
      shadowColor: BeatCheckColors.black,
      shadowOffset: const Offset(4, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        text,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          color: BeatCheckColors.black,
        ),
      ),
    );
  }
}

class _WarningStrip extends StatelessWidget {
  final String text;

  const _WarningStrip({required this.text});

  @override
  Widget build(BuildContext context) {
    return _BrutalistBlock(
      borderColor: BeatCheckColors.black,
      fillColor: BeatCheckColors.acidGreen,
      shadowColor: BeatCheckColors.black,
      shadowOffset: const Offset(6, 6),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Text(
        text,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          color: BeatCheckColors.black,
        ),
      ),
    );
  }
}

class _ResetButton extends StatelessWidget {
  const _ResetButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        context.read<TapTempoProvider>().reset();
      },
      child: SizedBox(
        width: 56,
        height: 56,
        child: _BrutalistBlock(
          borderColor: BeatCheckColors.black,
          fillColor: BeatCheckColors.white,
          shadowColor: BeatCheckColors.acidGreen,
          shadowOffset: const Offset(6, 6),
          child: const Icon(Icons.refresh, color: BeatCheckColors.black),
        ),
      ),
    );
  }
}

class _BrutalistBlock extends StatelessWidget {
  final Widget child;
  final Color fillColor;
  final Color borderColor;
  final Color shadowColor;
  final Offset shadowOffset;
  final EdgeInsetsGeometry padding;
  final double? width;
  final double? height;

  const _BrutalistBlock({
    required this.child,
    required this.fillColor,
    required this.borderColor,
    required this.shadowColor,
    this.shadowOffset = BeatCheckMetrics.shadowOffset,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final blockContent = Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: Transform.translate(
            offset: shadowOffset,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: shadowColor,
                border: Border.all(
                  color: borderColor,
                  width: BeatCheckMetrics.borderWidth,
                ),
                borderRadius: BorderRadius.circular(
                  BeatCheckMetrics.cornerRadius,
                ),
              ),
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: fillColor,
            border: Border.all(
              color: borderColor,
              width: BeatCheckMetrics.borderWidth,
            ),
            borderRadius: BorderRadius.circular(BeatCheckMetrics.cornerRadius),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ],
    );

    if (width != null || height != null) {
      return SizedBox(
        width: width,
        height: height,
        child: blockContent,
      );
    }
    return blockContent;
  }
}

class _GridBackground extends StatelessWidget {
  const _GridBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.infinite, painter: _GridPainter());
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = BeatCheckColors.darkGray.withValues(alpha: 0.4)
      ..strokeWidth = 1;

    const double spacing = 32;

    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
