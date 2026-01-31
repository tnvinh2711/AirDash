import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// About section showing app information.
///
/// Displays app version, build number, and links.
class AboutSection extends StatelessWidget {
  /// Creates an [AboutSection] widget.
  const AboutSection({required this.packageInfo, super.key});

  /// Package information.
  final PackageInfo packageInfo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'About',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // App Name & Version
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.bolt,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              title: Text(
                packageInfo.appName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'Version ${packageInfo.version} (${packageInfo.buildNumber})',
              ),
            ),
            const Divider(),

            // GitHub Link
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.code),
              title: const Text('Source Code'),
              subtitle: const Text('github.com/tnvinh2711/AirDash'),
              trailing: const Icon(Icons.open_in_new, size: 20),
              onTap: () => _launchUrl('https://github.com/tnvinh2711/AirDash'),
            ),

            // License
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.gavel),
              title: const Text('License'),
              subtitle: const Text('MIT License'),
              trailing: const Icon(Icons.open_in_new, size: 20),
              onTap: () => showLicensePage(
                context: context,
                applicationName: packageInfo.appName,
                applicationVersion: packageInfo.version,
                applicationIcon: Icon(
                  Icons.bolt,
                  size: 48,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

