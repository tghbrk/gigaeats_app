import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/custom_error_widget.dart';
import '../../data/models/system_setting.dart';
import '../providers/admin_providers_index.dart';
import '../widgets/system_settings_widgets.dart';

class AdminSystemSettingsScreen extends ConsumerStatefulWidget {
  const AdminSystemSettingsScreen({super.key});

  @override
  ConsumerState<AdminSystemSettingsScreen> createState() => _AdminSystemSettingsScreenState();
}

class _AdminSystemSettingsScreenState extends ConsumerState<AdminSystemSettingsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String? _selectedCategory;

  final List<String> _categories = [
    'All',
    SettingCategory.general,
    SettingCategory.payment,
    SettingCategory.notification,
    SettingCategory.security,
    SettingCategory.delivery,
    SettingCategory.ui,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    
    // Load settings on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSettings();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadSettings() {
    final filter = SettingsFilter(
      category: _selectedCategory == 'All' ? null : _selectedCategory,
      searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      limit: 100,
    );
    
    ref.read(systemSettingsProvider(filter).future);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(systemSettingsProvider);
              _loadSettings();
            },
            tooltip: 'Refresh Settings',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _showExportDialog(context),
            tooltip: 'Export Settings',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateSettingDialog(context),
            tooltip: 'Add Setting',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          onTap: (index) {
            setState(() {
              _selectedCategory = _categories[index];
            });
            _loadSettings();
          },
          tabs: _categories.map((category) => Tab(
            text: category == 'All' ? 'All' : category.toUpperCase(),
          )).toList(),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search settings...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                          });
                          _loadSettings();
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                // Debounce search
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (_searchQuery == value) {
                    _loadSettings();
                  }
                });
              },
            ),
          ),
          
          // Settings List
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _categories.map((category) {
                final filter = SettingsFilter(
                  category: category == 'All' ? null : category,
                  searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
                  limit: 100,
                );
                
                return _buildSettingsTab(filter);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab(SettingsFilter filter) {
    final settingsAsync = ref.watch(systemSettingsProvider(filter));

    return settingsAsync.when(
      data: (settings) {
        if (settings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.settings_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No settings found',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  _searchQuery.isNotEmpty
                      ? 'Try adjusting your search criteria'
                      : 'No settings available in this category',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: settings.length,
          itemBuilder: (context, index) {
            final setting = settings[index];
            return SystemSettingCard(
              setting: setting,
              onEdit: () => _showEditSettingDialog(context, setting),
              onDelete: () => _showDeleteSettingDialog(context, setting),
            );
          },
        );
      },
      loading: () => const LoadingWidget(message: 'Loading settings...'),
      error: (error, stack) => CustomErrorWidget(
        message: 'Failed to load settings: $error',
        onRetry: () {
          ref.invalidate(systemSettingsProvider);
          _loadSettings();
        },
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Settings'),
        content: const Text('Export all system settings to a file?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _exportSettings();
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  void _showCreateSettingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => SystemSettingFormDialog(
        onSave: (settingKey, settingValue, description, category, isPublic) async {
          try {
            await ref.read(adminRepositoryProvider).createSystemSetting(
              settingKey: settingKey,
              settingValue: settingValue,
              description: description,
              category: category,
              isPublic: isPublic,
            );
            
            if (context.mounted) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Setting created successfully')),
              );
            }
            
            // Refresh settings
            ref.invalidate(systemSettingsProvider);
            _loadSettings();
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to create setting: $e')),
              );
            }
          }
        },
      ),
    );
  }

  void _showEditSettingDialog(BuildContext context, SystemSetting setting) {
    showDialog(
      context: context,
      builder: (context) => SystemSettingFormDialog(
        setting: setting,
        onSave: (settingKey, settingValue, description, category, isPublic) async {
          try {
            await ref.read(adminRepositoryProvider).updateSystemSetting(
              setting.settingKey,
              settingValue,
              reason: 'Updated via admin interface',
            );
            
            if (context.mounted) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Setting updated successfully')),
              );
            }
            
            // Refresh settings
            ref.invalidate(systemSettingsProvider);
            _loadSettings();
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to update setting: $e')),
              );
            }
          }
        },
      ),
    );
  }

  void _showDeleteSettingDialog(BuildContext context, SystemSetting setting) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Setting'),
        content: Text('Are you sure you want to delete "${setting.settingKey}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                await ref.read(adminRepositoryProvider).deleteSystemSetting(
                  setting.settingKey,
                  reason: 'Deleted via admin interface',
                );
                
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Setting deleted successfully')),
                  );
                }
                
                // Refresh settings
                ref.invalidate(systemSettingsProvider);
                _loadSettings();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete setting: $e')),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _exportSettings() {
    // TODO: Implement settings export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export functionality coming soon')),
    );
  }
}
