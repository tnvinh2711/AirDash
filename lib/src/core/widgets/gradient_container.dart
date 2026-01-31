import 'package:flutter/material.dart';

/// A container with gradient background.
///
/// Provides a consistent gradient design across the app.
class GradientContainer extends StatelessWidget {
  /// Creates a [GradientContainer].
  const GradientContainer({
    required this.child,
    this.gradient,
    this.borderRadius,
    this.padding,
    super.key,
  });

  /// The child widget.
  final Widget child;

  /// Custom gradient. If null, uses theme-based gradient.
  final Gradient? gradient;

  /// Border radius for the container.
  final BorderRadius? borderRadius;

  /// Padding inside the container.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        theme.colorScheme.primaryContainer,
        theme.colorScheme.secondaryContainer,
      ],
    );

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: gradient ?? defaultGradient,
        borderRadius: borderRadius ?? BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

/// A hero section with gradient background and glow effect.
class HeroGradientSection extends StatelessWidget {
  /// Creates a [HeroGradientSection].
  const HeroGradientSection({
    required this.child,
    this.height,
    super.key,
  });

  /// The child widget.
  final Widget child;

  /// Height of the hero section.
  final double? height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.colorScheme.primary.withOpacity(0.15),
            theme.colorScheme.surface,
          ],
        ),
      ),
      child: child,
    );
  }
}

