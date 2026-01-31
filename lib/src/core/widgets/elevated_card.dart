import 'package:flutter/material.dart';

/// A card with elevated shadow and hover effect.
///
/// Provides consistent card design with interactive feedback.
class ElevatedCard extends StatefulWidget {
  /// Creates an [ElevatedCard].
  const ElevatedCard({
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.elevation = 2,
    this.hoverElevation = 8,
    this.borderRadius,
    this.color,
    super.key,
  });

  /// The child widget.
  final Widget child;

  /// Callback when card is tapped.
  final VoidCallback? onTap;

  /// Padding inside the card.
  final EdgeInsetsGeometry? padding;

  /// Margin around the card.
  final EdgeInsetsGeometry? margin;

  /// Default elevation.
  final double elevation;

  /// Elevation when hovered.
  final double hoverElevation;

  /// Border radius.
  final BorderRadius? borderRadius;

  /// Background color.
  final Color? color;

  @override
  State<ElevatedCard> createState() => _ElevatedCardState();
}

class _ElevatedCardState extends State<ElevatedCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: widget.margin,
        child: Material(
          elevation: _isHovered ? widget.hoverElevation : widget.elevation,
          borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
          color: widget.color ?? theme.colorScheme.surface,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
            child: Padding(
              padding: widget.padding ?? const EdgeInsets.all(16),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

/// A status chip with icon and label.
class StatusChip extends StatelessWidget {
  /// Creates a [StatusChip].
  const StatusChip({
    required this.label,
    required this.icon,
    this.color,
    this.onTap,
    super.key,
  });

  /// The label text.
  final String label;

  /// The icon to display.
  final IconData icon;

  /// Background color.
  final Color? color;

  /// Callback when chip is tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chipColor = color ?? theme.colorScheme.primaryContainer;

    return Material(
      color: chipColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.onPrimaryContainer),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

