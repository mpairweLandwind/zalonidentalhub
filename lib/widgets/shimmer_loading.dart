import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Shimmer effect — animates a gradient sweep across child widgets
// ---------------------------------------------------------------------------
class ShimmerEffect extends StatefulWidget {
  final Widget child;
  const ShimmerEffect({super.key, required this.child});

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = Theme.of(context).colorScheme.surfaceContainerHighest;
    final highlightColor = Theme.of(context).colorScheme.surface;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [baseColor, highlightColor, baseColor],
              stops: const [0.0, 0.5, 1.0],
              transform: _SlidingGradientTransform(_controller.value),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double percent;
  const _SlidingGradientTransform(this.percent);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(
        bounds.width * (percent * 2 - 1), 0, 0);
  }
}

// ---------------------------------------------------------------------------
// Skeleton placeholder box
// ---------------------------------------------------------------------------
class SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Carousel skeleton
// ---------------------------------------------------------------------------
class CarouselSkeleton extends StatelessWidget {
  const CarouselSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SkeletonBox(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.25,
          borderRadius: 12,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Horizontal product list skeleton
// ---------------------------------------------------------------------------
class HorizontalListSkeleton extends StatelessWidget {
  final double cardWidth;
  final double cardHeight;

  const HorizontalListSkeleton({
    super.key,
    this.cardWidth = 160,
    this.cardHeight = 240,
  });

  @override
  Widget build(BuildContext context) {
    final imageHeight = cardWidth * 0.8125;
    return ShimmerEffect(
      child: SizedBox(
        height: cardHeight,
        child: ListView(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          children: List.generate(
            4,
            (_) => Padding(
              padding: const EdgeInsets.only(left: 12),
              child: SizedBox(
                width: cardWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(
                      width: cardWidth,
                      height: imageHeight,
                      borderRadius: 12,
                    ),
                    const SizedBox(height: 8),
                    SkeletonBox(width: cardWidth * 0.75, height: 14),
                    const SizedBox(height: 4),
                    SkeletonBox(width: cardWidth * 0.5, height: 14),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Categories row skeleton
// ---------------------------------------------------------------------------
class CategoriesSkeleton extends StatelessWidget {
  const CategoriesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: SizedBox(
        height: 120,
        child: ListView(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          children: List.generate(
            5,
            (_) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: const [
                  SkeletonBox(width: 70, height: 70, borderRadius: 12),
                  SizedBox(height: 8),
                  SkeletonBox(width: 60, height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Generic section error widget with retry
// ---------------------------------------------------------------------------
class SectionError extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const SectionError({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline,
              size: 40, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 8),
          Text(message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}
