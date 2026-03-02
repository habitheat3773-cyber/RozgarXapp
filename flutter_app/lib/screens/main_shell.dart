import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_theme.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  int _getSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/search')) return 1;
    if (location.startsWith('/saved')) return 2;
    if (location.startsWith('/exams')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _getSelectedIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: _BottomNav(selectedIndex: selectedIndex),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int selectedIndex;
  const _BottomNav({required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          top: BorderSide(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.home_outlined,  selectedIcon: Icons.home,  label: 'Home',   index: 0, selected: selectedIndex == 0, route: '/home'),
              _NavItem(icon: Icons.search_outlined, selectedIcon: Icons.search, label: 'Search', index: 1, selected: selectedIndex == 1, route: '/search'),
              _NavItem(icon: Icons.bookmark_outline, selectedIcon: Icons.bookmark, label: 'Saved', index: 2, selected: selectedIndex == 2, route: '/saved'),
              _NavItem(icon: Icons.school_outlined, selectedIcon: Icons.school, label: 'Exams',  index: 3, selected: selectedIndex == 3, route: '/exams'),
              _NavItem(icon: Icons.person_outline, selectedIcon: Icons.person, label: 'Profile', index: 4, selected: selectedIndex == 4, route: '/profile'),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final int index;
  final bool selected;
  final String route;

  const _NavItem({
    required this.icon, required this.selectedIcon,
    required this.label, required this.index,
    required this.selected, required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(route),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryBlue.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                selected ? selectedIcon : icon,
                key: ValueKey(selected),
                color: selected ? AppTheme.primaryBlue : Colors.grey,
                size: 24,
              ),
            ).animate(target: selected ? 1 : 0).scaleXY(begin: 1, end: 1.15),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                color: selected ? AppTheme.primaryBlue : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
