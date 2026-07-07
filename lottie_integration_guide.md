# KAAND — Lottie Animation Integration Guide

This guide details how to add, manage, and render animations in the **KAAND** news application.

---

## 1. Supported Animation Formats

KAAND supports two formats under a single unified API wrapper:
1. **`.lottie` (Preferred)**: Highly optimized, zip-compressed animations that bundle resources and significantly reduce the final app size.
2. **`.json`**: Standard text-based Lottie files.

---

## 2. File Placement & Structure

Store all animations inside the `assets/animations/` directory.

```text
assets/
└── animations/
    ├── logo_intro.lottie          # Splash animation (DotLottie format)
    ├── loading.json               # Generic loading loop
    ├── ambient_glow.json          # Glow ambient overlay
    └── success.json               # Checkmark trigger
```

---

## 3. Register Assets in pubspec.yaml

To make assets accessible at runtime, verify they are declared under the `flutter` section in [pubspec.yaml](file:///d:/application/pubspec.yaml):

```yaml
flutter:
  assets:
    - assets/animations/
    - assets/logo/
```
*Note: Folder declarations (ending in `/`) automatically bundle all files residing directly inside that folder.*

---

## 4. Unified Rendering API

Always use the **`KaandLottie`** widget to render animations. It automatically delegates loading to the correct player based on the file extension and guarantees robust fallback rendering if an asset fails to load.

### Import
```dart
import 'package:application/shared/widgets/kaand_lottie.dart';
```

### Rendering a compressed .lottie asset:
```dart
const KaandLottie(
  assetPath: 'assets/animations/logo_intro.lottie',
  width: 200,
  height: 200,
  loop: false,
)
```

### Rendering a standard .json Lottie asset:
```dart
const KaandLottie(
  assetPath: 'assets/animations/loading.json',
  loop: true,
)
```

---

## 5. Resiliency & Error Fallbacks

If an animation file is corrupt, missing, or fails to resolve at runtime, the `KaandLottie` widget catches the failure and renders a custom-painted canvas loading indicator (`LoadingIndicator`). This prevents screen blackouts or application crashes.

No manual try-catch wrappers or asset existence checks are required in screen widgets.
