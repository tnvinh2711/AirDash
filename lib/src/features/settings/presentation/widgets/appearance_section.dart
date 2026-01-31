import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux/src/features/settings/application/settings_controller.dart';

/// Appearance settings section.
///
/// Allows users to configure theme mode and color scheme.
class AppearanceSection extends ConsumerWidget {
  /// Creates an [AppearanceSection] widget.
  const AppearanceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsControllerProvider);
    final theme = Theme.of(context);

    return settingsAsync.when(
      data: (settings) => Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.palette, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Text(
                    'Appearance',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Theme Mode
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Theme Mode'),
                subtitle: Text(_getThemeModeLabel(settings.themeMode)),
                trailing: SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode, size: 16),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode, size: 16),
                    ),
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: Icon(Icons.auto_mode, size: 16),
                    ),
                  ],
                  selected: {settings.themeMode},
                  onSelectionChanged: (Set<ThemeMode> newSelection) {
                    ref
                        .read(settingsControllerProvider.notifier)
                        .setThemeMode(newSelection.first);
                  },
                ),
              ),
              const Divider(),

              // Color Scheme
              const Text('Color Scheme'),
              const SizedBox(height: 12),
              SizedBox(
                height: 80,
                child: _buildColorSchemePicker(ref, settings.colorScheme),
              ),
            ],
          ),
        ),
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  String _getThemeModeLabel(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
      ThemeMode.system => 'System',
    };
  }

  String _getColorSchemeLabel(FlexScheme scheme) {
    return scheme.name[0].toUpperCase() + scheme.name.substring(1);
  }

  Widget _buildColorSchemePicker(WidgetRef ref, FlexScheme currentScheme) {
    // Diverse color schemes with different hues
    final schemes = [
      FlexScheme.material,      // Blue
      FlexScheme.red,           // Red
      FlexScheme.deepPurple,    // Purple
      FlexScheme.green,         // Green
      FlexScheme.amber,         // Orange/Yellow
      FlexScheme.indigo,        // Indigo
      FlexScheme.pinkM3,        // Pink M3
      FlexScheme.tealM3,        // Teal M3
      FlexScheme.deepOrangeM3,  // Deep Orange M3
      FlexScheme.purpleM3,      // Purple M3
      FlexScheme.money,         // Green Money
      FlexScheme.sakura,        // Pink Sakura
      FlexScheme.mango,         // Orange Mango
      FlexScheme.espresso,      // Brown
      FlexScheme.aquaBlue,      // Aqua Blue
      FlexScheme.brandBlue,     // Brand Blue
      FlexScheme.damask,        // Red Damask
      FlexScheme.mallardGreen,  // Green Mallard
      FlexScheme.outerSpace,    // Dark Blue
      FlexScheme.blueWhale,     // Navy Blue
      FlexScheme.gold,          // Gold
      FlexScheme.wasabi,        // Wasabi Green
    ];

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: schemes.length,
      itemBuilder: (context, index) {
        final scheme = schemes[index];
        final isSelected = scheme == currentScheme;
        final schemeData = FlexThemeData.light(scheme: scheme).colorScheme;

        return Padding(
          padding: const EdgeInsets.only(right: 12),
          child: InkWell(
            onTap: () {
              ref.read(settingsControllerProvider.notifier).setColorScheme(
                    scheme,
                  );
            },
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? schemeData.primary
                      : Colors.transparent,
                  width: 3,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          schemeData.primary,
                          schemeData.secondary,
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: schemeData.primary.withOpacity(0.4),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getColorSchemeLabel(scheme),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

