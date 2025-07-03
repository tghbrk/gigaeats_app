import 'package:flutter/material.dart';

/// Loading widget types
enum LoadingType {
  circular,
  linear,
  dots,
  pulse,
  skeleton,
}

/// A versatile loading widget for different use cases
class LoadingWidget extends StatelessWidget {
  final String? message;
  final LoadingType type;
  final Color? color;
  final double? size;
  final bool showMessage;
  final EdgeInsetsGeometry? padding;

  const LoadingWidget({
    super.key,
    this.message,
    this.type = LoadingType.circular,
    this.color,
    this.size,
    this.showMessage = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loadingColor = color ?? theme.colorScheme.primary;

    Widget loadingIndicator = switch (type) {
      LoadingType.circular => _buildCircularLoading(loadingColor),
      LoadingType.linear => _buildLinearLoading(loadingColor),
      LoadingType.dots => _buildDotsLoading(loadingColor),
      LoadingType.pulse => _buildPulseLoading(loadingColor),
      LoadingType.skeleton => _buildSkeletonLoading(theme),
    };

    if (type == LoadingType.skeleton) {
      return Container(
        padding: padding ?? const EdgeInsets.all(16),
        child: loadingIndicator,
      );
    }

    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          loadingIndicator,
          if (showMessage && message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCircularLoading(Color color) {
    return SizedBox(
      width: size ?? 24,
      height: size ?? 24,
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(color),
        strokeWidth: 2,
      ),
    );
  }

  Widget _buildLinearLoading(Color color) {
    return SizedBox(
      width: size ?? 200,
      child: LinearProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }

  Widget _buildDotsLoading(Color color) {
    return SizedBox(
      width: size ?? 60,
      height: 20,
      child: _DotsLoadingAnimation(color: color),
    );
  }

  Widget _buildPulseLoading(Color color) {
    return SizedBox(
      width: size ?? 40,
      height: size ?? 40,
      child: _PulseLoadingAnimation(color: color),
    );
  }

  Widget _buildSkeletonLoading(ThemeData theme) {
    return _SkeletonLoading(
      baseColor: theme.colorScheme.surface,
      highlightColor: theme.colorScheme.onSurface.withValues(alpha: 0.1),
    );
  }
}

/// Full screen loading overlay
class FullScreenLoading extends StatelessWidget {
  final String? message;
  final LoadingType type;
  final Color? backgroundColor;
  final Color? loadingColor;

  const FullScreenLoading({
    super.key,
    this.message,
    this.type = LoadingType.circular,
    this.backgroundColor,
    this.loadingColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor ?? Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: LoadingWidget(
              message: message,
              type: type,
              color: loadingColor,
            ),
          ),
        ),
      ),
    );
  }
}

/// Inline loading widget for lists and content
class InlineLoading extends StatelessWidget {
  final String? message;
  final double height;
  final LoadingType type;

  const InlineLoading({
    super.key,
    this.message,
    this.height = 60,
    this.type = LoadingType.circular,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Center(
        child: LoadingWidget(
          message: message,
          type: type,
          size: 20,
        ),
      ),
    );
  }
}

/// Button loading state
class ButtonLoading extends StatelessWidget {
  final Color? color;
  final double size;

  const ButtonLoading({
    super.key,
    this.color,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? Colors.white,
        ),
      ),
    );
  }
}

/// Dots loading animation
class _DotsLoadingAnimation extends StatefulWidget {
  final Color color;

  const _DotsLoadingAnimation({required this.color});

  @override
  State<_DotsLoadingAnimation> createState() => _DotsLoadingAnimationState();
}

class _DotsLoadingAnimationState extends State<_DotsLoadingAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final animationValue = (_controller.value - delay).clamp(0.0, 1.0);
            final scale = (1.0 - (animationValue * 2 - 1).abs()).clamp(0.5, 1.0);
            
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/// Pulse loading animation
class _PulseLoadingAnimation extends StatefulWidget {
  final Color color;

  const _PulseLoadingAnimation({required this.color});

  @override
  State<_PulseLoadingAnimation> createState() => _PulseLoadingAnimationState();
}

class _PulseLoadingAnimationState extends State<_PulseLoadingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: Container(
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton loading for content placeholders
class _SkeletonLoading extends StatefulWidget {
  final Color baseColor;
  final Color highlightColor;

  const _SkeletonLoading({
    required this.baseColor,
    required this.highlightColor,
  });

  @override
  State<_SkeletonLoading> createState() => _SkeletonLoadingState();
}

class _SkeletonLoadingState extends State<_SkeletonLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSkeletonLine(width: double.infinity, height: 16),
        const SizedBox(height: 8),
        _buildSkeletonLine(width: 200, height: 14),
        const SizedBox(height: 8),
        _buildSkeletonLine(width: 150, height: 14),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildSkeletonBox(width: 60, height: 60),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSkeletonLine(width: double.infinity, height: 14),
                  const SizedBox(height: 6),
                  _buildSkeletonLine(width: 120, height: 12),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSkeletonLine({required double width, required double height}) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value, 0),
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSkeletonBox({required double width, required double height}) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value, 0),
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
            ),
          ),
        );
      },
    );
  }
}
