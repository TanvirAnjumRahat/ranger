import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home_screen.dart';
import 'analytics_screen.dart';
import 'calendar_screen.dart';
import 'goals_screen.dart';
import 'settings_screen.dart';
import 'templates_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/routine_provider.dart';
import '../providers/notifications_provider.dart';
import '../routes.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Widget> _screens = const [
    HomeScreen(),
    AnalyticsScreen(),
    CalendarScreen(),
    GoalsScreen(),
    SettingsScreen(),
  ];

  final List<String> _titles = const [
    'My Routines',
    'Analytics',
    'Calendar',
    'Goals',
    'Settings',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
          tooltip: 'Menu',
        ),
        title: Text(_titles[_currentIndex]),
        actions: [
          if (_currentIndex == 0) ...[
            // Home screen actions
            IconButton(
              icon: const Icon(Icons.notifications_active_outlined),
              tooltip: 'Notifications',
              onPressed: () => _showNotificationsDialog(context),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) => _handleHomeMenuAction(context, value),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'refresh',
                  child: Row(
                    children: [
                      Icon(Icons.refresh),
                      SizedBox(width: 8),
                      Text('Refresh'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'export_all',
                  child: Row(
                    children: [
                      Icon(Icons.upload),
                      SizedBox(width: 8),
                      Text('Export All'),
                    ],
                  ),
                ),
              ],
            ),
          ],
          if (_currentIndex == 3) ...[
            // Goals screen actions
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) => _handleGoalsMenuAction(context, value),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'filter',
                  child: Row(
                    children: [
                      Icon(Icons.filter_list),
                      SizedBox(width: 8),
                      Text('Filter'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'sort',
                  child: Row(
                    children: [
                      Icon(Icons.sort),
                      SizedBox(width: 8),
                      Text('Sort'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      drawer: _buildDrawer(context),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          height: 70,
          elevation: 0,
          backgroundColor: Theme.of(context).colorScheme.surface,
          indicatorColor: Theme.of(context).colorScheme.primaryContainer,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Routines',
            ),
            NavigationDestination(
              icon: Icon(Icons.analytics_outlined),
              selectedIcon: Icon(Icons.analytics),
              label: 'Analytics',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_today_outlined),
              selectedIcon: Icon(Icons.calendar_today),
              label: 'Calendar',
            ),
            NavigationDestination(
              icon: Icon(Icons.flag_outlined),
              selectedIcon: Icon(Icons.flag),
              label: 'Goals',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primaryContainer,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(
                Icons.person,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            accountName: const Text(
              'Routine Ranger',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            accountEmail: Text(user?.email ?? 'user@example.com'),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.home,
            title: 'My Routines',
            index: 0,
          ),
          _buildDrawerItem(
            context,
            icon: Icons.analytics,
            title: 'Analytics',
            index: 1,
          ),
          _buildDrawerItem(
            context,
            icon: Icons.calendar_today,
            title: 'Calendar',
            index: 2,
          ),
          _buildDrawerItem(
            context,
            icon: Icons.flag,
            title: 'Goals',
            index: 3,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.auto_awesome),
            title: const Text('Browse Templates'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/templates');
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              setState(() {
                _currentIndex = 4;
              });
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            onTap: () {
              Navigator.pop(context);
              showAboutDialog(
                context: context,
                applicationName: 'Routine Ranger',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(Icons.schedule, size: 48),
                children: [
                  const Text('Build better habits and stay consistent with your daily routines.'),
                ],
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to sign out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              );
              if (confirmed == true && context.mounted) {
                Navigator.pop(context);
                await context.read<AuthProvider>().signOut();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required int index,
  }) {
    final isSelected = _currentIndex == index;
    
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Theme.of(context).colorScheme.primary : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Theme.of(context).colorScheme.primary : null,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      onTap: () {
        Navigator.pop(context);
        setState(() {
          _currentIndex = index;
        });
      },
    );
  }

  void _showNotificationsDialog(BuildContext context) async {
    final np = context.read<NotificationsProvider>();
    bool current = context.read<NotificationsProvider>().motivationSubscribed;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Notifications'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SwitchListTile(
                title: const Text('Subscribe to "motivation" topic'),
                value: current,
                onChanged: (v) {
                  setState(() => current = v);
                },
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                await np.setMotivationSubscribed(current);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _handleHomeMenuAction(BuildContext context, String value) {
    if (value == 'refresh') {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        context.read<RoutinesProvider>().loadRoutinesForUser(user.uid);
      }
    } else if (value == 'export_all') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Export all feature coming soon')),
      );
    }
  }

  void _handleGoalsMenuAction(BuildContext context, String value) {
    if (value == 'filter') {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Filter Goals'),
          content: const Text('Filter by category or priority'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } else if (value == 'sort') {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Sort Goals'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('By Date'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                title: const Text('By Priority'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                title: const Text('By Category'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      );
    }
  }
}
