import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux/src/features/settings/application/settings_controller.dart';
import 'package:flux/src/features/settings/presentation/widgets/about_section.dart';
import 'package:flux/src/features/settings/presentation/widgets/appearance_section.dart';
import 'package:flux/src/features/settings/presentation/widgets/device_section.dart';
import 'package:flux/src/features/settings/presentation/widgets/storage_section.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// The Settings screen - displays app configuration options.
///
/// Shows theme settings, device configuration, storage options, and app info.
class SettingsScreen extends ConsumerStatefulWidget {
  /// Creates a [SettingsScreen] widget.
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animationController.forward();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() => _packageInfo = info);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: settingsAsync.when(
        data: (settings) => _buildContent(context, settings),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading settings: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(settingsControllerProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, dynamic settings) {
    final sections = [
      const AppearanceSection(),
      const DeviceSection(),
      const StorageSection(),
      if (_packageInfo != null) AboutSection(packageInfo: _packageInfo!),
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: sections.length,
      itemBuilder: (context, index) {
        // Staggered animation for each section
        final delay = index * 0.1;
        final animation = CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            delay,
            delay + 0.4,
            curve: Curves.easeOutCubic,
          ),
        );

        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - animation.value)),
              child: Opacity(
                opacity: animation.value,
                child: child,
              ),
            );
          },
          child: sections[index],
        );
      },
    );
  }
}
