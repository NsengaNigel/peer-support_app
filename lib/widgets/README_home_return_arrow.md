# Home Return Arrow Widget

This widget provides a permanent return arrow to redirect users to the home page from any screen in the app.

## Features

- **HomeReturnArrow**: A customizable floating or inline home button
- **HomeReturnAppBar**: A custom AppBar with a built-in home button
- Automatic navigation to home with stack clearing
- Customizable colors, sizes, and positioning

## Usage

### 1. HomeReturnAppBar (Recommended for most screens)

Replace any `AppBar` with `HomeReturnAppBar`:

```dart
import '../widgets/home_return_arrow.dart';

// Instead of:
appBar: AppBar(
  title: Text('Screen Title'),
  backgroundColor: Colors.blue,
),

// Use:
appBar: HomeReturnAppBar(
  title: 'Screen Title',
  backgroundColor: Colors.blue,
  foregroundColor: Colors.white,
),
```

### 2. HomeReturnArrow as Floating Action Button

Add a floating home button to any screen:

```dart
import '../widgets/home_return_arrow.dart';

// In your Scaffold:
floatingActionButton: HomeReturnAppBar(
  isFloating: true,
  backgroundColor: Color(0xFF00BCD4),
  iconColor: Colors.white,
  size: 48,
  margin: EdgeInsets.only(bottom: 80),
),
```

### 3. HomeReturnArrow as Inline Widget

Add the home button anywhere in your widget tree:

```dart
import '../widgets/home_return_arrow.dart';

// In your widget:
HomeReturnArrow(
  backgroundColor: Colors.orange,
  iconColor: Colors.white,
  size: 56,
  margin: EdgeInsets.all(16),
),
```

## Properties

### HomeReturnArrow
- `backgroundColor`: Color of the button background (defaults to theme primary color)
- `iconColor`: Color of the home icon (defaults to white)
- `size`: Size of the button (defaults to 56.0)
- `margin`: Margin around the button (defaults to 8px)
- `isFloating`: Whether to render as a floating action button (defaults to false)

### HomeReturnAppBar
- `title`: The title text for the AppBar
- `backgroundColor`: Background color of the AppBar
- `foregroundColor`: Color of text and icons
- `actions`: List of action widgets (same as regular AppBar)
- `bottom`: TabBar or other PreferredSizeWidget
- `showHomeButton`: Whether to show the home button (defaults to true)

## Navigation Behavior

Both widgets automatically navigate to the home screen (`/`) and clear the navigation stack when tapped, ensuring users can always return to the main screen regardless of how deep they are in the app.

## Examples

### Basic AppBar Replacement
```dart
appBar: HomeReturnAppBar(
  title: 'Communities',
  backgroundColor: Color(0xFF00BCD4),
  foregroundColor: Colors.white,
),
```

### AppBar with TabBar
```dart
appBar: HomeReturnAppBar(
  title: 'Search',
  backgroundColor: Color(0xFF00BCD4),
  foregroundColor: Colors.white,
  bottom: TabBar(
    controller: _tabController,
    tabs: [
      Tab(text: 'Posts'),
      Tab(text: 'Communities'),
    ],
  ),
),
```

### Floating Home Button
```dart
floatingActionButton: HomeReturnArrow(
  isFloating: true,
  backgroundColor: Color(0xFF00BCD4),
  iconColor: Colors.white,
  size: 48,
),
```

## Screens Updated

The following screens have been updated to include the home return arrow:

1. **Create Post Screen** - Uses HomeReturnAppBar
2. **Communities Screen** - Uses HomeReturnAppBar with TabBar
3. **Profile Screen** - Uses HomeReturnAppBar for all sub-screens
4. **Search Screen** - Uses HomeReturnAppBar with search field
5. **Chat List Screen** - Uses HomeReturnAppBar
6. **Chat Screen** - Uses HomeReturnAppBar
7. **User Search Screen** - Uses HomeReturnAppBar
8. **Post Detail Screen** - Uses HomeReturnAppBar + floating HomeReturnArrow

## Benefits

- **Consistent Navigation**: Users can always return to home from any screen
- **Improved UX**: No need to navigate back through multiple screens
- **Accessibility**: Clear and visible home button
- **Customizable**: Adapts to your app's design system
- **Stack Management**: Automatically clears navigation stack when returning home 