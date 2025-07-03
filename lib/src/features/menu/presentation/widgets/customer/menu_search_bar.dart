import 'package:flutter/material.dart';

/// Reusable search bar widget for menu item filtering
/// Provides Material Design 3 styled search functionality with clear button
class MenuSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final Function(String) onChanged;
  final VoidCallback? onClear;
  final bool showClearButton;
  final EdgeInsets? padding;
  final Widget? leading;
  final List<Widget>? trailing;

  const MenuSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hintText = 'Search menu items...',
    this.onClear,
    this.showClearButton = true,
    this.padding,
    this.leading,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
      child: SearchBar(
        controller: controller,
        hintText: hintText,
        leading: leading ?? Icon(
          Icons.search,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        trailing: _buildTrailing(theme),
        backgroundColor: WidgetStateProperty.all(theme.colorScheme.surfaceContainerHighest),
        elevation: WidgetStateProperty.all(0),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }

  List<Widget>? _buildTrailing(ThemeData theme) {
    final List<Widget> trailingWidgets = [];
    
    // Add clear button if enabled and text is not empty
    if (showClearButton && controller.text.isNotEmpty) {
      trailingWidgets.add(
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: onClear ?? () {
            controller.clear();
            onChanged('');
          },
          tooltip: 'Clear search',
        ),
      );
    }
    
    // Add custom trailing widgets
    if (trailing != null) {
      trailingWidgets.addAll(trailing!);
    }
    
    return trailingWidgets.isNotEmpty ? trailingWidgets : null;
  }
}

/// Compact search bar for smaller spaces
class CompactMenuSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final Function(String) onChanged;
  final VoidCallback? onClear;
  final EdgeInsets? padding;

  const CompactMenuSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hintText = 'Search...',
    this.onClear,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Icon(
            Icons.search,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: onClear ?? () {
                    controller.clear();
                    onChanged('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: theme.colorScheme.surfaceContainerHighest,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}

/// Search bar with filter button for advanced filtering
class MenuSearchBarWithFilter extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final Function(String) onChanged;
  final VoidCallback? onClear;
  final VoidCallback? onFilterPressed;
  final bool hasActiveFilters;
  final EdgeInsets? padding;

  const MenuSearchBarWithFilter({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hintText = 'Search menu items...',
    this.onClear,
    this.onFilterPressed,
    this.hasActiveFilters = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return MenuSearchBar(
      controller: controller,
      hintText: hintText,
      onChanged: onChanged,
      onClear: onClear,
      padding: padding,
      trailing: [
        if (onFilterPressed != null)
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.tune),
                if (hasActiveFilters)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: onFilterPressed,
            tooltip: 'Filter options',
          ),
      ],
    );
  }
}
