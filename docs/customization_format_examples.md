# Simplified Customizations Format Examples

## Overview
The new simplified customizations format replaces complex JSON with human-readable text that vendors can easily understand and edit manually.

## Format Rules
- **Groups separated by semicolons (;)**
- **Options separated by commas (,)**
- **Prices in parentheses (+amount or +0 for free)**
- **Required groups marked with asterisk (*)**
- **No spaces around operators for consistency**

## Basic Examples

### Single Selection (Choose One)
```
Size: Small(+0), Medium(+2.00), Large(+4.00)
```

### Multiple Selection (Choose Multiple)
```
Add-ons: Extra Cheese(+1.50), Bacon(+2.00), Mushrooms(+1.00)
```

### Required Selection
```
Protein*: Chicken(+3.00), Beef(+4.00), Fish(+3.50)
```

## Real-World Examples

### Nasi Lemak Special
```
Protein*: Chicken(+3.00), Beef(+4.00), Fish(+3.50); Spice Level: Mild(+0), Medium(+0), Hot(+0); Add-ons: Extra Rice(+2.00), Fried Egg(+1.50)
```

### Teh Tarik
```
Sweetness: Less Sweet(+0), Normal(+0), Extra Sweet(+0); Temperature: Hot(+0), Iced(+0.50)
```

### Pizza
```
Size*: Personal(+0), Regular(+8.00), Large(+15.00); Crust*: Thin(+0), Thick(+2.00), Stuffed(+4.00); Toppings: Pepperoni(+3.00), Mushrooms(+2.00), Extra Cheese(+2.50), Olives(+1.50)
```

### Burger
```
Patty*: Beef(+0), Chicken(+0), Fish(+1.00), Vegetarian(+0); Size: Regular(+0), Large(+3.00); Add-ons: Cheese(+1.50), Bacon(+2.00), Avocado(+2.50), Extra Patty(+5.00)
```

### Coffee
```
Size*: Small(+0), Medium(+2.00), Large(+3.50); Milk: Regular(+0), Soy(+1.00), Almond(+1.50), Oat(+1.50); Extras: Extra Shot(+2.00), Decaf(+0), Sugar Free(+0)
```

## Complex Example
```
Size*: Small(+0), Medium(+3.00), Large(+6.00), Extra Large(+9.00); Protein*: Chicken(+0), Beef(+2.00), Seafood(+4.00), Tofu(+0); Spice Level: No Spice(+0), Mild(+0), Medium(+0), Hot(+0), Extra Hot(+1.00), Thai Hot(+2.00); Vegetables: Bean Sprouts(+1.00), Extra Vegetables(+2.00), No Vegetables(+0); Extras: Fried Egg(+1.50), Extra Noodles(+2.00), Soup(+1.00)
```

## Comparison: Old vs New Format

### Old Format (Complex JSON)
```json
[{"id":"4b5c4b5c-443e-4a3e-a0c6-e0ca8b9f3b4f","name":"Telur Keadaan","type":"single","is_required":true,"options":[{"id":"2fc1e7ac-3c8b-4d82-a7f1-fc2b8e117149","name":"Telur Keadaan","additional_price":0.0,"default":false},{"id":"2fc1e7ac-3c8b-4d82-a7f1-fc2b8e117148","name":"Daun Basi","additional_price":0.0,"default":false}]}]
```

### New Format (Simple Text)
```
Egg Style*: Sunny Side Up(+0), Scrambled(+0)
```

## Benefits

1. **Human Readable**: Vendors can understand at a glance
2. **Easy to Edit**: Simple text editing in spreadsheet software
3. **No Technical Knowledge**: No need to understand JSON or UUIDs
4. **Error Resistant**: Simple format reduces chance of syntax errors
5. **Bulk Editable**: Easy to copy/paste and modify across multiple items
6. **Self-Documenting**: Format is intuitive and self-explanatory

## Validation Rules

- Group names cannot be empty
- Each group must have at least one option
- Option names cannot be empty
- Prices must be non-negative numbers
- Required groups must be marked with asterisk (*)
- Proper syntax: `Group: Option1(+price), Option2(+price)`

## Tips for Vendors

1. **Keep group names short and clear**: "Size", "Protein", "Add-ons"
2. **Use consistent pricing format**: Always include + sign and 2 decimal places
3. **Mark required selections**: Add * after group name for mandatory choices
4. **Test with simple examples first**: Start with basic customizations
5. **Use the template**: Download the provided template for guidance
