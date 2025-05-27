import 'package:flutter/material.dart';

class SearchBarWidget extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final VoidCallback? onSubmitted;
  final bool enabled;
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  const SearchBarWidget({
    super.key,
    this.controller,
    this.hintText,
    this.onChanged,
    this.onClear,
    this.onSubmitted,
    this.enabled = true,
    this.prefixIcon,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        onChanged: onChanged,
        onSubmitted: onSubmitted != null ? (_) => onSubmitted!() : null,
        style: theme.textTheme.bodyLarge,
        decoration: InputDecoration(
          hintText: hintText ?? 'Search...',
          hintStyle: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
          prefixIcon: prefixIcon ??
              Icon(
                Icons.search,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
          suffixIcon: _buildSuffixIcon(theme),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget? _buildSuffixIcon(ThemeData theme) {
    if (suffixIcon != null) {
      return suffixIcon;
    }

    if (controller?.text.isNotEmpty == true && onClear != null) {
      return IconButton(
        icon: Icon(
          Icons.clear,
          color: theme.colorScheme.onSurface.withOpacity(0.5),
        ),
        onPressed: onClear,
      );
    }

    return null;
  }
}

class SearchBarWithFilters extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final VoidCallback? onFilterTap;
  final bool hasActiveFilters;
  final bool enabled;

  const SearchBarWithFilters({
    super.key,
    this.controller,
    this.hintText,
    this.onChanged,
    this.onClear,
    this.onFilterTap,
    this.hasActiveFilters = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: SearchBarWidget(
            controller: controller,
            hintText: hintText,
            onChanged: onChanged,
            onClear: onClear,
            enabled: enabled,
          ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            color: hasActiveFilters 
                ? theme.colorScheme.primary 
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasActiveFilters 
                  ? theme.colorScheme.primary 
                  : theme.colorScheme.outline.withOpacity(0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            onPressed: onFilterTap,
            icon: Icon(
              Icons.tune,
              color: hasActiveFilters 
                  ? Colors.white 
                  : theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ),
      ],
    );
  }
}

class SearchSuggestions extends StatelessWidget {
  final List<String> suggestions;
  final ValueChanged<String>? onSuggestionTap;

  const SearchSuggestions({
    super.key,
    required this.suggestions,
    this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: suggestions.map((suggestion) {
          return ListTile(
            dense: true,
            leading: Icon(
              Icons.search,
              size: 20,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            title: Text(
              suggestion,
              style: theme.textTheme.bodyMedium,
            ),
            onTap: () => onSuggestionTap?.call(suggestion),
          );
        }).toList(),
      ),
    );
  }
}

class RecentSearches extends StatelessWidget {
  final List<String> recentSearches;
  final ValueChanged<String>? onSearchTap;
  final ValueChanged<String>? onSearchRemove;
  final VoidCallback? onClearAll;

  const RecentSearches({
    super.key,
    required this.recentSearches,
    this.onSearchTap,
    this.onSearchRemove,
    this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (recentSearches.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Searches',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (onClearAll != null)
              TextButton(
                onPressed: onClearAll,
                child: const Text('Clear All'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: recentSearches.map((search) {
            return Chip(
              label: Text(search),
              deleteIcon: const Icon(Icons.close, size: 16),
              onDeleted: () => onSearchRemove?.call(search),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor: theme.colorScheme.surfaceVariant,
              side: BorderSide.none,
            );
          }).toList(),
        ),
      ],
    );
  }
}
