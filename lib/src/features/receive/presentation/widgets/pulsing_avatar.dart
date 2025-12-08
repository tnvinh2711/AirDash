import 'package:flutter/material.dart';

/// A widget that wraps a child with a pulsing animation effect.
///
/// The pulse effect is controlled by [isActive]. When active, the child
/// scales and fades in a smooth repeating animation. When inactive, the
/// animation stops and resets.
class PulsingAvatar extends StatefulWidget {
  /// Creates a [PulsingAvatar] widget.
  const PulsingAvatar({required this.isActive, required this.child, super.key});

  /// Whether the pulsing animation is active.
  final bool isActive;

  /// The child widget to wrap with the pulse effect.
  final Widget child;

  @override
  State<PulsingAvatar> createState() => _PulsingAvatarState();
}

class _PulsingAvatarState extends State<PulsingAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _opacityAnimation = Tween<double>(
      begin: 0.7,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    if (widget.isActive) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(PulsingAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isActive && _controller.isAnimating) {
      _controller
        ..stop()
        ..reset();
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

    return Stack(
      alignment: Alignment.center,
      children: [
        // Pulsing ring effect
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(
                      alpha: _opacityAnimation.value,
                    ),
                    width: 3,
                  ),
                ),
              ),
            );
          },
        ),
        // Child widget (avatar)
        widget.child,
      ],
    );
  }
}
