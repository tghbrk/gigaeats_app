import 'package:flutter/material.dart';
import '../../../../../../design_system/tokens/ge_vendor_colors.dart';

/// Mini Chart Component for Dashboard Cards
/// 
/// A small bar chart component that displays trend data
/// in dashboard metric cards, matching the mockup design.
class MiniChart extends StatefulWidget {
  final List<double> data;
  final Color color;
  final double height;
  final int maxBars;
  final Duration animationDuration;

  const MiniChart({
    super.key,
    required this.data,
    this.color = GEVendorColors.primaryGreen,
    this.height = 40,
    this.maxBars = 7,
    this.animationDuration = const Duration(milliseconds: 800),
  });

  @override
  State<MiniChart> createState() => _MiniChartState();
}

class _MiniChartState extends State<MiniChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    // Start animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(MiniChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          size: Size(double.infinity, widget.height),
          painter: MiniChartPainter(
            data: widget.data,
            color: widget.color,
            maxBars: widget.maxBars,
            animationValue: _animation.value,
          ),
        );
      },
    );
  }
}

/// Custom painter for the mini chart
class MiniChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final int maxBars;
  final double animationValue;

  MiniChartPainter({
    required this.data,
    required this.color,
    required this.maxBars,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    // Prepare data (take last maxBars items or pad with zeros)
    final chartData = _prepareData();
    final maxValue = chartData.isNotEmpty 
        ? chartData.reduce((a, b) => a > b ? a : b)
        : 1.0;
    
    // Avoid division by zero
    final safeMaxValue = maxValue > 0 ? maxValue : 1.0;

    // Calculate bar dimensions
    final barCount = chartData.length;
    final totalGapWidth = (barCount - 1) * 2.0; // 2px gap between bars
    final availableWidth = size.width - totalGapWidth;
    final barWidth = availableWidth / barCount;

    // Paint for bars
    final paint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    // Draw bars
    for (int i = 0; i < chartData.length; i++) {
      final value = chartData[i];
      final normalizedHeight = (value / safeMaxValue) * size.height;
      final animatedHeight = normalizedHeight * animationValue;
      
      final left = i * (barWidth + 2.0);
      final top = size.height - animatedHeight;
      final right = left + barWidth;
      final bottom = size.height;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTRB(left, top, right, bottom),
        const Radius.circular(1),
      );

      canvas.drawRRect(rect, paint);
    }
  }

  List<double> _prepareData() {
    if (data.length >= maxBars) {
      // Take the last maxBars items
      return data.sublist(data.length - maxBars);
    } else {
      // Pad with zeros at the beginning
      final paddedData = List<double>.filled(maxBars - data.length, 0.0);
      paddedData.addAll(data);
      return paddedData;
    }
  }

  @override
  bool shouldRepaint(MiniChartPainter oldDelegate) {
    return oldDelegate.data != data ||
           oldDelegate.color != color ||
           oldDelegate.animationValue != animationValue;
  }
}

/// Mini Chart with hover effects (for web/desktop)
class InteractiveMiniChart extends StatefulWidget {
  final List<double> data;
  final Color color;
  final double height;
  final int maxBars;
  final Function(int index, double value)? onBarHover;

  const InteractiveMiniChart({
    super.key,
    required this.data,
    this.color = GEVendorColors.primaryGreen,
    this.height = 40,
    this.maxBars = 7,
    this.onBarHover,
  });

  @override
  State<InteractiveMiniChart> createState() => _InteractiveMiniChartState();
}

class _InteractiveMiniChartState extends State<InteractiveMiniChart> {
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (event) {
        final RenderBox renderBox = context.findRenderObject() as RenderBox;
        final localPosition = renderBox.globalToLocal(event.position);
        final barIndex = _getBarIndex(localPosition, renderBox.size);
        
        if (barIndex != _hoveredIndex) {
          setState(() {
            _hoveredIndex = barIndex;
          });
          
          if (barIndex != null && widget.onBarHover != null) {
            final data = _prepareData();
            if (barIndex < data.length) {
              widget.onBarHover!(barIndex, data[barIndex]);
            }
          }
        }
      },
      onExit: (event) {
        setState(() {
          _hoveredIndex = null;
        });
      },
      child: CustomPaint(
        size: Size(double.infinity, widget.height),
        painter: InteractiveMiniChartPainter(
          data: widget.data,
          color: widget.color,
          maxBars: widget.maxBars,
          hoveredIndex: _hoveredIndex,
        ),
      ),
    );
  }

  int? _getBarIndex(Offset position, Size size) {
    final data = _prepareData();
    final barCount = data.length;
    final totalGapWidth = (barCount - 1) * 2.0;
    final availableWidth = size.width - totalGapWidth;
    final barWidth = availableWidth / barCount;
    
    for (int i = 0; i < barCount; i++) {
      final left = i * (barWidth + 2.0);
      final right = left + barWidth;
      
      if (position.dx >= left && position.dx <= right) {
        return i;
      }
    }
    
    return null;
  }

  List<double> _prepareData() {
    if (widget.data.length >= widget.maxBars) {
      return widget.data.sublist(widget.data.length - widget.maxBars);
    } else {
      final paddedData = List<double>.filled(widget.maxBars - widget.data.length, 0.0);
      paddedData.addAll(widget.data);
      return paddedData;
    }
  }
}

/// Interactive painter with hover effects
class InteractiveMiniChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final int maxBars;
  final int? hoveredIndex;

  InteractiveMiniChartPainter({
    required this.data,
    required this.color,
    required this.maxBars,
    this.hoveredIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final chartData = _prepareData();
    final maxValue = chartData.isNotEmpty 
        ? chartData.reduce((a, b) => a > b ? a : b)
        : 1.0;
    final safeMaxValue = maxValue > 0 ? maxValue : 1.0;

    final barCount = chartData.length;
    final totalGapWidth = (barCount - 1) * 2.0;
    final availableWidth = size.width - totalGapWidth;
    final barWidth = availableWidth / barCount;

    for (int i = 0; i < chartData.length; i++) {
      final value = chartData[i];
      final normalizedHeight = (value / safeMaxValue) * size.height;
      
      final left = i * (barWidth + 2.0);
      final top = size.height - normalizedHeight;
      final right = left + barWidth;
      final bottom = size.height;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTRB(left, top, right, bottom),
        const Radius.circular(1),
      );

      final paint = Paint()
        ..color = i == hoveredIndex 
            ? color 
            : color.withValues(alpha: 0.7)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(rect, paint);
    }
  }

  List<double> _prepareData() {
    if (data.length >= maxBars) {
      return data.sublist(data.length - maxBars);
    } else {
      final paddedData = List<double>.filled(maxBars - data.length, 0.0);
      paddedData.addAll(data);
      return paddedData;
    }
  }

  @override
  bool shouldRepaint(InteractiveMiniChartPainter oldDelegate) {
    return oldDelegate.data != data ||
           oldDelegate.color != color ||
           oldDelegate.hoveredIndex != hoveredIndex;
  }
}
