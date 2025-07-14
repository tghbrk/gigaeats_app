import 'package:flutter/material.dart';

/// Comprehensive help dialog for import functionality
class ImportHelpDialog extends StatelessWidget {
  const ImportHelpDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.help_outline,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Import Help Guide',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection(
                      theme,
                      'Getting Started',
                      Icons.play_arrow,
                      [
                        '1. Download a template with sample data',
                        '2. Edit the template with your menu items',
                        '3. Preview your data before importing',
                        '4. Fix any errors and import successfully',
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    _buildSection(
                      theme,
                      'Template Formats',
                      Icons.description,
                      [
                        'User-Friendly: Simplified headers, easy to understand (Recommended)',
                        'Technical: System field names, for advanced users',
                        'Both formats support CSV and Excel files',
                        'Sample data included to guide your editing',
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    _buildSection(
                      theme,
                      'Required Fields',
                      Icons.star,
                      [
                        'Item Name: The name of your menu item',
                        'Category: Food category (e.g., Main Course, Beverage)',
                        'Price: Base price in RM (must be positive)',
                        'All other fields are optional but recommended',
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    _buildSection(
                      theme,
                      'Customizations Format',
                      Icons.tune,
                      [
                        'Use simple text format: "Group: Option1(+price), Option2(+price)"',
                        'Required groups end with *: "Size*: Small(+0), Large(+2.00)"',
                        'Multiple groups separated by semicolon (;)',
                        'Example: "Size*: Small(+0), Large(+2.00); Spice: Mild(+0), Hot(+1.00)"',
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    _buildSection(
                      theme,
                      'Preview Benefits',
                      Icons.preview,
                      [
                        'See exactly what will be imported',
                        'Catch validation errors before importing',
                        'Review categories and pricing',
                        'Make corrections in your file if needed',
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    _buildSection(
                      theme,
                      'Common Issues',
                      Icons.warning,
                      [
                        'Missing required fields: Ensure Name, Category, and Price are filled',
                        'Negative prices: All prices must be positive numbers',
                        'Invalid customizations: Follow the text format exactly',
                        'File format: Use CSV, Excel, or JSON files only',
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    _buildSection(
                      theme,
                      'Best Practices',
                      Icons.lightbulb,
                      [
                        'Always export your current menu as backup before importing',
                        'Start with a small test file (5-10 items) first',
                        'Use the Preview feature to validate your data',
                        'Keep your source file for future reference',
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Footer
            const SizedBox(height: 16),
            Row(
              children: [
                const Spacer(),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Got it!'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(ThemeData theme, String title, IconData icon, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: theme.colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(left: 28, bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 4,
                margin: const EdgeInsets.only(top: 8, right: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Text(
                  item,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
}
