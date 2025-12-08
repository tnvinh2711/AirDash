import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux/src/features/receive/application/server_controller.dart';
import 'package:flux/src/features/receive/domain/isolate_event.dart';

/// Auto-decline timeout duration.
const _autoDeclineTimeout = Duration(seconds: 30);

/// Bottom sheet for accepting or declining incoming transfer requests.
///
/// Shows sender info, file details, and countdown timer for auto-decline.
class PendingRequestSheet extends ConsumerStatefulWidget {
  /// Creates a [PendingRequestSheet].
  const PendingRequestSheet({
    required this.request,
    super.key,
  });

  /// The pending transfer request to display.
  final IncomingRequestEvent request;

  @override
  ConsumerState<PendingRequestSheet> createState() =>
      _PendingRequestSheetState();
}

class _PendingRequestSheetState extends ConsumerState<PendingRequestSheet> {
  late Timer _countdownTimer;
  late DateTime _expiresAt;
  int _secondsRemaining = _autoDeclineTimeout.inSeconds;

  @override
  void initState() {
    super.initState();
    _expiresAt = DateTime.now().add(_autoDeclineTimeout);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), _onTick);
  }

  @override
  void dispose() {
    _countdownTimer.cancel();
    super.dispose();
  }

  void _onTick(Timer timer) {
    final remaining = _expiresAt.difference(DateTime.now()).inSeconds;
    if (remaining <= 0) {
      timer.cancel();
      _decline();
    } else {
      setState(() {
        _secondsRemaining = remaining;
      });
    }
  }

  void _accept() {
    ref
        .read(serverControllerProvider.notifier)
        .acceptRequest(widget.request.requestId);
    Navigator.of(context).pop();
  }

  void _decline() {
    ref
        .read(serverControllerProvider.notifier)
        .rejectRequest(widget.request.requestId);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final request = widget.request;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Title with countdown
            Row(
              children: [
                Icon(Icons.download, color: colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Incoming Transfer',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                _CountdownBadge(secondsRemaining: _secondsRemaining),
              ],
            ),
            const SizedBox(height: 20),

            // Sender info
            _InfoRow(
              icon: Icons.person,
              label: 'From',
              value: request.senderAlias,
            ),
            const SizedBox(height: 12),

            // File info
            _InfoRow(
              icon: Icons.insert_drive_file,
              label: 'File',
              value: request.fileName,
            ),
            const SizedBox(height: 12),

            // Size info
            _InfoRow(
              icon: Icons.data_usage,
              label: 'Size',
              value: _formatFileSize(request.fileSize),
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _decline,
                    icon: const Icon(Icons.close),
                    label: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _accept,
                    icon: const Icon(Icons.check),
                    label: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Countdown badge showing seconds remaining.
class _CountdownBadge extends StatelessWidget {
  const _CountdownBadge({required this.secondsRemaining});

  final int secondsRemaining;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isUrgent = secondsRemaining <= 10;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isUrgent
            ? colorScheme.errorContainer
            : colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '${secondsRemaining}s',
        style: TextStyle(
          color: isUrgent
              ? colorScheme.onErrorContainer
              : colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Info row with icon, label, and value.
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

