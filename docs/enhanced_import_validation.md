# Enhanced Import Validation and Parsing

## Overview
The enhanced import system now supports both technical and user-friendly CSV formats, with intelligent parsing and clear validation messages.

## Supported Formats

### 1. User-Friendly Format (Recommended)
- **Headers**: Human-readable column names
- **Values**: Simple Yes/No, clear pricing, text customizations
- **Target Users**: Restaurant vendors, non-technical users

### 2. Technical Format (Legacy)
- **Headers**: System field names (snake_case)
- **Values**: JSON customizations, boolean flags
- **Target Users**: System integrations, technical users

## Header Mapping

The system automatically detects and maps headers from both formats:

| Field | User-Friendly Headers | Technical Headers |
|-------|----------------------|-------------------|
| Item Name | "Item Name", "Name" | "name" |
| Price | "Price (RM)", "Price" | "base_price" |
| Available | "Available" | "is_available" |
| Halal | "Halal" | "is_halal" |
| Customizations | "Customizations" | "customization_groups" |

## Boolean Value Parsing

Supports multiple formats for boolean fields:

| True Values | False Values |
|-------------|--------------|
| Yes, Y, True, 1 | No, N, False, 0 |

**Case insensitive**: "YES", "yes", "Yes" all work

## Customizations Format Support

### Simplified Text Format (User-Friendly)
```
Size*: Small(+0), Large(+2.00); Add-ons: Cheese(+1.50), Bacon(+2.00)
```

**Rules:**
- Groups separated by semicolons (;)
- Options separated by commas (,)
- Prices in parentheses (+amount)
- Required groups marked with asterisk (*)

### JSON Format (Technical)
```json
[{"name":"Size","type":"single","isRequired":true,"options":[{"name":"Small","additionalPrice":0}]}]
```

## Validation Features

### 1. Intelligent Format Detection
- Automatically detects JSON vs text customizations
- Falls back to alternative format if parsing fails
- Provides format-specific error messages

### 2. Enhanced Error Messages
Instead of technical errors, users see:
- ❌ "Item name is required"
- ❌ "Invalid customization format. Expected: 'Group: Option1(+price)'"
- ❌ "Price must be a valid number"

### 3. Flexible Header Matching
- Supports variations: "Price (RM)", "Price", "base_price"
- Case insensitive matching
- Handles extra spaces and formatting

### 4. Data Type Validation
- **Prices**: Must be positive numbers
- **Quantities**: Must be integers
- **Spicy Level**: Must be 1-5 (if specified)
- **Boolean Fields**: Accepts Yes/No, Y/N, True/False, 1/0

## Import Process

### 1. File Upload
- Supports CSV, Excel (.xlsx, .xls), JSON
- Maximum file size: 10MB
- Maximum rows: 1000

### 2. Header Detection
- Scans first row for column headers
- Maps to internal field names
- Validates required fields present

### 3. Data Parsing
- Row-by-row processing
- Type conversion and validation
- Error collection with row numbers

### 4. Conflict Resolution
- **Skip**: Ignore existing items
- **Update**: Modify existing items
- **Replace**: Delete and recreate

### 5. Result Summary
- Total rows processed
- Valid vs invalid rows
- Detailed error list
- Warning messages

## Error Handling

### Common Validation Errors

1. **Missing Required Fields**
   ```
   Missing required columns: Item Name, Category, Price (RM)
   ```

2. **Invalid Data Types**
   ```
   Row 5: Price must be a valid number (found: "abc")
   ```

3. **Customization Format Errors**
   ```
   Row 8: Invalid customization format. Expected: "Group: Option1(+price), Option2(+price)"
   ```

4. **Boolean Value Errors**
   ```
   Row 12: Available must be Yes/No (found: "maybe")
   ```

### Warning Messages

1. **Default Values Applied**
   ```
   Row 3: Prep time not specified, defaulting to 30 minutes
   ```

2. **Optional Field Skipped**
   ```
   Row 7: Spicy level not specified for spicy item, defaulting to 1
   ```

## Best Practices

### For Vendors (User-Friendly Format)
1. Use the downloadable template
2. Keep customizations simple: "Size: Small(+0), Large(+2.00)"
3. Use Yes/No for boolean fields
4. Include currency in price headers: "Price (RM)"
5. Test with a small file first

### For Developers (Technical Format)
1. Use exact field names from documentation
2. Validate JSON syntax for customizations
3. Include all required fields
4. Use consistent data types

### For Both Formats
1. Avoid empty rows in the middle of data
2. Keep item names unique
3. Use consistent category names
4. Validate file before uploading
5. Review import preview before confirming

## Migration Guide

### From Technical to User-Friendly
1. Export existing data in user-friendly format
2. Edit using spreadsheet software
3. Re-import with simplified headers

### Maintaining Both Formats
- System supports both simultaneously
- Choose format based on user expertise
- Technical format for system integrations
- User-friendly format for manual editing

## Troubleshooting

### Import Fails Completely
- Check file format (CSV/Excel)
- Verify required columns present
- Ensure file size under 10MB

### Partial Import Success
- Review error messages for specific rows
- Fix data issues and re-import
- Use "Update" mode to fix existing items

### Customizations Not Working
- Check format: "Group: Option(+price)"
- Verify semicolon separation for multiple groups
- Ensure parentheses around prices

### Boolean Fields Not Recognized
- Use Yes/No instead of custom values
- Check for extra spaces
- Ensure consistent capitalization
