import 'package:flutter/material.dart';

/// Custom search bar widget for the GigaEats app
class SearchBarWidget extends StatefulWidget {
  final String hintText;
  final Function(String) onChanged;
  final Function(String)? onSubmitted;
  final VoidCallback? onClear;
  final TextEditingController? controller;
  final bool enabled;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderRadius;
  final bool showClearButton;
  final bool autofocus;

  const SearchBarWidget({
    super.key,
    required this.hintText,
    required this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.controller,
    this.enabled = true,
    this.prefixIcon,
    this.suffixIcon,
    this.margin,
    this.padding,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = 12.0,
    this.showClearButton = true,
    this.autofocus = false,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  late TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onTextChanged);
    _hasText = _controller.text.isNotEmpty;
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    } else {
      _controller.removeListener(_onTextChanged);
    }
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
    widget.onChanged(_controller.text);
  }

  void _onClear() {
    _controller.clear();
    widget.onClear?.call();
    widget.onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: widget.margin ?? const EdgeInsets.all(16.0),
      child: TextField(
        controller: _controller,
        enabled: widget.enabled,
        autofocus: widget.autofocus,
        onSubmitted: widget.onSubmitted,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          prefixIcon: widget.prefixIcon ?? 
            Icon(
              Icons.search,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          suffixIcon: _buildSuffixIcon(),
          filled: true,
          fillColor: widget.backgroundColor ?? 
            colorScheme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            borderSide: BorderSide(
              color: widget.borderColor ?? 
                colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            borderSide: BorderSide(
              color: widget.borderColor ?? 
                colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            borderSide: BorderSide(
              color: colorScheme.primary,
              width: 2.0,
            ),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            borderSide: BorderSide(
              color: colorScheme.outline.withValues(alpha: 0.1),
            ),
          ),
          contentPadding: widget.padding ?? 
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        ),
        style: TextStyle(
          color: colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget? _buildSuffixIcon() {
    if (widget.suffixIcon != null) {
      return widget.suffixIcon;
    }

    if (widget.showClearButton && _hasText) {
      return IconButton(
        icon: Icon(
          Icons.clear,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        onPressed: widget.enabled ? _onClear : null,
      );
    }

    return null;
  }
}

/// Simplified search bar for quick implementation
class SimpleSearchBar extends StatelessWidget {
  final String hintText;
  final Function(String) onChanged;
  final TextEditingController? controller;

  const SimpleSearchBar({
    super.key,
    required this.hintText,
    required this.onChanged,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return SearchBarWidget(
      hintText: hintText,
      onChanged: onChanged,
      controller: controller,
    );
  }
}

/// Search bar with filter button
class SearchBarWithFilter extends StatelessWidget {
  final String hintText;
  final Function(String) onChanged;
  final VoidCallback? onFilterTap;
  final TextEditingController? controller;
  final bool hasActiveFilters;

  const SearchBarWithFilter({
    super.key,
    required this.hintText,
    required this.onChanged,
    this.onFilterTap,
    this.controller,
    this.hasActiveFilters = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SearchBarWidget(
      hintText: hintText,
      onChanged: onChanged,
      controller: controller,
      suffixIcon: IconButton(
        icon: Icon(
          Icons.filter_list,
          color: hasActiveFilters 
            ? colorScheme.primary 
            : colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        onPressed: onFilterTap,
      ),
    );
  }
}

/// Search bar for vendors/restaurants
class VendorSearchBar extends StatelessWidget {
  final Function(String) onChanged;
  final TextEditingController? controller;

  const VendorSearchBar({
    super.key,
    required this.onChanged,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return SearchBarWidget(
      hintText: 'Search restaurants...',
      onChanged: onChanged,
      controller: controller,
      prefixIcon: const Icon(Icons.restaurant),
    );
  }
}

/// Search bar for menu items
class MenuSearchBar extends StatelessWidget {
  final Function(String) onChanged;
  final TextEditingController? controller;

  const MenuSearchBar({
    super.key,
    required this.onChanged,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return SearchBarWidget(
      hintText: 'Search menu items...',
      onChanged: onChanged,
      controller: controller,
      prefixIcon: const Icon(Icons.fastfood),
    );
  }
}

/// Search bar for customers
class CustomerSearchBar extends StatelessWidget {
  final Function(String) onChanged;
  final TextEditingController? controller;

  const CustomerSearchBar({
    super.key,
    required this.onChanged,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return SearchBarWidget(
      hintText: 'Search customers...',
      onChanged: onChanged,
      controller: controller,
      prefixIcon: const Icon(Icons.person_search),
    );
  }
}
