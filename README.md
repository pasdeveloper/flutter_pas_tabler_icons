# flutter_pas_tabler_icons

A Flutter package for [Tabler Icons](https://tabler.io/icons) — **always up to date**, automatically.

[![Tabler Icons](https://img.shields.io/badge/Tabler%20Icons-3.40.0-blue)](https://tabler-icons.io/)
[![pub package](https://img.shields.io/pub/v/flutter_pas_tabler_icons.svg)](https://pub.dev/packages/flutter_pas_tabler_icons)

Unlike other Tabler icon packages for Flutter, **this library updates itself automatically** via a CI pipeline that checks for new Tabler releases weekly. No waiting for a maintainer to manually publish — when Tabler ships new icons, this package follows within days.

Currently tracking **Tabler Icons v3.40.0** with **6131** icons, including both **Outline** and **Filled** variants. All icons are `static const`, making them fully tree-shakeable.

## Getting Started

Add the package to your project:

```bash
flutter pub add flutter_pas_tabler_icons
```

Or manually in your `pubspec.yaml`:

```yaml
dependencies:
  flutter_pas_tabler_icons: ^3.40.0
```

Then run:

```bash
flutter pub get
```

## Usage

Import the package:

```dart
import 'package:flutter_pas_tabler_icons/flutter_pas_tabler_icons.dart';
```

Use the icons in your widgets:

```dart
// Outline icon
Icon(TablerIcons.heart)

// Filled icon
Icon(TablerIcons.heart_filled)

// Customizing
Icon(
  TablerIcons.brand_github,
  color: Colors.black,
  size: 32.0,
)
```

## Icon Naming

Icon names are converted from Tabler's kebab-case to snake_case.

- `activity` -> `TablerIcons.activity`
- `brand-github` -> `TablerIcons.brand_github`
- `123` -> `TablerIcons.icon_123` (Prefixed with `icon_` if it starts with a digit)
- `filled` variant -> `TablerIcons.heart_filled` (Suffixed with `_filled`)

## Additional Information

For a full list of icons, visit [tabler.io/icons](https://tabler.io/icons).
