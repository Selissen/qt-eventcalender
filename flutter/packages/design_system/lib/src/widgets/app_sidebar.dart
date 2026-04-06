import 'package:flutter/material.dart';
import '../theme.dart';

class AppSidebarItem {
  const AppSidebarItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

class AppSidebar extends StatelessWidget {
  const AppSidebar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onItemSelected,
    this.width = 200,
  });

  final List<AppSidebarItem> items;
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final double width;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: width,
      child: Material(
        color: colorScheme.surface,
        elevation: 1,
        child: Column(
          children: List.generate(items.length, (i) {
            final item = items[i];
            final selected = i == selectedIndex;
            return ListTile(
              leading: Icon(
                item.icon,
                color: selected ? colorScheme.primary : null,
              ),
              title: Text(
                item.label,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  color: selected ? colorScheme.primary : null,
                ),
              ),
              selected: selected,
              selectedTileColor:
                  colorScheme.primaryContainer.withValues(alpha: 0.15),
              onTap: () => onItemSelected(i),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
            );
          }),
        ),
      ),
    );
  }
}
