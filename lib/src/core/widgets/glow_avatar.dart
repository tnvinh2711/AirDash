import 'package:flutter/material.dart';

/// An avatar with animated glow effect.
///
/// Used for device identity display with pulsing animation.
class GlowAvatar extends StatefulWidget {
  /// Creates a [GlowAvatar].
  const GlowAvatar({
    required this.icon,
    required this.isActive,
    this.size = 120,
    this.glowColor,
    super.key,
  });

  /// The icon to display.
  final IconData icon;

  /// Whether the glow effect is active.
  final bool isActive;

  /// Size of the avatar.
  final double size;

  /// Custom glow color. If null, uses primary color.
  final Color? glowColor;

  @override
  State<GlowAvatar> createState() => _GlowAvatarState();
}

class _GlowAvatarState extends State<GlowAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isActive) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(GlowAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.value = 0.5;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glowColor = widget.glowColor ?? theme.colorScheme.primary;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: widget.isActive
                ? [
                    BoxShadow(
                      color: glowColor.withOpacity(0.4 * _animation.value),
                      blurRadius: 30 * _animation.value,
                      spreadRadius: 10 * _animation.value,
                    ),
                  ]
                : null,
          ),
          child: child,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primaryContainer,
              theme.colorScheme.primary,
            ],
          ),
        ),
        child: Icon(
          widget.icon,
          size: widget.size * 0.5,
          color: theme.colorScheme.onPrimary,
        ),
      ),
    );
  }
}

