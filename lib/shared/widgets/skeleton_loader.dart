import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

/// A fluid shimmer skeleton loader for smooth content loading states.
class SkeletonLoader extends StatefulWidget {
  final Widget child;
  final bool loading;

  const SkeletonLoader({
    super.key,
    required this.child,
    this.loading = true,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.loading) return widget.child;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF262626) : const Color(0xFFE8E0D2);
    final highlightColor = isDark ? const Color(0xFF383838) : const Color(0xFFF7F2E8);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final double progress = _controller.value;
            return LinearGradient(
              begin: const Alignment(-1.0, -0.3),
              end: const Alignment(1.0, 0.3),
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: [
                (progress - 0.3).clamp(0.0, 1.0),
                progress.clamp(0.0, 1.0),
                (progress + 0.3).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// A rounded skeleton box placeholder.
class SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE2D9CA),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// A multi-line skeleton text placeholder.
class SkeletonText extends StatelessWidget {
  final int lines;
  final double lineHeight;
  final double spacing;

  const SkeletonText({
    super.key,
    this.lines = 3,
    this.lineHeight = 14,
    this.spacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(lines, (index) {
        final isLast = index == lines - 1;
        return Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : spacing),
          child: LayoutBuilder(
            builder: (ctx, constraints) {
              final w = isLast ? constraints.maxWidth * 0.6 : constraints.maxWidth;
              return SkeletonBox(
                width: w,
                height: lineHeight,
                borderRadius: 4,
              );
            },
          ),
        );
      }),
    );
  }
}

/// Skeleton Card representing a book item in the catalog.
class SkeletonBookCard extends StatelessWidget {
  const SkeletonBookCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.borderLight,
        ),
      ),
      child: const Row(
        children: [
          SkeletonBox(width: 65, height: 95, borderRadius: 10),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 140, height: 16, borderRadius: 4),
                SizedBox(height: 8),
                SkeletonBox(width: 90, height: 12, borderRadius: 4),
                SizedBox(height: 12),
                SkeletonBox(width: 180, height: 10, borderRadius: 4),
              ],
            ),
          ),
          SizedBox(width: 8),
          SkeletonBox(width: 68, height: 36, borderRadius: 12),
        ],
      ),
    );
  }
}

/// Full screen skeleton placeholder for Library, Bazaar, or Dashboard.
class SkeletonScreenPlaceholder extends StatelessWidget {
  const SkeletonScreenPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonBox(width: double.infinity, height: 48, borderRadius: 14),
            const SizedBox(height: 16),
            const Row(
              children: [
                SkeletonBox(width: 72, height: 32, borderRadius: 16),
                SizedBox(width: 8),
                SkeletonBox(width: 90, height: 32, borderRadius: 16),
                SizedBox(width: 8),
                SkeletonBox(width: 84, height: 32, borderRadius: 16),
              ],
            ),
            const SizedBox(height: 24),
            ...List.generate(
              4,
              (index) => const Padding(
                padding: EdgeInsets.only(bottom: 14),
                child: SkeletonBookCard(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
