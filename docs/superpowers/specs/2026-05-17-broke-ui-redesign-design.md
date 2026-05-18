# BROKE App — UI Redesign + Penguin/Dragon Theme

**Date:** 2026-05-17  
**Scope:** UI-only redesign. Zero functional changes. All existing features preserved.

---

## 1. Goals

- Apply the color palette from `Broke Redesign - standalone.html` to the SwiftUI app
- Add switchable **Penguin** / **Dragon** character theme
- Add **Light / Dark / System** appearance mode per theme
- Keep all SF Symbols (`Image(systemName:)`) — no emoji in UI
- Default: Penguin theme, Light appearance

---

## 2. Color Tokens (from HTML file)

All hex values extracted directly from `Broke Redesign - standalone.html`.

### Penguin Theme
| Token | Light | Dark |
|-------|-------|------|
| `background` | `#F0F7FF` | `#0A1628` |
| `cardBackground` | `#DDEEFF` | `#0D2847` |
| `primary` | `#3D9BF0` | `#3D9BF0` |
| `accent` | `#FFA94D` | `#FFA94D` |
| `textPrimary` | `#1A1410` | `#FFFCF1` |
| `textSecondary` | `#1A1410` at 50% | `#FFFCF1` at 50% |
| `income` | `#1A8A50` | `#40C8A0` |
| `expense` | `#D93030` | `#FF6B8A` |
| `separator` | `#3D9BF0` at 12% | `#3D9BF0` at 10% |

### Dragon Theme
| Token | Light | Dark |
|-------|-------|------|
| `background` | `#FFF6EC` | `#1C0E08` |
| `cardBackground` | `#F0EEE9` | `#2D1206` |
| `primary` | `#F5BC1A` | `#F5BC1A` |
| `accent` | `#FF8A3D` | `#FF8A3D` |
| `textPrimary` | `#2A1F08` | `#FFFCF1` |
| `textSecondary` | `#2A1F08` at 50% | `#FFFCF1` at 50% |
| `income` | `#1A8A50` | `#40C8A0` |
| `expense` | `#CC3300` | `#FF6B8A` |
| `separator` | `#2A1F08` at 8% | `#FFFCF1` at 8% |

---

## 3. Architecture

### 3.1 New file: `BROKE/Utils/AppTheme.swift`

Contains:

```
enum ThemeCharacter: String, CaseIterable  { case penguin, dragon }
enum AppearanceMode: String, CaseIterable  { case light, dark, system }

class ThemeManager: ObservableObject {
    @AppStorage("themeCharacter") var character: ThemeCharacter = .penguin
    @AppStorage("appearanceMode") var appearance: AppearanceMode = .light

    // Computed color properties (returns Color values from above table)
    var background: Color
    var cardBackground: Color
    var primary: Color
    var accent: Color
    var textPrimary: Color
    var textSecondary: Color
    var income: Color
    var expense: Color
    var separator: Color

    // Resolved ColorScheme for preferredColorScheme modifier
    var colorScheme: ColorScheme?   // nil = system
}
```

Colors are expressed as `Color(hex:)` using a simple `Color` hex initializer extension (added to `Utils`).

### 3.2 App entry point: `BROKEApp.swift`

- Add `@StateObject var themeManager = ThemeManager()`
- Inject as `.environmentObject(themeManager)` alongside existing ones
- Apply `.preferredColorScheme(themeManager.colorScheme)` on `ContentView`

### 3.3 Views — consume theme

All views add `@EnvironmentObject var theme: ThemeManager` and replace hardcoded colors with theme tokens:

| Hardcoded value | Replace with |
|-----------------|--------------|
| `Color(UIColor.systemGroupedBackground)` | `theme.background` |
| `Color(UIColor.secondarySystemGroupedBackground)` | `theme.cardBackground` |
| `.green` (income) | `theme.income` |
| `.red` (expense) | `theme.expense` |
| `.blue` (buttons, nav, primary actions) | `theme.primary` |
| `.primary` / `.secondary` text | `theme.textPrimary` / `theme.textSecondary` |

SF Symbols and their colors (category icons) stay exactly as-is — they already use per-category `Color` values defined in the model, which are unchanged.

### 3.4 Settings: `SettingsView.swift`

Add new **Appearance** section at the top of the Form:

```
Section("Appearance") {
    Picker("Theme", selection: $theme.character) {
        Label("Penguin", systemImage: "snowflake")   .tag(ThemeCharacter.penguin)
        Label("Dragon",  systemImage: "flame")        .tag(ThemeCharacter.dragon)
    }
    Picker("Mode", selection: $theme.appearance) {
        Label("Light",  systemImage: "sun.max")       .tag(AppearanceMode.light)
        Label("Dark",   systemImage: "moon")          .tag(AppearanceMode.dark)
        Label("System", systemImage: "circle.lefthalf.filled") .tag(AppearanceMode.system)
    }
}
```

Uses SF Symbols only. No emoji in picker labels.

---

## 4. Files Changed

| File | Change |
|------|--------|
| `BROKE/Utils/AppTheme.swift` | **New** — ThemeManager + color tokens |
| `BROKE/Utils/Color+Hex.swift` | **New** — `Color(hex:)` initializer |
| `BROKE/BROKEApp.swift` | Inject ThemeManager, apply colorScheme |
| `BROKE/ContentView.swift` | Pass theme env object; restyle tab bar tint |
| `BROKE/Views/HomeView.swift` | Apply theme colors throughout |
| `BROKE/Views/TransactionRow.swift` | Apply theme colors |
| `BROKE/Views/TransactionListView.swift` | Apply theme colors |
| `BROKE/Views/AddTransactionView.swift` | Apply theme colors |
| `BROKE/Views/AnalyticsView.swift` | Apply theme colors |
| `BROKE/Views/SettingsView.swift` | Add Appearance section at top |

---

## 5. What Does NOT Change

- All business logic, ViewModels, Models, Services — untouched
- SF Symbol names for category icons — untouched
- Category colors defined in `ExpenseCategory` / `IncomeCategory` — untouched
- Slip scanning, photo access, CSV import/export — untouched
- Navigation structure (TabView with Home / Analytics / Settings) — untouched
- All existing `@EnvironmentObject` wiring — extended, not replaced

---

## 6. Persistence

`ThemeManager` uses `@AppStorage` so theme selection persists across app launches automatically. No separate persistence layer needed.

---

## 7. Constraints

- iOS 16+ (already required by existing codebase)
- No third-party dependencies added
- No new SF Symbol names beyond the 3 added in the Settings picker
