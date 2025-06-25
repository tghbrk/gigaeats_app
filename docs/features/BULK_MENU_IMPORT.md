# Bulk Menu Import Feature

## Overview

The Bulk Menu Import feature allows vendors to upload their complete menu catalog using CSV or Excel files, significantly reducing the time required to set up their menu compared to manual entry.

## Features

### ✅ Implemented Features

1. **File Format Support**
   - CSV (.csv) files
   - Excel (.xlsx, .xls) files
   - Maximum file size: 10MB
   - Maximum rows: 1000 items

2. **Template Generation**
   - Downloadable CSV template with sample data
   - Downloadable Excel template with sample data
   - Comprehensive field documentation
   - Sample menu items for reference

3. **Data Validation**
   - Required field validation (Name, Category, Base Price)
   - Data type validation (numbers, booleans, JSON)
   - Price validation (positive numbers)
   - Quantity validation (logical min/max relationships)
   - Duplicate name detection
   - JSON format validation for customizations

4. **Import Preview**
   - Complete preview of all items before import
   - Error and warning display
   - Filter by status (all, valid, errors, warnings)
   - Detailed item inspection
   - Success rate calculation

5. **Batch Processing**
   - Processes items in batches to avoid database overload
   - Continues processing even if individual items fail
   - Comprehensive error reporting

6. **Integration**
   - Seamlessly integrated into vendor menu management
   - Proper RLS (Row Level Security) compliance
   - Automatic category creation
   - Customization options support

## Supported Fields

### Required Fields
- **Item Name**: Unique menu item name
- **Category**: Menu category (auto-created if doesn't exist)
- **Base Price (RM)**: Price in Malaysian Ringgit

### Optional Fields
- **Description**: Item description
- **Unit**: Unit of measurement (default: pax)
- **Min/Max Order Qty**: Order quantity constraints
- **Prep Time (min)**: Preparation time in minutes
- **Available (Y/N)**: Availability status
- **Halal/Vegetarian/Vegan/Spicy (Y/N)**: Dietary information
- **Spicy Level (1-5)**: Spiciness rating
- **Allergens**: Comma-separated allergen list
- **Tags**: Comma-separated tag list
- **Image URL**: Direct link to item image
- **Nutritional Info (JSON)**: Nutritional data in JSON format
- **Bulk Price/Qty**: Bulk pricing information
- **Customizations (JSON)**: Customization options in JSON format

## File Format Examples

### CSV Format
```csv
Item Name,Description,Category,Base Price (RM),Unit,Available (Y/N),Halal (Y/N)
Nasi Lemak,Traditional coconut rice,Rice Dishes,12.50,pax,Y,Y
Teh Tarik,Malaysian pulled tea,Beverages,3.50,cup,Y,Y
```

### Customizations JSON Format
```json
[
  {
    "name": "Size",
    "type": "single_select",
    "required": true,
    "options": [
      {"name": "Small", "price": 0},
      {"name": "Large", "price": 2.00}
    ]
  },
  {
    "name": "Add-ons",
    "type": "multi_select",
    "required": false,
    "options": [
      {"name": "Extra Cheese", "price": 1.50},
      {"name": "Extra Sauce", "price": 0.50}
    ]
  }
]
```

## User Flow

1. **Access Import**: Vendor navigates to Menu Management → More Options → Import Menu
2. **Download Template**: Download CSV or Excel template with sample data
3. **Prepare Data**: Fill in menu items using the template format
4. **Upload File**: Select and upload the completed file
5. **Review Results**: View processing results with error/warning details
6. **Preview Items**: Review all items before final import
7. **Confirm Import**: Complete the import process
8. **Verification**: Verify imported items in menu management

## Technical Implementation

### Architecture
```
BulkMenuImportScreen
├── MenuImportService (File processing)
├── MenuTemplateService (Template generation)
├── MenuBulkImportService (Database operations)
└── ImportPreviewScreen (Preview & confirmation)
```

### Key Components

1. **MenuImportService**
   - File parsing (CSV/Excel)
   - Data validation
   - Error reporting

2. **MenuTemplateService**
   - Template generation
   - Sample data creation
   - Instructions generation

3. **MenuBulkImportService**
   - Batch database operations
   - RLS compliance
   - Error handling

4. **UI Components**
   - File picker widget
   - Template download cards
   - Import preview interface
   - Progress indicators

### Database Integration

- Uses existing `menu_items` table structure
- Maintains RLS policies for vendor isolation
- Supports customization options via related tables
- Automatic category creation in `menu_categories`

## Error Handling

### Validation Errors
- Missing required fields
- Invalid data types
- Negative prices
- Invalid quantity relationships
- Malformed JSON

### Import Errors
- Database connection issues
- Permission errors
- Duplicate name conflicts
- File processing failures

### User Feedback
- Real-time validation feedback
- Detailed error messages
- Suggested fixes
- Progress indicators

## Performance Considerations

- **Batch Processing**: Items processed in batches of 10
- **Memory Management**: Streaming file processing
- **Database Optimization**: Bulk insert operations
- **Error Recovery**: Continues processing despite individual failures

## Security Features

- **File Validation**: Size and format restrictions
- **RLS Compliance**: Vendor-specific data isolation
- **Input Sanitization**: Prevents injection attacks
- **Permission Checks**: Vendor authentication required

## Future Enhancements

### Planned Features
- [ ] Export existing menu to CSV/Excel
- [ ] Bulk update operations
- [ ] Image upload integration
- [ ] Advanced validation rules
- [ ] Import history tracking
- [ ] Scheduled imports
- [ ] API integration for external systems

### Potential Improvements
- [ ] Real-time collaboration
- [ ] Version control for menu changes
- [ ] Advanced filtering and search
- [ ] Integration with inventory management
- [ ] Multi-language support
- [ ] Advanced analytics and reporting

## Testing

### Test Scenarios
1. **Valid Data Import**: Complete successful import
2. **Error Handling**: Various error conditions
3. **Large File Processing**: Performance with maximum file size
4. **Edge Cases**: Empty files, malformed data
5. **Security Testing**: File upload security
6. **RLS Testing**: Vendor data isolation

### Sample Test Data
- Template files with various scenarios
- Error condition test cases
- Performance test datasets
- Security test vectors

## Support and Documentation

### User Documentation
- Step-by-step import guide
- Template field explanations
- Common error solutions
- Best practices guide

### Developer Documentation
- API documentation
- Database schema
- Component architecture
- Extension guidelines

## Conclusion

The Bulk Menu Import feature significantly improves the vendor onboarding experience by allowing rapid menu setup through file uploads. The comprehensive validation, preview functionality, and error handling ensure data quality while maintaining system security and performance.
