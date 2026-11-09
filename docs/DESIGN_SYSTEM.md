# Medify Design System

Elderly-friendly dual chrome: **iOS Liquid Glass** (native via `adaptive_platform_ui`) and **Android Material You tint**. Brand teal + Nunito.

## Chrome vs content

| Layer | iOS 26+ | iOS &lt;26 | Android |
| --- | --- | --- | --- |
| App bar / tab bar | Native Liquid Glass (`useNativeToolbar` / `useNativeBottomBar`) | Cupertino bars | Tinted Material `AppBar` / `NavigationBar` |
| Page body | Opaque grouped background | same | same |
| Cards / sheets | Opaque surface + hairline border | same | same |

**Rule:** glass/blur belongs only on chrome (bars, sheets). Content cards stay solid for contrast and readability.

## Tokens

- `lib/core/design/tokens/` — primitives, color, chrome, space, radius, type, motion
- `MedifyTokens` ThemeExtension — prefer `MedifyTokens.of(context)`
- Legacy `AppColors` / `AppSizes` delegate to tokens

Brand: teal (`#0891B2` light / `#22D3EE` dark). Min tap **44pt**. Body **17+**.

## Adaptive wiring

- Root: `AdaptiveApp` (`lib/app/my_app.dart`) with Material + Cupertino themes
- Shell: `AdaptiveScaffold` + `AdaptiveBottomNavigationBar(useNativeBottomBar: true)`
- Pages: `AdaptiveScaffold` + `AdaptiveAppBar(useNativeToolbar: true)`
- Helpers: `lib/core/design/adaptive.dart` (`MedifyAdaptive`)
- iOS CupertinoApp gets Material `Theme` + `ScaffoldMessenger` via `AdaptiveApp.builder` so tokens and snackbars work

## A11y

- Prefer system Reduce Transparency / Reduce Motion: native chrome handles blur fallbacks
- Status colors never sole meaning (icon + label)
- Large primary CTAs (`buttonHeight` 56)

## Do / don't

- Do: opaque cards, native glass bars, SF Symbols on iOS 26+
- Don't: BackdropFilter on content cards; pure black backgrounds; glass fill on list rows
