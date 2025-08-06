import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/enhanced_driver_order_history_providers.dart';
import 'modern_complete_filter_interface_m3.dart';
import 'modern_date_filter_components_m3.dart';
import 'modern_date_filter_dialog_m3.dart';

/// Responsive Material Design 3 filter layout that adapts to different screen sizes
class ResponsiveFilterLayout extends ConsumerWidget {
  final VoidCallback? onFilterChanged;
  final bool showAnalytics;
  final bool enableAdvancedFilters;

  const ResponsiveFilterLayout({
    super.key,
    this.onFilterChanged,
    this.showAnalytics = false,
    this.enableAdvancedFilters = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;
    final isDesktop = screenWidth >= 1024;

    if (isDesktop) {
      return _buildDesktopLayout(context, ref);
    } else if (isTablet) {
      return _buildTabletLayout(context, ref);
    } else {
      return _buildMobileLayout(context, ref);
    }
  }

  Widget _buildMobileLayout(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // Compact filter interface for mobile
        ModernCompleteFilterInterface(
          showQuickFilters: true,
          showStatusCard: true,
          showOrderCount: true,
          enableAdvancedFilters: enableAdvancedFilters,
          onFilterChanged: onFilterChanged,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        
        // Analytics summary (if enabled)
        if (showAnalytics)
          ModernFilterSummary(
            showAnalytics: true,
            showRecommendations: false,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // Enhanced filter interface for tablet
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main filter controls
            Expanded(
              flex: 2,
              child: ModernCompleteFilterInterface(
                showQuickFilters: true,
                showStatusCard: true,
                showOrderCount: true,
                enableAdvancedFilters: enableAdvancedFilters,
                onFilterChanged: onFilterChanged,
                padding: const EdgeInsets.all(16),
              ),
            ),
            
            // Side panel with analytics
            if (showAnalytics)
              Expanded(
                flex: 1,
                child: ModernFilterSummary(
                  showAnalytics: true,
                  showRecommendations: true,
                  padding: const EdgeInsets.all(16),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context, WidgetRef ref) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 1200),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main filter controls
          Expanded(
            flex: 3,
            child: ModernCompleteFilterInterface(
              showQuickFilters: true,
              showStatusCard: true,
              showOrderCount: true,
              enableAdvancedFilters: enableAdvancedFilters,
              onFilterChanged: onFilterChanged,
              padding: const EdgeInsets.all(20),
            ),
          ),
          
          // Side panel with analytics and recommendations
          if (showAnalytics)
            Expanded(
              flex: 2,
              child: ModernFilterSummary(
                showAnalytics: true,
                showRecommendations: true,
                padding: const EdgeInsets.all(20),
              ),
            ),
          
          // Advanced filter panel (desktop only)
          if (enableAdvancedFilters)
            Expanded(
              flex: 2,
              child: _buildAdvancedFilterPanel(context, ref),
            ),
        ],
      ),
    );
  }

  Widget _buildAdvancedFilterPanel(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.tune_rounded,
                color: colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Advanced Filters',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Embedded date range picker
          Expanded(
            child: ModernDateRangePicker(
              showPresets: true,
              onDateRangeChanged: (start, end) {
                ref.read(selectedQuickFilterProvider.notifier).setFilter(QuickDateFilter.all);
                ref.read(dateFilterProvider.notifier).setCustomDateRange(start, end);
                onFilterChanged?.call();
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Adaptive filter app bar for different screen sizes
class AdaptiveFilterAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final bool showFilterButton;
  final VoidCallback? onFilterPressed;
  final List<Widget>? actions;

  const AdaptiveFilterAppBar({
    super.key,
    required this.title,
    this.showFilterButton = true,
    this.onFilterPressed,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return AppBar(
      title: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 1,
      actions: [
        // Filter status indicator
        if (showFilterButton)
          _buildFilterStatusIndicator(context, ref, isMobile),
        
        // Custom actions
        if (actions != null) ...actions!,
        
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildFilterStatusIndicator(BuildContext context, WidgetRef ref, bool isMobile) {
    final selectedQuickFilter = ref.watch(selectedQuickFilterProvider);
    final dateFilter = ref.watch(dateFilterProvider);
    final hasActiveFilter = selectedQuickFilter != QuickDateFilter.all || dateFilter.hasActiveFilter;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Material(
        color: hasActiveFilter 
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onFilterPressed ?? () => _showFilterDialog(context),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  hasActiveFilter 
                      ? Icons.filter_alt_rounded
                      : Icons.filter_alt_outlined,
                  size: 18,
                  color: hasActiveFilter 
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant,
                ),
                if (!isMobile) ...[
                  const SizedBox(width: 6),
                  Text(
                    hasActiveFilter ? 'Filtered' : 'Filter',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: hasActiveFilter 
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                if (hasActiveFilter) ...[
                  const SizedBox(width: 4),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    if (isMobile) {
      showModernDateFilterBottomSheet(context);
    } else {
      showModernDateFilterDialog(context);
    }
  }
}

/// Floating action button for quick filter access
class FilterFloatingActionButton extends ConsumerWidget {
  final VoidCallback? onPressed;
  final String? tooltip;

  const FilterFloatingActionButton({
    super.key,
    this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedQuickFilter = ref.watch(selectedQuickFilterProvider);
    final dateFilter = ref.watch(dateFilterProvider);
    final hasActiveFilter = selectedQuickFilter != QuickDateFilter.all || dateFilter.hasActiveFilter;

    return FloatingActionButton.extended(
      onPressed: onPressed ?? () => _showFilterDialog(context),
      backgroundColor: hasActiveFilter 
          ? colorScheme.primaryContainer
          : colorScheme.primary,
      foregroundColor: hasActiveFilter 
          ? colorScheme.onPrimaryContainer
          : colorScheme.onPrimary,
      icon: Icon(
        hasActiveFilter 
            ? Icons.filter_alt_rounded
            : Icons.filter_alt_outlined,
      ),
      label: Text(
        hasActiveFilter ? 'Filtered' : 'Filter',
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      tooltip: tooltip ?? 'Filter orders',
    );
  }

  void _showFilterDialog(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    if (isMobile) {
      showModernDateFilterBottomSheet(context);
    } else {
      showModernDateFilterDialog(context);
    }
  }
}
