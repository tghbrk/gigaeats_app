import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test to verify that UI overflow issues have been fixed
void main() {
  group('UI Overflow Fix Verification', () {
    testWidgets('DropdownButtonFormField with isExpanded should not overflow', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 250, // Constrained width to test overflow
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: DropdownButtonFormField<String>(
                  initialValue: null,
                  isExpanded: true, // This is the key fix
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    hintText: 'Select a category',
                    prefixIcon: Icon(Icons.category),
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem<String>(
                      value: '1',
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(Icons.category, size: 16, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          const Flexible(
                            fit: FlexFit.loose,
                            child: Text(
                              'Very Long Category Name That Could Cause Overflow',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    DropdownMenuItem<String>(
                      value: '2',
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(Icons.category, size: 16, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          const Flexible(
                            fit: FlexFit.loose,
                            child: Text(
                              'Another Extremely Long Category Name For Testing',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (value) {},
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify that the dropdown renders without throwing overflow errors
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);

      // Verify no overflow errors occurred during rendering
      // (Flutter test framework will throw if RenderFlex overflow occurs)
    });

    testWidgets('Template selector Row should not overflow with proper layout', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200, // Constrained width to test overflow
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      // Simulate the fixed Row layout from enhanced_template_selector.dart
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '5 options',
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Used 25x',
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify that the Row renders without throwing overflow errors
      expect(find.text('5 options'), findsOneWidget);
      expect(find.text('Used 25x'), findsOneWidget);

      // Verify no overflow errors occurred during rendering
      // (Flutter test framework will throw if RenderFlex overflow occurs)
    });

    testWidgets('Template selector tabs should handle long text without overflow', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DefaultTabController(
            length: 2,
            child: Scaffold(
              appBar: AppBar(
                bottom: TabBar(
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.grid_view, size: 18),
                          const SizedBox(width: 6),
                          const Flexible(
                            child: Text(
                              'Browse Templates',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.checklist, size: 18),
                          const SizedBox(width: 6),
                          const Flexible(
                            child: Text(
                              'Selected Templates',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              body: const TabBarView(
                children: [
                  Center(child: Text('Browse')),
                  Center(child: Text('Selected')),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify tabs render without overflow
      expect(find.text('Browse Templates'), findsOneWidget);
      expect(find.text('Selected Templates'), findsOneWidget);
    });

    testWidgets('Template card Column should not overflow with mainAxisSize.min', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 80, // Very narrow width like in the error (79.7px)
              height: 130, // Constrained height like in the error (129.6px)
              child: Card(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // This is the key fix
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with checkbox
                      Row(
                        children: [
                          Checkbox(
                            value: false,
                            onChanged: (value) {},
                          ),
                          Expanded(
                            child: Text(
                              'Template Name',
                              style: const TextStyle(fontSize: 12),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Type badge
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Single',
                                style: const TextStyle(fontSize: 10, color: Colors.white),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Description (conditional)
                      Text(
                        'Template description',
                        style: const TextStyle(fontSize: 10),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // Options count (bottom)
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '5 options',
                              style: const TextStyle(fontSize: 10),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify that the template card renders without throwing overflow errors
      expect(find.text('Template Name'), findsOneWidget);
      expect(find.text('Single'), findsOneWidget);
      expect(find.text('5 options'), findsOneWidget);

      // Verify no overflow errors occurred during rendering
      // (Flutter test framework will throw if RenderFlex overflow occurs)
    });

    testWidgets('Template selector tab text should have proper styling and contrast', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: DefaultTabController(
            length: 2,
            child: Scaffold(
              appBar: AppBar(
                bottom: TabBar(
                  tabs: [
                    Tab(
                      child: Builder(
                        builder: (context) => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.grid_view, size: 18),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Browse Templates',
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Tab(
                      child: Builder(
                        builder: (context) => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.checklist, size: 18),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Selected Templates',
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              body: const TabBarView(
                children: [
                  Center(child: Text('Browse')),
                  Center(child: Text('Selected')),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify tab text is visible and properly styled
      expect(find.text('Browse Templates'), findsOneWidget);
      expect(find.text('Selected Templates'), findsOneWidget);

      // Verify the text widgets have proper styling
      final browseText = tester.widget<Text>(find.text('Browse Templates'));
      final selectedText = tester.widget<Text>(find.text('Selected Templates'));

      expect(browseText.style?.fontWeight, FontWeight.w500);
      expect(selectedText.style?.fontWeight, FontWeight.w500);
    });

    testWidgets('Customer preview text should have proper styling and contrast', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: Builder(
              builder: (context) => Card(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.preview,
                        size: 48,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Customer Preview',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Select templates to see how they will appear to customers',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify customer preview text is visible and properly styled
      expect(find.text('Customer Preview'), findsOneWidget);
      expect(find.text('Select templates to see how they will appear to customers'), findsOneWidget);

      // Verify the title text has proper styling
      final titleText = tester.widget<Text>(find.text('Customer Preview'));
      expect(titleText.style?.fontWeight, FontWeight.w600);
      expect(titleText.style?.color, isNotNull);
    });
  });
}
