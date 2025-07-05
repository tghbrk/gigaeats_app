# Template Analytics and Usage Tracking System

## Overview

The Template Analytics and Usage Tracking System provides comprehensive insights into how customization templates are being used across the GigaEats platform. This system helps vendors understand template performance, optimize their offerings, and make data-driven decisions about their customization strategies.

## Architecture

### Core Components

1. **Template Analytics Provider** (`template_analytics_provider.dart`)
   - Manages analytics state and data loading
   - Provides real-time analytics updates
   - Handles date range filtering and data aggregation

2. **Template Analytics Dashboard** (`template_analytics_dashboard_screen.dart`)
   - Comprehensive analytics interface with multiple tabs
   - Interactive charts and visualizations
   - Date range selection and filtering

3. **Template Usage Tracking Service** (`template_usage_tracking_service.dart`)
   - Tracks template usage in real-time
   - Updates analytics data when orders are created
   - Manages performance metrics calculation

4. **Analytics Widgets**
   - Summary cards with key metrics
   - Performance charts (line, bar, pie)
   - Usage trend visualizations
   - Insights and recommendations

## Features

### 📊 Analytics Dashboard

#### Overview Tab
- **Summary Cards**: Key metrics at a glance
  - Total templates and active templates
  - Menu items using templates
  - Total orders and revenue from templates
  - Utilization rate and average revenue per template
  - Daily average revenue and period duration

- **Quick Statistics**: Real-time performance indicators
- **Top Templates Preview**: Best performing templates snapshot

#### Performance Tab
- **Revenue Performance Chart**: Interactive line chart showing revenue trends
- **Performance List**: Detailed template performance metrics with grades
- **Sortable Metrics**: Sort by performance score, revenue, usage, or name
- **Expandable Details**: Drill-down into individual template metrics

#### Usage Tab
- **Usage Trend Charts**: Bar and pie charts showing template usage patterns
- **Usage Statistics**: Detailed usage breakdowns and patterns
- **Template Distribution**: Visual representation of template adoption

#### Insights Tab
- **AI-Generated Insights**: Automated analysis of template performance
- **Performance Summary**: Grade-based template categorization
- **Recommendations**: Actionable suggestions for optimization
- **Trend Analysis**: Performance trends and growth indicators

### 📈 Key Metrics Tracked

#### Template Performance Metrics
- **Performance Score**: Calculated based on usage, revenue, and conversion
- **Performance Grade**: A+ to F grading system
- **Usage Count**: Number of menu items using the template
- **Orders Count**: Number of orders containing template customizations
- **Revenue Generated**: Total revenue attributed to the template
- **Conversion Rate**: Orders per menu item using the template
- **Average Order Value**: Average value of orders with template customizations
- **Last Used Date**: Most recent usage timestamp

#### Analytics Summary
- **Total Templates**: Count of all templates created
- **Active Templates**: Templates currently in use
- **Template Utilization Rate**: Percentage of templates being used
- **Total Menu Items Using Templates**: Count of menu items with templates
- **Total Orders with Templates**: Orders containing template customizations
- **Total Revenue from Templates**: Revenue generated through templates
- **Average Revenue per Template**: Revenue efficiency metric
- **Daily Average Revenue**: Daily revenue from templates
- **Period Duration**: Analytics period length

### 🔄 Real-time Tracking

#### Order Integration
- Automatic tracking when orders contain template customizations
- Real-time analytics updates
- Performance metrics recalculation
- Usage statistics updates

#### Template Usage Events
- Track individual template usage instances
- Store metadata about customization selections
- Link usage to specific orders and revenue
- Maintain audit trail for analytics

### 💡 Insights and Recommendations

#### Automated Insights
- **Template Adoption Analysis**: Utilization rate insights
- **Revenue Optimization**: Pricing and option recommendations
- **Performance Recognition**: Highlighting successful templates
- **Diversity Suggestions**: Template variety recommendations
- **Underperformance Alerts**: Low-performing template identification

#### Recommendation Types
- **Improve Template Adoption**: For low utilization rates
- **Optimize Template Pricing**: For low revenue generation
- **Expand Template Variety**: For limited template diversity
- **Review Underperforming Templates**: For poor performance scores
- **Performance Celebration**: For excellent results

## Technical Implementation

### Data Models

#### TemplateUsageAnalytics
```dart
class TemplateUsageAnalytics {
  final String id;
  final String templateId;
  final String vendorId;
  final int menuItemsCount;
  final int ordersCount;
  final double revenueGenerated;
  final DateTime? lastUsedAt;
  final DateTime analyticsDate;
  // ... additional fields
}
```

