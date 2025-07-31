import 'package:flutter/material.dart';
import 'dart:async';

/// Search bar widget for driver wallet transaction filtering
class DriverTransactionSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onSearch;
  final VoidCallback? onClear;
  final String hintText;
  final Duration debounceDelay;

  const DriverTransactionSearchBar({
    super.key,
    required this.controller,
    required this.onSearch,
    this.onClear,
    this.hintText = 'Search transactions, order IDs, descriptions...',
    this.debounceDelay = const Duration(milliseconds: 500),
  });

  @override
  State<DriverTransactionSearchBar> createState() => _DriverTransactionSearchBarState();
}

class _DriverTransactionSearchBarState extends State<DriverTransactionSearchBar> {
  Timer? _debounceTimer;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final text = widget.controller.text;
    setState(() {
      _isSearching = text.isNotEmpty;
    });

    // Cancel previous timer
    _debounceTimer?.cancel();

    // Start new timer for debounced search
    _debounceTimer = Timer(widget.debounceDelay, () {
      widget.onSearch(text);
    });
  }

  void _clearSearch() {
    widget.controller.clear();
    widget.onClear?.call();
    setState(() {
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: TextField(
        controller: widget.controller,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          suffixIcon: _isSearching
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  onPressed: _clearSearch,
                  tooltip: 'Clear search',
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        style: theme.textTheme.bodyMedium,
        textInputAction: TextInputAction.search,
        onSubmitted: widget.onSearch,
      ),
    );
  }
}
