import 'package:flutter/material.dart';

import '../../../data/models/customization_template.dart';

/// Compact preview card showing how a single template appears to customers
class TemplatePreviewCard extends StatelessWidget {
  final CustomizationTemplate template;
  final bool showPricing;
  final bool isExpanded;
  final VoidCallback? onTap;

  const TemplatePreviewCard({
    super.key,
    required this.template,
    this.showPricing = true,
    this.isExpanded = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(theme),
              
              if (isExpanded) ...[
                const SizedBox(height: 12),
                _buildOptionsPreview(theme),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        // Selection Type Icon
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            template.isSingleSelection ? Icons.radio_button_checked : Icons.check_box,
            size: 16,
            color: theme.colorScheme.primary,
          ),
        ),
        
        const SizedBox(width: 8),
        
        // Template Name
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                template.name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              
              // Type and Required badges
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        template.isSingleSelection ? 'Single' : 'Multiple',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontSize: 10,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),

                  if (template.isRequired) ...[
                    const SizedBox(width: 4),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          'Required',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                            fontSize: 10,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        
        // Options Count
        Text(
          '${template.options.length}',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        
        if (onTap != null) ...[
          const SizedBox(width: 4),
          Icon(
            isExpanded ? Icons.expand_less : Icons.expand_more,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ],
    );
  }

  Widget _buildOptionsPreview(ThemeData theme) {
    if (template.options.isEmpty) {
      return Text(
        'No options configured',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    // Show first few options as preview
    final previewOptions = template.options.take(3).toList();
    final hasMore = template.options.length > 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Options Preview:',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        
        ...previewOptions.map((option) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Icon(
                template.isSingleSelection ? Icons.radio_button_unchecked : Icons.check_box_outline_blank,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  option.name,
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (showPricing && option.additionalPrice > 0)
                Text(
                  '+RM${option.additionalPrice.toStringAsFixed(2)}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        )),
        
        if (hasMore)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '... and ${template.options.length - 3} more options',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }
}

/// Widget that shows a grid of template preview cards
class TemplatePreviewGrid extends StatefulWidget {
  final List<CustomizationTemplate> templates;
  final bool showPricing;
  final String? emptyMessage;

  const TemplatePreviewGrid({
    super.key,
    required this.templates,
    this.showPricing = true,
    this.emptyMessage,
  });

  @override
  State<TemplatePreviewGrid> createState() => _TemplatePreviewGridState();
}

class _TemplatePreviewGridState extends State<TemplatePreviewGrid> {
  String? _expandedTemplateId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.templates.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.preview,
                size: 48,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                widget.emptyMessage ?? 'No templates to preview',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: widget.templates.length,
      itemBuilder: (context, index) {
        final template = widget.templates[index];
        final isExpanded = _expandedTemplateId == template.id;
        
        return TemplatePreviewCard(
          template: template,
          showPricing: widget.showPricing,
          isExpanded: isExpanded,
          onTap: () {
            setState(() {
              _expandedTemplateId = isExpanded ? null : template.id;
            });
          },
        );
      },
    );
  }
}

/// Compact horizontal list of template previews
class TemplatePreviewList extends StatelessWidget {
  final List<CustomizationTemplate> templates;
  final bool showPricing;
  final String? emptyMessage;

  const TemplatePreviewList({
    super.key,
    required this.templates,
    this.showPricing = true,
    this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (templates.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            emptyMessage ?? 'No templates selected',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: templates.length,
        itemBuilder: (context, index) {
          final template = templates[index];

          return Container(
            width: 200,
            margin: EdgeInsets.only(right: index < templates.length - 1 ? 12 : 0),
            child: TemplatePreviewCard(
              template: template,
              showPricing: showPricing,
            ),
          );
        },
      ),
    );
  }
}
