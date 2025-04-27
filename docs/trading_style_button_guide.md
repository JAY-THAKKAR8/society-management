# Trading Style Button Guide

This guide explains how to use the `TradingStyleButton` component throughout the app to maintain a consistent trading app-like UI.

## Basic Usage

Import the button in your file:

```dart
import 'package:society_management/widget/trading_style_button.dart';
```

Then use it in your widget tree:

```dart
TradingStyleButton(
  text: 'View Details',
  onPressed: () {
    // Your action here
  },
)
```

## Customization Options

The `TradingStyleButton` supports several customization options:

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `text` | String | Required | The text to display on the button |
| `onPressed` | VoidCallback | Required | The action to perform when the button is pressed |
| `startColor` | Color | Colors.indigo | The start color of the gradient |
| `endColor` | Color | Colors.teal | The end color of the gradient |
| `height` | double | 50 | The height of the button |
| `leadingIcon` | IconData | null | A custom icon to display instead of the chart icons |
| `trailingIcon` | IconData | Icons.arrow_forward | The trailing icon |
| `showChartIcons` | bool | true | Whether to show the chart icons |

## Examples

### Basic Button with Default Trading Icons

```dart
TradingStyleButton(
  text: 'View Details',
  onPressed: () {
    // Navigate to details page
  },
)
```

### Button with Custom Icon

```dart
TradingStyleButton(
  text: 'Add User',
  onPressed: () {
    // Add user logic
  },
  leadingIcon: Icons.person_add,
  showChartIcons: false,
)
```

### Button with Custom Colors

```dart
TradingStyleButton(
  text: 'Delete',
  onPressed: () {
    // Delete logic
  },
  startColor: Colors.red,
  endColor: Colors.redAccent,
  leadingIcon: Icons.delete,
  showChartIcons: false,
)
```

## Replacing Existing Buttons

To replace existing buttons in the app, follow these patterns:

### Replace ElevatedButton

From:
```dart
ElevatedButton(
  onPressed: () {
    // Action
  },
  child: const Text('Button Text'),
)
```

To:
```dart
TradingStyleButton(
  text: 'Button Text',
  onPressed: () {
    // Action
  },
  showChartIcons: false,
)
```

### Replace ElevatedButton.icon

From:
```dart
ElevatedButton.icon(
  onPressed: () {
    // Action
  },
  icon: const Icon(Icons.add),
  label: const Text('Add Item'),
)
```

To:
```dart
TradingStyleButton(
  text: 'Add Item',
  onPressed: () {
    // Action
  },
  leadingIcon: Icons.add,
  showChartIcons: false,
)
```

### Replace CommonButton

From:
```dart
CommonButton(
  text: 'Submit',
  onTap: () {
    // Action
  },
)
```

To:
```dart
TradingStyleButton(
  text: 'Submit',
  onPressed: () {
    // Action
  },
  showChartIcons: false,
)
```

## Best Practices

1. Use `showChartIcons: true` for buttons related to viewing data, statistics, or reports
2. Use `showChartIcons: false` and a custom `leadingIcon` for action buttons like add, edit, delete
3. Keep button text concise and clear
4. Maintain consistent styling across similar actions
5. Consider using custom colors for destructive actions (like delete) to provide visual cues
