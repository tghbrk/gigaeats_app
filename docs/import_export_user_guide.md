# GigaEats Menu Import/Export User Guide

## Overview
The GigaEats menu import/export system allows restaurant vendors to efficiently manage their menu data using familiar spreadsheet tools like Excel or Google Sheets. This guide covers everything you need to know to successfully import and export your menu data.

## Quick Start Guide

### 1. First Time Setup
1. **Backup Your Current Menu**: Always export your existing menu before importing new data
2. **Download Template**: Get a template with sample data to understand the format
3. **Start Small**: Begin with 5-10 items to test the process
4. **Use Preview**: Always preview your data before importing

### 2. Basic Import Process
1. Download a user-friendly template (CSV or Excel)
2. Edit the template with your menu items
3. Click "Preview" to validate your data
4. Review the preview and fix any errors
5. Confirm the import

## Template Formats

### User-Friendly Format (Recommended)
- **Best for**: Manual editing, first-time users, small to medium menus
- **Features**: Clear column headers, Yes/No values, simple customizations
- **Sample Headers**: Item Name, Description, Category, Price (RM), Available, etc.

### Technical Format (Advanced)
- **Best for**: System integrations, large menus, advanced users
- **Features**: System field names, JSON customizations, all database fields
- **Sample Headers**: name, description, category, base_price, is_available, etc.

## Required Fields

### Mandatory Information
- **Item Name**: The name of your menu item (e.g., "Nasi Lemak Special")
- **Category**: Food category (e.g., "Main Course", "Beverage", "Dessert")
- **Price (RM)**: Base price in Malaysian Ringgit (must be positive)

### Optional but Recommended
- **Description**: Detailed description of the item
- **Available**: Whether the item is currently available (Yes/No)
- **Preparation Time**: How long it takes to prepare (in minutes)
- **Dietary Information**: Halal, Vegetarian, Vegan, Spicy status

## Customizations Format

### Simple Text Format
Use this easy-to-understand format for menu customizations:

```
Group Name: Option1(+price), Option2(+price); Next Group: Option1(+price)
```

### Examples
```
Size*: Small(+0), Medium(+2.00), Large(+4.00)
Size*: Small(+0), Large(+2.00); Spice Level: Mild(+0), Medium(+0), Hot(+1.00)
Protein*: Chicken(+3.00), Beef(+4.00), Fish(+3.50); Extras: Extra Rice(+2.00), Extra Sauce(+1.00)
```

### Rules
- **Required Groups**: End group name with asterisk (*) - customers must choose
- **Optional Groups**: No asterisk - customers can skip
- **Pricing**: Use (+amount) for additional cost, (+0) for no extra charge
- **Separators**: Use semicolon (;) between groups, comma (,) between options

## Categories

### Automatic Creation
- New categories are created automatically when you import
- Categories are case-sensitive ("Main Course" ≠ "main course")
- Use consistent naming across your menu

### Recommended Categories
- **Main Course**: Rice dishes, noodles, meat dishes
- **Appetizer**: Starters, small plates
- **Beverage**: Drinks, juices, coffee, tea
- **Dessert**: Sweet dishes, ice cream
- **Side Dish**: Accompaniments, extras

## Data Validation

### Common Errors and Solutions

#### Missing Required Fields
- **Error**: "Item name is required"
- **Solution**: Ensure every row has a name in the Item Name column

#### Invalid Pricing
- **Error**: "Price must be non-negative"
- **Solution**: Check that all prices are positive numbers (no negative values)

#### Category Issues
- **Error**: "Category is required"
- **Solution**: Assign a category to every menu item

#### Customization Format Errors
- **Error**: "Invalid customization format"
- **Solution**: Follow the text format exactly: "Group: Option(+price)"

### Warnings vs Errors
- **Errors**: Must be fixed before importing (red indicators)
- **Warnings**: Recommended to fix but not mandatory (orange indicators)

## Best Practices

### Before Importing
1. **Export Current Menu**: Create a backup of your existing menu
2. **Plan Your Categories**: Decide on consistent category names
3. **Prepare Images**: Have image URLs ready if using them
4. **Test Small**: Start with a few items to test the process

### During Editing
1. **Use Consistent Naming**: Keep category and item names consistent
2. **Check Pricing**: Ensure all prices are in RM and positive
3. **Validate Customizations**: Test the customization format
4. **Review Descriptions**: Make descriptions clear and appealing

### After Importing
1. **Review Your Menu**: Check that everything imported correctly
2. **Test Ordering**: Place a test order to verify customizations work
3. **Update Images**: Add or update item images if needed
4. **Monitor Performance**: Check how the new items perform

## Troubleshooting

### File Format Issues
- **Problem**: "Unsupported file format"
- **Solution**: Use CSV, Excel (.xlsx, .xls), or JSON files only

### Import Failures
- **Problem**: Import process fails
- **Solution**: Check file size (max 10MB), ensure proper format, try preview first

### Data Not Appearing
- **Problem**: Imported items don't show in menu
- **Solution**: Check if items are marked as "Available", verify category assignment

### Customization Problems
- **Problem**: Customizations not working in app
- **Solution**: Verify text format, check for special characters, test with simple options first

## Advanced Features

### Bulk Pricing
- Set different prices for bulk orders
- Specify minimum quantity for bulk pricing
- Example: Regular price RM 12.00, Bulk price RM 10.00 for 10+ items

### Nutritional Information
- Add nutritional data in JSON format (technical format only)
- Include calories, protein, carbs, fat, etc.

### Tags and Allergens
- Use comma-separated lists: "spicy, popular, new"
- Common allergens: "nuts, dairy, eggs, gluten"

## Support and Help

### Getting Help
- Use the Help button (?) in the import screen
- Check the preview feature to validate your data
- Review error messages carefully - they provide specific guidance

### Common Questions
- **Q**: Can I import the same item multiple times?
- **A**: Yes, but it will create duplicates. Use unique names or update existing items.

- **Q**: What happens to my existing menu when I import?
- **A**: New items are added. Existing items remain unless you have duplicates.

- **Q**: Can I import items without prices?
- **A**: No, price is required for all menu items.

### Best Results
- Start with the user-friendly template
- Use the preview feature every time
- Keep your source file for future updates
- Export regularly as backup

## File Size and Limits
- **Maximum file size**: 10MB
- **Recommended items per import**: 100-500 items
- **Supported formats**: CSV, Excel (.xlsx, .xls), JSON

## Security and Privacy
- Files are processed securely and not stored permanently
- Only you can access your menu data
- All data transmission is encrypted

---

*For technical support or questions, contact the GigaEats support team through the app.*
