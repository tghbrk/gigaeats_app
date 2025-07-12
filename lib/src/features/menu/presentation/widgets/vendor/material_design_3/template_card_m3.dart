import 'package:flutter/material.dart';

import '../../../../data/models/customization_template.dart';
import '../../../theme/template_theme_extension.dart';

/// Material Design 3 enhanced template card with proper elevation, colors, and interactions
class TemplateCardM3 extends StatefulWidget {
  final CustomizationTemplate template;
  final bool isSelected;
  final bool showDragHandle;
  final bool showUsageStats;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Function(bool)? onSelectionChanged;
  final Widget? trailing;

  const TemplateCardM3({
    super.key,
    required this.template,
    this.isSelected = false,
    this.showDragHandle = false,
    this.showUsageStats = true,
    this.onTap,
    this.onLongPress,
    this.onSelectionChanged,
    this.trailing,
  });

  @override
  State<TemplateCardM3> createState() => _TemplateCardM3State();
}

class _TemplateCardM3State extends State<TemplateCardM3>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _elevationAnimation = Tween<double>(
      begin: 1.0,
      end: 4.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(TemplateCardM3 oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final templateTheme = context.templateTheme;
    final category = _getCategoryFromTemplate(widget.template);

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Card(
            elevation: widget.isSelected ? _elevationAnimation.value : 1.0,
            color: widget.isSelected 
                ? templateTheme.templateCardSelectedBackground
                : templateTheme.templateCardBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: widget.isSelected 
                    ? templateTheme.templateCardSelectedBorder
                    : templateTheme.templateCardBorder,
                width: widget.isSelected ? 2.0 : 1.0,
              ),
            ),
            child: InkWell(
              onTap: widget.onTap,
              onLongPress: widget.onLongPress,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row
                    Row(
                      children: [
                        // Selection Checkbox
                        if (widget.onSelectionChanged != null)
                          Checkbox(
                            value: widget.isSelected,
                            onChanged: (value) => widget.onSelectionChanged?.call(value ?? false),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        
                        // Category Icon
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: templateTheme.getCategoryColor(category).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            templateTheme.getCategoryIcon(category),
                            color: templateTheme.getCategoryColor(category),
                            size: 20,
                          ),
                        ),
                        
                        const SizedBox(width: 12),
                        
                        // Template Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.template.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: widget.isSelected 
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  // Category Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: templateTheme.getCategoryColor(category).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      category,
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: templateTheme.getCategoryColor(category),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  
                                  const SizedBox(width: 8),
                                  
                                  // Type Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: widget.template.isSingleSelection
                                          ? theme.colorScheme.primaryContainer
                                          : theme.colorScheme.secondaryContainer,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      widget.template.isSingleSelection ? 'Single' : 'Multiple',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: widget.template.isSingleSelection
                                            ? theme.colorScheme.onPrimaryContainer
                                            : theme.colorScheme.onSecondaryContainer,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  
                                  // Required Badge
                                  if (widget.template.isRequired) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: templateTheme.templateRequiredColor.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Required',
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: templateTheme.templateRequiredColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // Trailing Actions
                        if (widget.trailing != null) widget.trailing!,
                        
                        // Drag Handle
                        if (widget.showDragHandle)
                          Icon(
                            Icons.drag_handle,
                            color: templateTheme.dragHandleColor,
                            size: 20,
                          ),
                      ],
                    ),
                    
                    // Description
                    if (widget.template.description != null && widget.template.description!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        widget.template.description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    
                    const SizedBox(height: 12),
                    
                    // Options Preview
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: widget.template.options.take(3).map((option) => 
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: templateTheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: templateTheme.templateCardBorder,
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                option.name,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              if (option.additionalPrice > 0) ...[
                                const SizedBox(width: 4),
                                Text(
                                  '+RM${option.additionalPrice.toStringAsFixed(2)}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ).toList(),
                    ),
                    
                    // Show more indicator
                    if (widget.template.options.length > 3) ...[
                      const SizedBox(height: 4),
                      Text(
                        '+${widget.template.options.length - 3} more options',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    
                    // Usage Stats
                    if (widget.showUsageStats) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.analytics,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Used ${widget.template.usageCount} times',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const Spacer(),
                          // Active Status
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: widget.template.isActive 
                                  ? templateTheme.templateActiveColor
                                  : templateTheme.templateInactiveColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.template.isActive ? 'Active' : 'Inactive',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: widget.template.isActive 
                                  ? templateTheme.templateActiveColor
                                  : templateTheme.templateInactiveColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _getCategoryFromTemplate(CustomizationTemplate template) {
    final name = template.name.toLowerCase();
    if (name.contains('size') || name.contains('portion')) return 'Size Options';
    if (name.contains('add') || name.contains('extra')) return 'Add-ons';
    if (name.contains('spice') || name.contains('level')) return 'Spice Level';
    if (name.contains('cook') || name.contains('style')) return 'Cooking Style';
    if (name.contains('diet') || name.contains('vegan') || name.contains('halal')) return 'Dietary';
    return 'Other';
  }
}
