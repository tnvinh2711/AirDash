import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The breakpoint width for switching between NavigationBar and NavigationRail.
///
/// Below this width, a bottom NavigationBar is used (mobile).
/// At or above this width, a side NavigationRail is used (desktop).
const double _kNavigationBreakpoint = 600;

/// A scaffold that wraps the main content with responsive navigation.
///
/// This widget provides the shell for the main navigation structure,
/// adapting between [NavigationBar] (bottom) for narrow screens and
/// [NavigationRail] (side) for wider screens based on a 600px breakpoint.
class ScaffoldWithNavBar extends StatelessWidget {
  /// Creates a [ScaffoldWithNavBar] widget.
  ///
  /// The [navigationShell] provides access to the current navigation state
  /// and the child widget to display for the current route.
  const ScaffoldWithNavBar({
    required this.navigationShell,
    super.key,
  });

  /// The navigation shell that manages the current tab state.
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _kNavigationBreakpoint) {
          // Mobile layout: bottom NavigationBar
          return _buildMobileLayout();
        } else {
          // Desktop layout: side NavigationRail
          return _buildDesktopLayout();
        }
      },
    );
  }

  /// Builds the mobile layout with a bottom NavigationBar.
  Widget _buildMobileLayout() {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.download_outlined),
            selectedIcon: Icon(Icons.download),
            label: 'Receive',
          ),
          NavigationDestination(
            icon: Icon(Icons.upload_outlined),
            selectedIcon: Icon(Icons.upload),
            label: 'Send',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  /// Builds the desktop layout with a side NavigationRail.
  Widget _buildDesktopLayout() {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: _onDestinationSelected,
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.download_outlined),
                selectedIcon: Icon(Icons.download),
                label: Text('Receive'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.upload_outlined),
                selectedIcon: Icon(Icons.upload),
                label: Text('Send'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('Settings'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }

  /// Handles navigation when a destination is selected.
  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      // Navigate to the initial location of the branch if already on it
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
