import 'package:flutter/material.dart';
import '../tokens/tokens.dart';

/// GigaEats Design System Screen Layout Component
/// 
/// A standardized screen layout that provides consistent structure,
/// spacing, and behavior across all user interfaces.
class GEScreen extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? drawer;
  final Widget? endDrawer;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final EdgeInsetsGeometry? padding;
  final bool safeArea;
  final bool scrollable;
  final ScrollController? scrollController;
  final RefreshCallback? onRefresh;
  final bool showLoadingOverlay;
  final String? loadingMessage;

  const GEScreen({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.drawer,
    this.endDrawer,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.padding,
    this.safeArea = true,
    this.scrollable = false,
    this.scrollController,
    this.onRefresh,
    this.showLoadingOverlay = false,
    this.loadingMessage,
  });

  /// Scrollable screen constructor
  const GEScreen.scrollable({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.drawer,
    this.endDrawer,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.padding,
    this.safeArea = true,
    this.scrollController,
    this.onRefresh,
    this.showLoadingOverlay = false,
    this.loadingMessage,
  }) : scrollable = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenBackgroundColor = backgroundColor ?? theme.scaffoldBackgroundColor;
    
    Widget screenBody = _buildBody(context);
    
    if (safeArea) {
      screenBody = SafeArea(child: screenBody);
    }
    
    if (padding != null) {
      screenBody = Padding(
        padding: padding!,
        child: screenBody,
      );
    }
    
    Widget scaffold = Scaffold(
      appBar: appBar,
      body: screenBody,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      drawer: drawer,
      endDrawer: endDrawer,
      backgroundColor: screenBackgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
    );
    
    if (showLoadingOverlay) {
      scaffold = Stack(
        children: [
          scaffold,
          _buildLoadingOverlay(context),
        ],
      );
    }
    
    return scaffold;
  }

  Widget _buildBody(BuildContext context) {
    if (scrollable) {
      if (onRefresh != null) {
        return RefreshIndicator(
          onRefresh: onRefresh!,
          child: SingleChildScrollView(
            controller: scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            child: body,
          ),
        );
      } else {
        return SingleChildScrollView(
          controller: scrollController,
          child: body,
        );
      }
    }
    
    return body;
  }

  Widget _buildLoadingOverlay(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(GESpacing.xl),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: GEBorderRadius.lgRadius,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              if (loadingMessage != null) ...[
                const SizedBox(height: GESpacing.lg),
                Text(
                  loadingMessage!,
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Section Layout Component
/// 
/// A standardized section layout for organizing content within screens.
class GESection extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget? action;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool showDivider;
  final CrossAxisAlignment crossAxisAlignment;

  const GESection({
    super.key,
    this.title,
    this.subtitle,
    this.action,
    required this.child,
    this.padding,
    this.margin,
    this.showDivider = false,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: GESpacing.sectionSpacing),
      child: Column(
        crossAxisAlignment: crossAxisAlignment,
        children: [
          if (title != null || action != null) ...[
            _buildHeader(context, theme),
            const SizedBox(height: GESpacing.lg),
          ],
          Container(
            padding: padding ?? const EdgeInsets.symmetric(horizontal: GESpacing.screenPadding),
            child: child,
          ),
          if (showDivider) ...[
            const SizedBox(height: GESpacing.sectionSpacing),
            Divider(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
              height: 1,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: GESpacing.screenPadding),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Text(
                    title!,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: GETypography.semiBold,
                    ),
                  ),
                if (subtitle != null) ...[
                  const SizedBox(height: GESpacing.xs),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

/// Container Layout Component
/// 
/// A standardized container with consistent spacing and styling.
class GEContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Border? border;
  final List<BoxShadow>? boxShadow;
  final double? elevation;
  final AlignmentGeometry? alignment;

  const GEContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.width,
    this.height,
    this.borderRadius,
    this.border,
    this.boxShadow,
    this.elevation,
    this.alignment,
  });

  /// Card-style container constructor
  const GEContainer.card({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.width,
    this.height,
    this.borderRadius,
    this.border,
    this.alignment,
  }) : boxShadow = null,
       elevation = GEElevation.card;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final containerBackgroundColor = backgroundColor ?? theme.colorScheme.surface;
    final containerBorderRadius = borderRadius ?? GEBorderRadius.lgRadius;
    final containerBoxShadow = boxShadow ?? 
        (elevation != null ? GEElevation.getShadow(elevation!, isDark: theme.brightness == Brightness.dark) : null);
    
    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding ?? const EdgeInsets.all(GESpacing.containerPadding),
      alignment: alignment,
      decoration: BoxDecoration(
        color: containerBackgroundColor,
        borderRadius: containerBorderRadius,
        border: border,
        boxShadow: containerBoxShadow,
      ),
      child: child,
    );
  }
}

/// Grid Layout Component
/// 
/// A responsive grid layout for organizing content.
class GEGrid extends StatelessWidget {
  final List<Widget> children;
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const GEGrid({
    super.key,
    required this.children,
    this.crossAxisCount = 2,
    this.mainAxisSpacing = GESpacing.gridGutter,
    this.crossAxisSpacing = GESpacing.gridGutter,
    this.childAspectRatio = 1.0,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
  });

  /// Responsive grid constructor that adapts to screen size
  const GEGrid.responsive({
    super.key,
    required this.children,
    this.mainAxisSpacing = GESpacing.gridGutter,
    this.crossAxisSpacing = GESpacing.gridGutter,
    this.childAspectRatio = 1.0,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
  }) : crossAxisCount = 0; // Will be calculated based on screen size

  @override
  Widget build(BuildContext context) {
    final effectiveCrossAxisCount = crossAxisCount > 0 
        ? crossAxisCount 
        : _getResponsiveCrossAxisCount(context);
    
    return GridView.builder(
      padding: padding ?? const EdgeInsets.all(GESpacing.gridMargin),
      shrinkWrap: shrinkWrap,
      physics: physics,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: effectiveCrossAxisCount,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }

  int _getResponsiveCrossAxisCount(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Mobile: 1-2 columns
    if (screenWidth < 600) return 2;
    
    // Tablet: 3-4 columns
    if (screenWidth < 1200) return 3;
    
    // Desktop: 4+ columns
    return 4;
  }
}
