import 'package:flutter/material.dart';

import '../theming/navigation_theme_service.dart';

/// Comprehensive loading state widgets for the Enhanced In-App Navigation System
/// Provides consistent Material Design 3 loading states across all navigation components

/// Navigation loading overlay for full-screen loading states
class NavigationLoadingOverlay extends StatelessWidget {
  final String message;
  final bool showProgress;
  final double? progress;
  final VoidCallback? onCancel;

  const NavigationLoadingOverlay({
    super.key,
    this.message = 'Loading navigation...',
    this.showProgress = false,
    this.progress,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final navTheme = NavigationTheme.of(context);
    
    return Container(
      color: navTheme?.loadingTheme.loadingOverlayColor ?? 
             theme.colorScheme.surface.withValues(alpha: 0.8),
      child: Center(
        child: Card(
          elevation: navTheme?.elevationTheme.dialogElevation ?? 12.0,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Loading indicator
                if (showProgress && progress != null)
                  CircularProgressIndicator(
                    value: progress,
                    color: navTheme?.loadingTheme.progressIndicatorColor ?? 
                           theme.colorScheme.primary,
                    strokeWidth: 4,
                  )
                else
                  CircularProgressIndicator(
                    color: navTheme?.loadingTheme.progressIndicatorColor ?? 
                           theme.colorScheme.primary,
                    strokeWidth: 4,
                  ),
                
                const SizedBox(height: 16),
                
                // Loading message
                Text(
                  message,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: navTheme?.loadingTheme.loadingTextColor ?? 
                           theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                // Progress percentage
                if (showProgress && progress != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${(progress! * 100).round()}%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                
                // Cancel button
                if (onCancel != null) ...[
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: onCancel,
                    child: const Text('Cancel'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shimmer loading placeholder for navigation stats
class NavigationStatsLoadingPlaceholder extends StatelessWidget {
  final bool compact;

  const NavigationStatsLoadingPlaceholder({
    super.key,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final navTheme = NavigationTheme.of(context);
    
    return Container(
      margin: const EdgeInsets.all(16),
      child: Material(
        elevation: navTheme?.elevationTheme.cardElevation ?? 4.0,
        borderRadius: BorderRadius.circular(compact ? 12 : 16),
        child: Container(
          padding: EdgeInsets.all(compact ? 12 : 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(compact ? 12 : 16),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: _AnimatedLoadingPlaceholder(
            child: compact ? _buildCompactShimmer() : _buildFullShimmer(),
          ),
        ),
      ),
    );
  }

  Widget _buildFullShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 120,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Stats row
        Row(
          children: [
            Expanded(child: _buildStatShimmer()),
            const SizedBox(width: 12),
            Expanded(child: _buildStatShimmer()),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // ETA shimmer
        _buildStatShimmer(fullWidth: true),
      ],
    );
  }

  Widget _buildCompactShimmer() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildCompactStatShimmer(),
        _buildCompactStatShimmer(),
        _buildCompactStatShimmer(),
      ],
    );
  }

  Widget _buildStatShimmer({bool fullWidth = false}) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: fullWidth ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: fullWidth ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 40,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: fullWidth ? 80 : 60,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatShimmer() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 40,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    );
  }
}

/// Loading placeholder for navigation instruction overlay
class NavigationInstructionLoadingPlaceholder extends StatelessWidget {
  const NavigationInstructionLoadingPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final navTheme = NavigationTheme.of(context);
    
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: Material(
        elevation: navTheme?.elevationTheme.overlayElevation ?? 8.0,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: _AnimatedLoadingPlaceholder(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 150,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 100,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Main instruction
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: 120,
                              height: 14,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Distance and controls
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 80,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 60,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Loading state for battery optimization widget
class BatteryOptimizationLoadingPlaceholder extends StatelessWidget {
  final bool isCompact;

  const BatteryOptimizationLoadingPlaceholder({
    super.key,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (isCompact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: _AnimatedLoadingPlaceholder(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 30,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _AnimatedLoadingPlaceholder(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 140,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 80,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Status container
              Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Generic loading state for navigation components
class NavigationComponentLoadingState extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const NavigationComponentLoadingState({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final navTheme = NavigationTheme.of(context);

    return _AnimatedLoadingPlaceholder(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: navTheme?.loadingTheme.shimmerBaseColor ??
                theme.colorScheme.surfaceContainer,
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
      ),
    );
  }
}

/// Animated loading placeholder widget that provides a pulsing animation
class _AnimatedLoadingPlaceholder extends StatefulWidget {
  final Widget child;

  const _AnimatedLoadingPlaceholder({
    required this.child,
  });

  @override
  State<_AnimatedLoadingPlaceholder> createState() => _AnimatedLoadingPlaceholderState();
}

class _AnimatedLoadingPlaceholderState extends State<_AnimatedLoadingPlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: widget.child,
        );
      },
    );
  }
}