#### TemplateAnalyticsSummary
```dart
class TemplateAnalyticsSummary {
  final String vendorId;
  final int totalTemplates;
  final int activeTemplates;
  final int totalMenuItemsUsingTemplates;
  final int totalOrdersWithTemplates;
  final double totalRevenueFromTemplates;
  final DateTime periodStart;
  final DateTime periodEnd;
  final List<TemplateUsageAnalytics> topPerformingTemplates;
  // ... additional fields
}
```

#### TemplatePerformanceMetrics
```dart
class TemplatePerformanceMetrics {
  final String templateId;
  final String templateName;
  final int usageCount;
  final int ordersCount;
  final double revenueGenerated;
  final double conversionRate;
  final double averageOrderValue;
  final DateTime lastUsed;
  // ... additional fields
}
```

### Database Schema

#### template_usage_analytics
- Stores daily aggregated analytics data
- Tracks template performance over time
- Enables trend analysis and reporting

#### template_usage_events
- Records individual template usage instances
- Links to orders and revenue data
- Provides detailed audit trail

#### Database Functions
- `get_template_analytics_summary`: Aggregates analytics data
- `get_template_performance_metrics`: Calculates performance metrics
- `upsert_template_daily_analytics`: Updates daily analytics
- `update_template_performance_metrics`: Recalculates metrics

### State Management

#### TemplateAnalyticsState
```dart
class TemplateAnalyticsState {
  final TemplateAnalyticsSummary? summary;
  final List<TemplateUsageAnalytics> usageAnalytics;
  final List<TemplatePerformanceMetrics> performanceMetrics;
  final Map<String, List<TemplateUsageAnalytics>> trendData;
  final bool isLoading;
  final String? errorMessage;
  final DateTime? lastUpdated;
  final DateTime periodStart;
  final DateTime periodEnd;
}
```

#### Provider Integration
- Riverpod-based state management
- Family providers for vendor-specific data
- Automatic data loading and caching
- Real-time updates and refresh capabilities

## Navigation Integration

### Template Management Screen
- Analytics tab integrated into template management
- Seamless navigation between templates and analytics
- Contextual analytics for specific templates

### Vendor Dashboard
- Analytics accessible from vendor menu
- Quick access to template performance
- Integration with overall vendor analytics

### Routing
- Dedicated route: `/vendor/template-analytics/:vendorId`
- Deep linking support for specific analytics views
- Role-based access control

## Usage Examples

### Accessing Analytics
```dart
// Navigate to template analytics
context.go('/vendor/template-analytics/$vendorId');

// Access analytics provider
final analytics = ref.watch(templateAnalyticsProvider(vendorId));

// Get top performing templates
final topTemplates = ref.watch(topPerformingTemplatesProvider(vendorId));
```

### Tracking Template Usage
```dart
// Track template usage in order processing
await templateUsageTrackingService.trackTemplateUsage(
  orderId: orderId,
  templateId: templateId,
  vendorId: vendorId,
  revenueAmount: revenueAmount,
);
```

### Custom Analytics Queries
```dart
// Get usage trends
final trends = await trackingService.getUsageTrends(
  vendorId: vendorId,
  startDate: startDate,
  endDate: endDate,
  granularity: 'daily',
);

// Compare template performance
final comparison = await trackingService.getTemplateComparison(
  vendorId: vendorId,
  templateIds: templateIds,
  startDate: startDate,
  endDate: endDate,
);
```

## Performance Considerations

### Optimization Strategies
- **Data Aggregation**: Pre-calculated daily analytics
- **Caching**: Provider-level caching for frequently accessed data
- **Pagination**: Limit data loading for large datasets
- **Background Processing**: Async analytics updates
- **Database Indexing**: Optimized queries for analytics tables

### Scalability
- **Partitioned Tables**: Time-based partitioning for analytics data
- **Archival Strategy**: Automated cleanup of old analytics data
- **Batch Processing**: Efficient bulk analytics updates
- **Real-time Updates**: Optimized for high-frequency usage tracking

## Future Enhancements

### Planned Features
- **Predictive Analytics**: ML-based performance predictions
- **A/B Testing**: Template variation testing
- **Export Functionality**: CSV/PDF analytics reports
- **Advanced Filtering**: Multi-dimensional data filtering
- **Comparative Analysis**: Cross-vendor benchmarking
- **Mobile Optimization**: Enhanced mobile analytics experience

### Integration Opportunities
- **Business Intelligence**: Integration with BI tools
- **Notification System**: Performance alerts and insights
- **Recommendation Engine**: AI-powered template suggestions
- **Customer Analytics**: Customer preference insights
- **Revenue Optimization**: Dynamic pricing recommendations

## Conclusion

The Template Analytics and Usage Tracking System provides vendors with comprehensive insights into their template performance, enabling data-driven decisions and optimization strategies. The system's real-time tracking, detailed analytics, and actionable insights help vendors maximize the value of their customization templates and improve customer satisfaction.
