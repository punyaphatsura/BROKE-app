# BROKE Full UI Redesign — Penguin/Dragon Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild every screen in the BROKE app to match the Penguin/Dragon design directions from the HTML redesign prototype — custom floating tab bar, mascot SVG, balance card with brand background, new transaction rows with icon tiles, hero amount input, SVG-style donut analytics, and mascot switcher in Settings.

**Architecture:** All views are rebuilt from scratch in the `feat/full-ui-redesign` worktree. `ThemeManager` gains a richer token set. Shared UI primitives (mascot, tab bar, balance card) are isolated in `BROKE/Views/Components/`. `ContentView` drops `TabView` in favour of a manual `ZStack` + `FloatingTabBar`. All existing business logic, ViewModels, Models, and Services are untouched.

**Tech Stack:** SwiftUI, Swift Charts (donut), `Canvas` / `Path` for mascot SVG, `@EnvironmentObject` for theme propagation, `@AppStorage` for persistence, SF Symbols for all icons.

**Worktree:** `/Users/jackkahod/Desktop/File/Project/Meow-Jod-Clone-App/.worktrees/feat/full-ui-redesign`

---

## File Map

| Action | File | Responsibility |
|--------|------|----------------|
| Modify | `BROKE/Utils/AppTheme.swift` | Richer token set matching design spec |
| Create | `BROKE/Views/Components/MascotView.swift` | Penguin + Dragon SVG drawn with SwiftUI ZStack/Shapes |
| Create | `BROKE/Views/Components/FloatingTabBar.swift` | Floating pill tab bar |
| Modify | `BROKE/ContentView.swift` | Drop TabView, use FloatingTabBar + ZStack |
| Create | `BROKE/Views/Components/BalanceCard.swift` | Brand-colored balance card with in/out row |
| Create | `BROKE/Views/Components/SlipBanner.swift` | Mascot speech bubble slip-review nudge |
| Modify | `BROKE/Views/HomeView.swift` | Full rebuild: custom header, balance card, slip banner, list |
| Modify | `BROKE/Views/TransactionRow.swift` | Icon tile, bank pill, compact layout |
| Modify | `BROKE/Views/TransactionListView.swift` | Grouped rounded cards, new section header |
| Modify | `BROKE/Views/AddTransactionView.swift` | Hero 92pt amount, 4-column category grid |
| Modify | `BROKE/Views/AnalyticsView.swift` | SVG donut, segmented control, category progress bars |
| Modify | `BROKE/Views/SettingsView.swift` | Hero card, mascot switcher, themed sections |

**Build command (use for every task):**
```bash
xcodebuild build \
  -project /Users/jackkahod/Desktop/File/Project/Meow-Jod-Clone-App/.worktrees/feat/full-ui-redesign/BROKE.xcodeproj \
  -scheme BROKE \
  -destination 'platform=iOS Simulator,name=iPhone 16e' \
  CODE_SIGNING_ALLOWED=NO 2>&1 | tail -3
```
Expected: `** BUILD SUCCEEDED **`

---

## Task 1: Update ThemeManager token set

**Files:**
- Modify: `BROKE/Utils/AppTheme.swift`

The existing ThemeManager has 9 tokens. Replace with the full 14-token palette from the design spec. Keep old names as computed aliases so any leftover references still compile.

- [ ] **Step 1: Replace AppTheme.swift**

Replace the entire file with:

```swift
//
//  AppTheme.swift
//  BROKE
//

import SwiftUI

enum ThemeCharacter: String, CaseIterable {
    case penguin, dragon
}

enum AppearanceMode: String, CaseIterable {
    case light, dark, system
}

class ThemeManager: ObservableObject {
    @AppStorage("themeCharacter") var character: ThemeCharacter = .penguin {
        willSet { objectWillChange.send() }
    }
    @AppStorage("appearanceMode") var appearance: AppearanceMode = .light {
        willSet { objectWillChange.send() }
    }

    var preferredColorScheme: ColorScheme? {
        switch appearance {
        case .light:  return .light
        case .dark:   return .dark
        case .system: return nil
        }
    }

    // MARK: - Design-spec tokens

    /// Page background
    var bg: Color          { resolve(.bg) }
    /// Card / sheet background
    var surface: Color     { resolve(.surface) }
    /// Elevated card background
    var raised: Color      { resolve(.raised) }
    /// Primary text
    var ink: Color         { resolve(.ink) }
    /// Secondary body text
    var bodyText: Color    { resolve(.bodyText) }
    /// Tertiary / muted text + icons
    var muted: Color       { resolve(.muted) }
    /// Divider colour
    var rule: Color        { resolve(.rule) }
    /// Brand accent (sky-blue / golden-yellow)
    var brand: Color       { resolve(.brand) }
    /// Text on brand background
    var brandInk: Color    { resolve(.brandInk) }
    /// Brand-tinted background
    var softBrand: Color   { resolve(.softBrand) }
    /// Chip / pill background
    var chipBg: Color      { resolve(.chipBg) }
    /// Positive amounts
    var income: Color      { resolve(.income) }
    /// Negative amounts
    var expense: Color     { resolve(.expense) }

    // MARK: - Backward-compat aliases (used by existing views still in transition)
    var background: Color    { bg }
    var cardBackground: Color { surface }
    var primary: Color       { brand }
    var accent: Color        { resolve(.accent) }
    var textPrimary: Color   { ink }
    var textSecondary: Color { ink.opacity(0.5) }
    var separator: Color     { rule }

    // MARK: - Private

    private enum Token {
        case bg, surface, raised, ink, bodyText, muted, rule
        case brand, brandInk, softBrand, chipBg, income, expense, accent
    }

    private func resolve(_ token: Token) -> Color {
        switch appearance {
        case .light:
            return lightColor(token, for: character)
        case .dark:
            return darkColor(token, for: character)
        case .system:
            return Color(uiColor: UIColor { [self] traits in
                UIColor(traits.userInterfaceStyle == .dark
                    ? self.darkColor(token, for: self.character)
                    : self.lightColor(token, for: self.character))
            })
        }
    }

    private func lightColor(_ token: Token, for character: ThemeCharacter) -> Color {
        switch (character, token) {
        // ── Penguin light ──────────────────────────────────────
        case (.penguin, .bg):        return Color(hex: "EFF6FE")
        case (.penguin, .surface):   return Color(hex: "FFFFFF")
        case (.penguin, .raised):    return Color(hex: "FFFFFF")
        case (.penguin, .ink):       return Color(hex: "0E1A2C")
        case (.penguin, .bodyText):  return Color(hex: "2C3B52")
        case (.penguin, .muted):     return Color(hex: "7A8BA0")
        case (.penguin, .rule):      return Color(hex: "0E1A2C").opacity(0.08)
        case (.penguin, .brand):     return Color(hex: "3D9BF0")
        case (.penguin, .brandInk):  return Color(hex: "FFFFFF")
        case (.penguin, .softBrand): return Color(hex: "D5EAFF")
        case (.penguin, .chipBg):    return Color(hex: "3D9BF0").opacity(0.12)
        case (.penguin, .income):    return Color(hex: "2FA66B")
        case (.penguin, .expense):   return Color(hex: "E64C5C")
        case (.penguin, .accent):    return Color(hex: "3D8AE0")
        // ── Dragon light ───────────────────────────────────────
        case (.dragon, .bg):         return Color(hex: "FFFAEC")
        case (.dragon, .surface):    return Color(hex: "FFFFFF")
        case (.dragon, .raised):     return Color(hex: "FFFFFF")
        case (.dragon, .ink):        return Color(hex: "2A1F08")
        case (.dragon, .bodyText):   return Color(hex: "3D331C")
        case (.dragon, .muted):      return Color(hex: "9A8B6A")
        case (.dragon, .rule):       return Color(hex: "2A1F08").opacity(0.08)
        case (.dragon, .brand):      return Color(hex: "F5BC1A")
        case (.dragon, .brandInk):   return Color(hex: "2A1F08")
        case (.dragon, .softBrand):  return Color(hex: "FFF1B8")
        case (.dragon, .chipBg):     return Color(hex: "F5BC1A").opacity(0.14)
        case (.dragon, .income):     return Color(hex: "2FA66B")
        case (.dragon, .expense):    return Color(hex: "E64C5C")
        case (.dragon, .accent):     return Color(hex: "3D8AE0")
        }
    }

    private func darkColor(_ token: Token, for character: ThemeCharacter) -> Color {
        switch (character, token) {
        // ── Penguin dark ───────────────────────────────────────
        case (.penguin, .bg):        return Color(hex: "0E141B")
        case (.penguin, .surface):   return Color(hex: "162130")
        case (.penguin, .raised):    return Color(hex: "1E2B3D")
        case (.penguin, .ink):       return Color(hex: "EAF4FF")
        case (.penguin, .bodyText):  return Color(hex: "C7D8EA")
        case (.penguin, .muted):     return Color(hex: "7A8BA0")
        case (.penguin, .rule):      return Color(hex: "EAF4FF").opacity(0.10)
        case (.penguin, .brand):     return Color(hex: "7DC6FF")
        case (.penguin, .brandInk):  return Color(hex: "0A1626")
        case (.penguin, .softBrand): return Color(hex: "1B2C42")
        case (.penguin, .chipBg):    return Color(hex: "7DC6FF").opacity(0.14)
        case (.penguin, .income):    return Color(hex: "80E2A9")
        case (.penguin, .expense):   return Color(hex: "FF8290")
        case (.penguin, .accent):    return Color(hex: "A5D8FF")
        // ── Dragon dark ────────────────────────────────────────
        case (.dragon, .bg):         return Color(hex: "181308")
        case (.dragon, .surface):    return Color(hex: "241D10")
        case (.dragon, .raised):     return Color(hex: "2F2614")
        case (.dragon, .ink):        return Color(hex: "FFF6DA")
        case (.dragon, .bodyText):   return Color(hex: "E8DCB8")
        case (.dragon, .muted):      return Color(hex: "A89880")
        case (.dragon, .rule):       return Color(hex: "FFF6DA").opacity(0.10)
        case (.dragon, .brand):      return Color(hex: "FFD75E")
        case (.dragon, .brandInk):   return Color(hex: "2A1F08")
        case (.dragon, .softBrand):  return Color(hex: "3A2D14")
        case (.dragon, .chipBg):     return Color(hex: "FFD75E").opacity(0.14)
        case (.dragon, .income):     return Color(hex: "9FE08C")
        case (.dragon, .expense):    return Color(hex: "FF8C7A")
        case (.dragon, .accent):     return Color(hex: "7DC6FF")
        }
    }
}
```

- [ ] **Step 2: Build to verify**

Run the build command. Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git -C /Users/jackkahod/Desktop/File/Project/Meow-Jod-Clone-App/.worktrees/feat/full-ui-redesign \
  add BROKE/Utils/AppTheme.swift && \
git -C /Users/jackkahod/Desktop/File/Project/Meow-Jod-Clone-App/.worktrees/feat/full-ui-redesign \
  commit -m "feat: expand ThemeManager with full design-spec token set"
```

---

## Task 2: Create MascotView

**Files:**
- Create: `BROKE/Views/Components/MascotView.swift`

The mascot is drawn with SwiftUI ZStack + Shapes. All positions are in a 64×64 coordinate space, scaled to `size` via a helper. Wings rotate around their own centre (apply `.rotationEffect` before `.offset`).

- [ ] **Step 1: Create the Components directory and MascotView.swift**

```bash
mkdir -p /Users/jackkahod/Desktop/File/Project/Meow-Jod-Clone-App/.worktrees/feat/full-ui-redesign/BROKE/Views/Components
```

Create `BROKE/Views/Components/MascotView.swift`:

```swift
//
//  MascotView.swift
//  BROKE
//

import SwiftUI

enum MascotMood { case happy, sleepy, normal }

struct MascotView: View {
    let size: CGFloat
    var mood: MascotMood = .happy
    @EnvironmentObject var theme: ThemeManager

    // Scale from 64×64 design space to actual size
    private func s(_ v: CGFloat) -> CGFloat { v * size / 64 }

    var body: some View {
        ZStack {
            if theme.character == .penguin {
                penguinView
            } else {
                dragonView
            }
        }
        .frame(width: size, height: size)
    }

    // MARK: - Penguin

    private var penguinView: some View {
        ZStack {
            // Left wing — rotate around its own centre, then offset
            Ellipse()
                .fill(theme.brand)
                .frame(width: s(10), height: s(22))
                .rotationEffect(.degrees(-12))
                .offset(x: s(11 - 32), y: s(40 - 32))

            // Right wing
            Ellipse()
                .fill(theme.brand)
                .frame(width: s(10), height: s(22))
                .rotationEffect(.degrees(12))
                .offset(x: s(53 - 32), y: s(40 - 32))

            // Body (egg)
            Ellipse()
                .fill(theme.brand)
                .frame(width: s(40), height: s(44))
                .offset(x: 0, y: s(34 - 32))

            // White belly
            Ellipse()
                .fill(Color.white)
                .frame(width: s(24), height: s(32))
                .offset(x: 0, y: s(38 - 32))

            // Eyes
            penguinEyes

            // Beak (downward triangle)
            TriangleDown()
                .fill(Color(hex: "FF9A3C"))
                .frame(width: s(8), height: s(5))
                .offset(x: 0, y: s(35 - 32))

            // Left foot
            Ellipse()
                .fill(Color(hex: "FF9A3C"))
                .frame(width: s(9), height: s(5))
                .offset(x: s(26 - 32), y: s(55 - 32))

            // Right foot
            Ellipse()
                .fill(Color(hex: "FF9A3C"))
                .frame(width: s(9), height: s(5))
                .offset(x: s(38 - 32), y: s(55 - 32))
        }
    }

    @ViewBuilder
    private var penguinEyes: some View {
        switch mood {
        case .normal:
            // Filled circles
            Circle()
                .fill(theme.ink)
                .frame(width: s(3.8), height: s(3.8))
                .offset(x: s(25.5 - 32), y: s(29 - 32))
            Circle()
                .fill(theme.ink)
                .frame(width: s(3.8), height: s(3.8))
                .offset(x: s(38.5 - 32), y: s(29 - 32))

        case .happy, .sleepy:
            // Arc eyes (happy crescent)
            PenguinEyeArc(leftEye: true, sleepy: mood == .sleepy)
                .stroke(theme.ink, style: StrokeStyle(lineWidth: s(2.2), lineCap: .round))
                .frame(width: s(64), height: s(64))
            PenguinEyeArc(leftEye: false, sleepy: mood == .sleepy)
                .stroke(theme.ink, style: StrokeStyle(lineWidth: s(2.2), lineCap: .round))
                .frame(width: s(64), height: s(64))
        }
    }

    // MARK: - Dragon

    private var dragonView: some View {
        ZStack {
            // Left horn
            DragonHorn(left: true)
                .fill(Color(hex: "F0A53A"))
                .frame(width: s(64), height: s(64))

            // Right horn
            DragonHorn(left: false)
                .fill(Color(hex: "F0A53A"))
                .frame(width: s(64), height: s(64))

            // Back spine
            DragonSpine()
                .fill(Color(hex: "F0A53A").opacity(0.7))
                .frame(width: s(64), height: s(64))

            // Head (round)
            Ellipse()
                .fill(theme.brand)
                .frame(width: s(44), height: s(40))
                .offset(x: 0, y: s(36 - 32))

            // Snout patch
            Ellipse()
                .fill(Color.black.opacity(0.06))
                .frame(width: s(22), height: s(14))
                .offset(x: 0, y: s(42 - 32))

            // Cheeks
            Circle()
                .fill(Color(hex: "F0A53A").opacity(0.5))
                .frame(width: s(4.8), height: s(4.8))
                .offset(x: s(17 - 32), y: s(40 - 32))
            Circle()
                .fill(Color(hex: "F0A53A").opacity(0.5))
                .frame(width: s(4.8), height: s(4.8))
                .offset(x: s(47 - 32), y: s(40 - 32))

            // Eyes
            dragonEyes

            // Nostrils
            Circle()
                .fill(theme.ink)
                .frame(width: s(2.2), height: s(2.2))
                .offset(x: s(29 - 32), y: s(40 - 32))
            Circle()
                .fill(theme.ink)
                .frame(width: s(2.2), height: s(2.2))
                .offset(x: s(35 - 32), y: s(40 - 32))
        }
    }

    @ViewBuilder
    private var dragonEyes: some View {
        switch mood {
        case .normal:
            Circle()
                .fill(theme.ink)
                .frame(width: s(4.4), height: s(4.4))
                .offset(x: s(23 - 32), y: s(30 - 32))
            Circle()
                .fill(theme.ink)
                .frame(width: s(4.4), height: s(4.4))
                .offset(x: s(41 - 32), y: s(30 - 32))
        case .happy, .sleepy:
            DragonEyeArc(leftEye: true, sleepy: mood == .sleepy)
                .stroke(theme.ink, style: StrokeStyle(lineWidth: s(2.4), lineCap: .round))
                .frame(width: s(64), height: s(64))
            DragonEyeArc(leftEye: false, sleepy: mood == .sleepy)
                .stroke(theme.ink, style: StrokeStyle(lineWidth: s(2.4), lineCap: .round))
                .frame(width: s(64), height: s(64))
        }
    }
}

// MARK: - Supporting Shapes

struct TriangleDown: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: 0))
        p.addLine(to: CGPoint(x: rect.width, y: 0))
        p.addLine(to: CGPoint(x: rect.width / 2, y: rect.height))
        p.closeSubpath()
        return p
    }
}

struct PenguinEyeArc: Shape {
    let leftEye: Bool
    let sleepy: Bool

    func path(in rect: CGRect) -> Path {
        let s = rect.width / 64
        var p = Path()
        if sleepy {
            // Horizontal line: left eye M23,29 l5,0 / right eye M36,29 l5,0
            let x: CGFloat = leftEye ? 23 : 36
            p.move(to: CGPoint(x: x * s, y: 29 * s))
            p.addLine(to: CGPoint(x: (x + 5) * s, y: 29 * s))
        } else {
            // Happy arc: left M23,28 q2.5,-2 5,0 / right M36,28 q2.5,-2 5,0
            let x: CGFloat = leftEye ? 23 : 36
            p.move(to: CGPoint(x: x * s, y: 28 * s))
            p.addQuadCurve(
                to: CGPoint(x: (x + 5) * s, y: 28 * s),
                control: CGPoint(x: (x + 2.5) * s, y: 26 * s)
            )
        }
        return p
    }
}

struct DragonEyeArc: Shape {
    let leftEye: Bool
    let sleepy: Bool

    func path(in rect: CGRect) -> Path {
        let s = rect.width / 64
        var p = Path()
        if sleepy {
            let x: CGFloat = leftEye ? 19 : 37
            p.move(to: CGPoint(x: x * s, y: 30 * s))
            p.addLine(to: CGPoint(x: (x + 8) * s, y: 30 * s))
        } else {
            let x: CGFloat = leftEye ? 19 : 37
            p.move(to: CGPoint(x: x * s, y: 30 * s))
            p.addQuadCurve(
                to: CGPoint(x: (x + 8) * s, y: 30 * s),
                control: CGPoint(x: (x + 4) * s, y: 26 * s)
            )
        }
        return p
    }
}

struct DragonHorn: Shape {
    let left: Bool

    func path(in rect: CGRect) -> Path {
        let s = rect.width / 64
        var p = Path()
        if left {
            p.move(to: CGPoint(x: 19 * s, y: 22 * s))
            p.addLine(to: CGPoint(x: 21 * s, y: 9 * s))
            p.addLine(to: CGPoint(x: 26 * s, y: 21 * s))
        } else {
            p.move(to: CGPoint(x: 45 * s, y: 22 * s))
            p.addLine(to: CGPoint(x: 43 * s, y: 9 * s))
            p.addLine(to: CGPoint(x: 38 * s, y: 21 * s))
        }
        p.closeSubpath()
        return p
    }
}

struct DragonSpine: Shape {
    func path(in rect: CGRect) -> Path {
        let s = rect.width / 64
        var p = Path()
        p.move(to: CGPoint(x: 32 * s, y: 12 * s))
        p.addLine(to: CGPoint(x: 34 * s, y: 6 * s))
        p.addLine(to: CGPoint(x: 36 * s, y: 12 * s))
        p.closeSubpath()
        return p
    }
}
```

- [ ] **Step 2: Build to verify**

Run the build command. Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git -C /Users/jackkahod/Desktop/File/Project/Meow-Jod-Clone-App/.worktrees/feat/full-ui-redesign \
  add BROKE/Views/Components/MascotView.swift && \
git -C /Users/jackkahod/Desktop/File/Project/Meow-Jod-Clone-App/.worktrees/feat/full-ui-redesign \
  commit -m "feat: add MascotView (penguin/dragon SVG in SwiftUI)"
```

---

## Task 3: Create FloatingTabBar + update ContentView

**Files:**
- Create: `BROKE/Views/Components/FloatingTabBar.swift`
- Modify: `BROKE/ContentView.swift`

The tab bar is a floating pill at the bottom of the screen. `ContentView` drops `TabView` entirely and manages tab selection manually.

- [ ] **Step 1: Create FloatingTabBar.swift**

Create `BROKE/Views/Components/FloatingTabBar.swift`:

```swift
//
//  FloatingTabBar.swift
//  BROKE
//

import SwiftUI

enum AppTab: CaseIterable {
    case home, analytics, settings

    var label: String {
        switch self {
        case .home:      return "Home"
        case .analytics: return "Insights"
        case .settings:  return "Me"
        }
    }

    var icon: String {
        switch self {
        case .home:      return "house"
        case .analytics: return "chart.line.uptrend.xyaxis"
        case .settings:  return "person"
        }
    }
}

struct FloatingTabBar: View {
    @Binding var selectedTab: AppTab
    @EnvironmentObject var theme: ThemeManager

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                tabItem(tab)
            }
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(theme.surface)
                .shadow(color: Color.black.opacity(0.10), radius: 15, x: 0, y: 5)
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(Color.black.opacity(0.04), lineWidth: 0.5)
                )
        )
        .padding(.horizontal, 12)
        .padding(.bottom, 14)
    }

    private func tabItem(_ tab: AppTab) -> some View {
        let isActive = selectedTab == tab
        return Button(action: { selectedTab = tab }) {
            VStack(spacing: 2) {
                Image(systemName: tab.icon)
                    .font(.system(size: 18, weight: .medium))
                Text(tab.label)
                    .font(.system(size: 10, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(isActive ? theme.brand : Color.clear)
            )
            .foregroundColor(isActive ? theme.brandInk : theme.muted)
        }
        .buttonStyle(.plain)
    }
}
```

- [ ] **Step 2: Replace ContentView.swift**

```swift
//
//  ContentView.swift
//  BROKE
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab: AppTab = .home
    @EnvironmentObject var theme: ThemeManager

    var body: some View {
        ZStack(alignment: .bottom) {
            // Selected screen
            Group {
                switch selectedTab {
                case .home:
                    HomeView()
                case .analytics:
                    NavigationStack { AnalyticsView() }
                case .settings:
                    NavigationStack { SettingsView() }
                }
            }
            // Reserve space so content clears the tab bar
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 88)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Floating tab bar
            FloatingTabBar(selectedTab: $selectedTab)
                .ignoresSafeArea(.keyboard)
        }
        .background(theme.bg.ignoresSafeArea())
        .preferredColorScheme(theme.preferredColorScheme)
        .ignoresSafeArea(.keyboard)
    }
}

#Preview {
    ContentView()
        .environmentObject(TransactionStore())
        .environmentObject(PhotoService())
        .environmentObject(ThemeManager())
}
```

- [ ] **Step 3: Build to verify**

Run the build command. Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git -C /Users/jackkahod/Desktop/File/Project/Meow-Jod-Clone-App/.worktrees/feat/full-ui-redesign \
  add BROKE/Views/Components/FloatingTabBar.swift BROKE/ContentView.swift && \
git -C /Users/jackkahod/Desktop/File/Project/Meow-Jod-Clone-App/.worktrees/feat/full-ui-redesign \
  commit -m "feat: add FloatingTabBar and rewire ContentView to custom tab management"
```

---

## Task 4: Create BalanceCard + SlipBanner components

**Files:**
- Create: `BROKE/Views/Components/BalanceCard.swift`
- Create: `BROKE/Views/Components/SlipBanner.swift`

- [ ] **Step 1: Create BalanceCard.swift**

Create `BROKE/Views/Components/BalanceCard.swift`:

```swift
//
//  BalanceCard.swift
//  BROKE
//

import SwiftUI

struct BalanceCard: View {
    let netAmount: Double
    let incomeAmount: Double
    let expenseAmount: Double
    @EnvironmentObject var theme: ThemeManager

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Decorative circles
            Circle()
                .fill(Color.white.opacity(0.16))
                .frame(width: 140, height: 140)
                .offset(x: 30, y: -30)

            Circle()
                .fill(Color.white.opacity(0.10))
                .frame(width: 60, height: 60)
                .offset(x: -20, y: 60)

            VStack(alignment: .leading, spacing: 16) {
                Text("NET THIS MONTH")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .tracking(0.4)
                    .foregroundColor(theme.brandInk.opacity(0.9))

                // Big balance number
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("฿")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundColor(theme.brandInk)
                    Text(formattedWhole)
                        .font(.system(size: 52, weight: .semibold, design: .rounded))
                        .foregroundColor(theme.brandInk)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                    if !formattedDecimal.isEmpty {
                        Text("." + formattedDecimal)
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundColor(theme.brandInk.opacity(0.7))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // In / Out row
                HStack(spacing: 8) {
                    inOutPill(label: "IN", amount: incomeAmount, arrow: "↓")
                    inOutPill(label: "OUT", amount: expenseAmount, arrow: "↑")
                }
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 20)
        }
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(theme.brand)
        )
        .clipped()
        .padding(.horizontal, 16)
    }

    private func inOutPill(label: String, amount: Double, arrow: String) -> some View {
        HStack(spacing: 6) {
            Text(arrow)
                .font(.system(size: 12, weight: .semibold))
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .tracking(0.4)
                Text("฿\(Int(amount).formattedWithSeparator)")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
            }
        }
        .foregroundColor(theme.brandInk)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.18))
        )
    }

    private var formattedWhole: String {
        let absVal = abs(netAmount)
        let whole = Int(absVal)
        let prefix = netAmount < 0 ? "-" : ""
        return prefix + NumberFormatter.localizedString(from: NSNumber(value: whole), number: .decimal)
    }

    private var formattedDecimal: String {
        let absVal = abs(netAmount)
        let decimal = absVal - Double(Int(absVal))
        guard decimal > 0 else { return "" }
        return String(format: "%02d", Int(decimal * 100))
    }
}
```

- [ ] **Step 2: Create SlipBanner.swift**

Create `BROKE/Views/Components/SlipBanner.swift`:

```swift
//
//  SlipBanner.swift
//  BROKE
//

import SwiftUI

struct SlipBanner: View {
    let slipCount: Int
    let onReview: () -> Void
    @EnvironmentObject var theme: ThemeManager

    private var speechText: String {
        switch theme.character {
        case .penguin:
            return slipCount == 1
                ? "I caught 1 slip for you! Tap Review to file it."
                : "I caught \(slipCount) slips for you! Tap Review to file them."
        case .dragon:
            return slipCount == 1
                ? "Rawr! I sniffed out 1 slip! Tap Review to file it."
                : "Rawr! I sniffed out \(slipCount) slips! Tap Review."
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Mascot tile
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(theme.softBrand)
                    .frame(width: 44, height: 44)
                MascotView(size: 28)
            }

            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(speechText)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Review button
            Button(action: onReview) {
                Text("Review")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(theme.brandInk)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule().fill(theme.brand)
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(theme.surface)
                .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
        )
        .padding(.horizontal, 16)
    }
}
```

- [ ] **Step 3: Build to verify**

Run the build command. Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git -C /Users/jackkahod/Desktop/File/Project/Meow-Jod-Clone-App/.worktrees/feat/full-ui-redesign \
  add BROKE/Views/Components/BalanceCard.swift \
      BROKE/Views/Components/SlipBanner.swift && \
git -C /Users/jackkahod/Desktop/File/Project/Meow-Jod-Clone-App/.worktrees/feat/full-ui-redesign \
  commit -m "feat: add BalanceCard and SlipBanner components"
```

---

## Task 5: Rebuild HomeView

**Files:**
- Modify: `BROKE/Views/HomeView.swift`

The new HomeView has: custom header with mascot + greeting, BalanceCard, optional SlipBanner, transaction list grouped into rounded-rect cards per date group.

- [ ] **Step 1: Replace HomeView.swift**

Replace the entire file with:

```swift
//
//  HomeView.swift
//  BROKE
//

import Photos
import PhotosUI
import SwiftUI

struct HomeView: View {
    @EnvironmentObject var transactionStore: TransactionStore
    @EnvironmentObject var photoService: PhotoService
    @EnvironmentObject var theme: ThemeManager
    @StateObject private var scannerViewModel = SlipScannerViewModel()
    @StateObject private var viewModel = HomeViewModel()
    @Environment(\.scenePhase) var scenePhase

    @State private var newSlipsCount: Int = 0
    @State private var showingQuotaAlert = false
    @State private var showingAddTransaction = false
    @State private var selectedTransactionForReview: Transaction?

    var unprocessedCount: Int {
        photoService.assets.filter { !ImageHashManager.shared.isProcessed(asset: $0) }.count
    }

    var groupedTransactions: [(key: Date, value: [Transaction])] {
        let grouped = Dictionary(grouping: transactionStore.transactions) { t in
            Calendar.current.startOfDay(for: t.date)
        }
        return grouped.sorted { $0.key > $1.key }
    }

    // Net balance = income - expense
    var netBalance: Double {
        transactionStore.totalIncome() - transactionStore.totalExpense()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // ── Header ───────────────────────────────────
                homeHeader
                    .padding(.top, 56)
                    .padding(.bottom, 18)

                // ── Balance card ─────────────────────────────
                BalanceCard(
                    netAmount: netBalance,
                    incomeAmount: transactionStore.totalIncome(),
                    expenseAmount: transactionStore.totalExpense()
                )
                .padding(.bottom, 14)

                // ── Slip banner ──────────────────────────────
                if unprocessedCount > 0 || !viewModel.recentScannedTransactions.isEmpty {
                    SlipBanner(
                        slipCount: max(unprocessedCount, viewModel.recentScannedTransactions.count),
                        onReview: { triggerBatchScan() }
                    )
                    .padding(.bottom, 14)
                }

                // ── Month navigation ─────────────────────────
                monthNav
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)

                // ── Transaction groups ───────────────────────
                ForEach(groupedTransactions, id: \.key) { section in
                    transactionGroup(date: section.key, transactions: section.value)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 10)
                }

                Spacer(minLength: 20)
            }
        }
        .background(theme.bg.ignoresSafeArea())
        .sheet(isPresented: $showingAddTransaction) {
            AddTransactionView()
        }
        .sheet(item: $selectedTransactionForReview) { transaction in
            AddTransactionView(transactionToEdit: transaction)
        }
        .alert("Limit Exceeded", isPresented: $showingQuotaAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The daily Gemini API quota has been reached. Please try again later.")
        }
        .onReceive(photoService.$isLoadingComplete) { complete in
            if complete { triggerBatchScan() }
        }
        .onReceive(scannerViewModel.$processedSlipData) { slipData in
            if let slipData { saveTransactionFromSlip(slipData) }
        }
        .onReceive(scannerViewModel.$errorMessage) { error in
            if let error, (error.contains("quota") || error.contains("429") || error.contains("RESOURCE_EXHAUSTED")) {
                showingQuotaAlert = true
            }
        }
        .onAppear { updateTransactionsList() }
        .onChange(of: viewModel.currentMonth) { _ in updateTransactionsList() }
        .onChange(of: viewModel.currentYear)  { _ in updateTransactionsList() }
    }

    // MARK: - Header

    private var homeHeader: some View {
        HStack(alignment: .top, spacing: 14) {
            // Mascot tile
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(theme.softBrand)
                    .frame(width: 44, height: 44)
                MascotView(size: 28)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Hi, there.")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundColor(theme.ink)
                Text(viewModel.monthYearString)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(theme.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Add button
            Button(action: { showingAddTransaction = true }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(theme.brand)
                        .frame(width: 44, height: 44)
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(theme.brandInk)
                }
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Month navigation

    private var monthNav: some View {
        HStack {
            Button(action: viewModel.previousMonth) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.muted)
                    .frame(width: 32, height: 32)
            }
            Spacer()
            Text(viewModel.monthYearString)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(theme.ink)
            Spacer()
            Button(action: viewModel.nextMonth) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(viewModel.isCurrentMonthAndYear ? theme.muted.opacity(0.3) : theme.muted)
                    .frame(width: 32, height: 32)
            }
            .disabled(viewModel.isCurrentMonthAndYear)
        }
    }

    // MARK: - Transaction group card

    private func transactionGroup(date: Date, transactions: [Transaction]) -> some View {
        VStack(spacing: 0) {
            // Section header
            HStack {
                Text(date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)))
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(theme.ink)
                Spacer()
                let daily = transactions.filter { $0.type == .expense }.reduce(0.0) { $0 + $1.amount }
                if daily > 0 {
                    Text("-฿\(Int(daily).formattedWithSeparator)")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(theme.muted)
                }
            }
            .padding(.horizontal, 6)
            .padding(.bottom, 8)

            // Rows
            VStack(spacing: 0) {
                ForEach(Array(transactions.sorted(by: { $0.date > $1.date }).enumerated()), id: \.element.id) { idx, transaction in
                    TransactionRow(transaction: transaction)
                        .onTapGesture { selectedTransactionForReview = transaction }
                    if idx < transactions.count - 1 {
                        Divider()
                            .padding(.leading, 68)
                            .overlay(theme.rule)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(theme.surface)
                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
            )
        }
    }

    // MARK: - Actions

    private func updateTransactionsList() {
        transactionStore.transactions = viewModel.getTransactions(from: transactionStore)
    }

    private func saveTransactionFromSlip(_ slipData: SlipData) {
        viewModel.saveTransactionFromSlip(slipData, into: transactionStore) { data in
            scannerViewModel.suggestCategory(for: data)
        }
        let cal = Calendar.current
        let tm = cal.component(.month, from: slipData.parsedDate ?? Date())
        let ty = cal.component(.year, from: slipData.parsedDate ?? Date())
        if tm == viewModel.currentMonth, ty == viewModel.currentYear {
            updateTransactionsList()
        }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    private func triggerBatchScan() {
        if unprocessedCount > 0 {
            newSlipsCount = viewModel.recentScannedTransactions.count + unprocessedCount
        }
        scannerViewModel.processBatch(assets: photoService.assets) { _ in }
    }
}
```

- [ ] **Step 2: Build to verify**

Run the build command. Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git -C /Users/jackkahod/Desktop/File/Project/Meow-Jod-Clone-App/.worktrees/feat/full-ui-redesign \
  add BROKE/Views/HomeView.swift && \
git -C /Users/jackkahod/Desktop/File/Project/Meow-Jod-Clone-App/.worktrees/feat/full-ui-redesign \
  commit -m "feat: rebuild HomeView with mascot header, BalanceCard, SlipBanner, grouped transactions"
```

---

## Task 6: Rebuild TransactionRow

**Files:**
- Modify: `BROKE/Views/TransactionRow.swift`
- Modify: `BROKE/Views/TransactionListView.swift`

The new row: 40×40pt rounded icon tile (category color at 14% opacity bg), category name in display font, description + bank pill below, amount at right with +/- prefix.

- [ ] **Step 1: Replace TransactionRow.swift**

Replace the entire file with:

```swift
//
//  TransactionRow.swift
//  BROKE
//

import SwiftUI

struct TransactionRow: View {
    @EnvironmentObject var transactionStore: TransactionStore
    @EnvironmentObject var theme: ThemeManager
    let transaction: Transaction

    private var categoryColor: Color {
        if let cat = transaction.categoryId { return cat.color }
        if let cat = transaction.incomeCategoryId { return cat.color }
        return theme.muted
    }

    private var categoryIcon: String {
        if let cat = transaction.categoryId { return cat.icon }
        if let cat = transaction.incomeCategoryId { return cat.icon }
        return transaction.type == .transfer ? "arrow.left.arrow.right" : "questionmark"
    }

    private var displayName: String {
        if let cat = transaction.categoryId { return cat.displayName }
        if let cat = transaction.incomeCategoryId { return cat.displayName }
        return transaction.type == .transfer ? "Transfer" : "Unknown"
    }

    private var amountColor: Color {
        switch transaction.type {
        case .income:   return theme.income
        case .expense:  return theme.expense
        case .transfer: return theme.ink
        }
    }

    private var amountPrefix: String {
        switch transaction.type {
        case .income:   return "+"
        case .expense:  return "−"
        case .transfer: return ""
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // ── Category icon tile ─────────────────────────
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(categoryColor.opacity(0.14))
                    .frame(width: 40, height: 40)
                Image(systemName: categoryIcon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(categoryColor)
            }

            // ── Name + meta ────────────────────────────────
            VStack(alignment: .leading, spacing: 3) {
                Text(displayName)
                    .font(.system(size: 14.5, weight: .semibold, design: .rounded))
                    .foregroundColor(theme.ink)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    if !transaction.description.isEmpty {
                        Text(transaction.description)
                            .font(.system(size: 11))
                            .foregroundColor(theme.muted)
                            .lineLimit(1)
                    }
                    if let bank = transaction.bank, bank != .unknown {
                        Text(bank.rawValue)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(theme.ink)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(theme.softBrand))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // ── Amount ─────────────────────────────────────
            Text("\(amountPrefix)฿\(transaction.amount.formattedCurrency)")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(amountColor)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                transactionStore.deleteTransactionById(transaction.id)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
```

- [ ] **Step 2: Replace TransactionListView.swift** (keep logic, update visual chrome)

Replace the entire file with:

```swift
//
//  TransactionListView.swift
//  BROKE
//

import SwiftUI

struct TransactionListView: View {
    @EnvironmentObject var transactionStore: TransactionStore
    @EnvironmentObject var theme: ThemeManager
    @State private var showingAddTransaction = false
    @State private var filterType: TransactionType? = nil
    var customTransactions: [Transaction]?

    var filteredTransactions: [Transaction] {
        if let custom = customTransactions { return custom }
        if let filterType { return transactionStore.transactions.filter { $0.type == filterType } }
        return transactionStore.transactions
    }

    var groupedTransactions: [(key: Date, value: [Transaction])] {
        let grouped = Dictionary(grouping: filteredTransactions) {
            Calendar.current.startOfDay(for: $0.date)
        }
        return grouped.sorted { $0.key > $1.key }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                if customTransactions == nil {
                    filterPicker
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                }

                ForEach(groupedTransactions, id: \.key) { section in
                    sectionCard(date: section.key, transactions: section.value)
                        .padding(.horizontal, 16)
                }
            }
            .padding(.bottom, 20)
        }
        .background(theme.bg.ignoresSafeArea())
        .toolbar {
            if customTransactions == nil {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingAddTransaction = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddTransaction) {
            AddTransactionView()
        }
    }

    private var filterPicker: some View {
        HStack(spacing: 0) {
            filterBtn(title: "All",     tag: nil)
            filterBtn(title: "Income",  tag: .income)
            filterBtn(title: "Expense", tag: .expense)
        }
        .padding(4)
        .background(Capsule().fill(theme.surface))
    }

    private func filterBtn(title: String, tag: TransactionType?) -> some View {
        let active = filterType == tag
        return Button { filterType = tag } label: {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(Capsule().fill(active ? theme.brand : Color.clear))
                .foregroundColor(active ? theme.brandInk : theme.muted)
        }
        .buttonStyle(.plain)
    }

    private func sectionCard(date: Date, transactions: [Transaction]) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)))
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(theme.ink)
                Spacer()
                let total = transactions.filter { $0.type == .expense }.reduce(0.0) { $0 + $1.amount }
                if total > 0 {
                    Text("-฿\(Int(total).formattedWithSeparator)")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(theme.muted)
                }
            }
            .padding(.horizontal, 6)
            .padding(.bottom, 8)

            VStack(spacing: 0) {
                ForEach(Array(transactions.sorted(by: { $0.date > $1.date }).enumerated()), id: \.element.id) { idx, tx in
                    TransactionRow(transaction: tx)
                    if idx < transactions.count - 1 {
                        Divider().padding(.leading, 68)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(theme.surface)
                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
            )
        }
    }

    private func deleteTransactions(at offsets: IndexSet, in transactions: [Transaction]) {
        for t in offsets.map({ transactions[$0] }) {
            if let i = transactionStore.transactions.firstIndex(where: { $0.id == t.id }) {
                transactionStore.transactions.remove(at: i)
            }
        }
        transactionStore.saveTransactions()
    }
}
```

- [ ] **Step 3: Build to verify**

Run the build command. Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git -C /Users/jackkahod/Desktop/File/Project/Meow-Jod-Clone-App/.worktrees/feat/full-ui-redesign \
  add BROKE/Views/TransactionRow.swift BROKE/Views/TransactionListView.swift && \
git -C /Users/jackkahod/Desktop/File/Project/Meow-Jod-Clone-App/.worktrees/feat/full-ui-redesign \
  commit -m "feat: rebuild TransactionRow with icon tile and bank pill; rebuild TransactionListView"
```

---

## Task 7: Rebuild AddTransactionView

**Files:**
- Modify: `BROKE/Views/AddTransactionView.swift`

Key design changes: 92pt hero amount field, 4-column category grid with solid/tinted tiles, pill type picker, compact note field. All existing save/edit/slip logic is preserved exactly.

- [ ] **Step 1: Replace AddTransactionView.swift**

Read the current file carefully first, then replace the `body` and visual subviews while keeping all state properties, `saveTransaction()`, `populateFromTransaction()`, `populateFromSlipData()`, `loadImage()`, `ZoomableScrollView`, and `fullScreenSlipOverlay` unchanged.

Replace only the `body` property and its helper view methods with:

```swift
var body: some View {
    ZStack {
        theme.bg.ignoresSafeArea()

        NavigationView {
            ScrollView {
                VStack(spacing: 20) {

                    // ── Type picker (pill segments) ────────────────────
                    typePicker
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                    // ── Hero amount ────────────────────────────────────
                    heroAmount
                        .padding(.horizontal, 20)

                    // ── Category grid (expense / income) ──────────────
                    if type != .transfer {
                        categoryGrid
                            .padding(.horizontal, 20)
                    }

                    // ── Note ──────────────────────────────────────────
                    noteField
                        .padding(.horizontal, 20)

                    // ── Sub-transactions (expense only) ───────────────
                    if type == .expense {
                        subTransactionsSection
                            .padding(.horizontal, 20)
                    }

                    // ── Slip image ────────────────────────────────────
                    if loadedImage != nil || transactionToEdit?.imagePath != nil {
                        slipImageSection
                            .padding(.horizontal, 20)
                    }

                    // ── More details ──────────────────────────────────
                    moreDetailsSection
                        .padding(.horizontal, 20)

                    Spacer(minLength: 40)
                }
            }
            .background(theme.bg)
            .navigationTitle(transactionToEdit == nil ? "New Entry" : "Edit Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(theme.muted)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: saveTransaction) {
                        Text(transactionToEdit == nil ? "Save" : "Update")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(theme.brandInk)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 7)
                            .background(Capsule().fill(amount.isEmpty ? theme.muted : theme.brand))
                    }
                    .disabled(amount.isEmpty)
                }
                ToolbarItem(placement: .keyboard) {
                    HStack { Spacer(); Button("Done") { focusedField = nil } }
                }
            }
        }
        .onAppear {
            if let transaction = transactionToEdit {
                populateFromTransaction(transaction)
                loadImage(from: transaction.imagePath)
            } else {
                populateFromSlipData()
            }
        }
        .sheet(isPresented: $showDatePicker) {
            DatePicker("Select Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.graphical)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .padding()
        }

        if isShowSlip {
            fullScreenSlipOverlay
                .transition(.opacity)
                .zIndex(999)
        }
    }
}

// ── Type picker ────────────────────────────────────────────────────────────

private var typePicker: some View {
    HStack(spacing: 0) {
        typeBtn("Expense",  tag: .expense)
        typeBtn("Income",   tag: .income)
        typeBtn("Transfer", tag: .transfer)
    }
    .padding(4)
    .background(
        Capsule()
            .fill(theme.surface)
            .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 1)
    )
}

private func typeBtn(_ title: String, tag: TransactionType) -> some View {
    Button { type = tag } label: {
        Text(title)
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity)
            .background(Capsule().fill(type == tag ? theme.brand : Color.clear))
            .foregroundColor(type == tag ? theme.brandInk : theme.muted)
    }
    .buttonStyle(.plain)
}

// ── Hero amount ────────────────────────────────────────────────────────────

private var heroAmount: some View {
    VStack(spacing: 10) {
        Text("AMOUNT · THB")
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .tracking(1)
            .foregroundColor(theme.muted)

        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text("฿")
                .font(.system(size: 40, weight: .semibold, design: .rounded))
                .foregroundColor(theme.brand)
            TextField("0", text: $amount)
                .keyboardType(.decimalPad)
                .font(.system(size: 92, weight: .semibold, design: .rounded))
                .minimumScaleFactor(0.3)
                .multilineTextAlignment(.center)
                .focused($focusedField, equals: .amount)
                .foregroundColor(theme.ink)
        }

        // Date pill
        Button(action: { showDatePicker = true }) {
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.system(size: 13))
                Text(dateFormatted)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
            }
            .foregroundColor(theme.ink)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Capsule().fill(theme.surface))
        }
    }
}

// ── Category grid ──────────────────────────────────────────────────────────

private var categoryGrid: some View {
    VStack(alignment: .leading, spacing: 12) {
        Text("Category")
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundColor(theme.muted)

        if type == .expense {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                ForEach(ExpenseCategory.allCases) { cat in
                    expenseCatCell(cat)
                }
            }
        } else {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                ForEach(IncomeCategory.allCases) { cat in
                    incomeCatCell(cat)
                }
            }
        }
    }
}

private func expenseCatCell(_ cat: ExpenseCategory) -> some View {
    let active = selectedCategory == cat
    return Button { selectedCategory = cat } label: {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(active ? cat.color : cat.color.opacity(0.14))
                    .frame(height: 52)
                Image(systemName: cat.icon)
                    .font(.system(size: 20))
                    .foregroundColor(active ? .white : cat.color)
            }
            Text(cat.displayName)
                .font(.system(size: 10))
                .foregroundColor(active ? theme.ink : theme.muted)
                .lineLimit(1)
        }
    }
    .buttonStyle(.plain)
}

private func incomeCatCell(_ cat: IncomeCategory) -> some View {
    let active = selectedIncomeCategory == cat
    return Button { selectedIncomeCategory = cat } label: {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(active ? cat.color : cat.color.opacity(0.14))
                    .frame(height: 52)
                Image(systemName: cat.icon)
                    .font(.system(size: 20))
                    .foregroundColor(active ? .white : cat.color)
            }
            Text(cat.displayName)
                .font(.system(size: 10))
                .foregroundColor(active ? theme.ink : theme.muted)
                .lineLimit(1)
        }
    }
    .buttonStyle(.plain)
}

// ── Note ───────────────────────────────────────────────────────────────────

private var noteField: some View {
    HStack(spacing: 12) {
        Image(systemName: "square.and.pencil")
            .foregroundColor(theme.muted)
        TextField("Add a note…", text: $description)
            .focused($focusedField, equals: .description)
            .foregroundColor(theme.ink)
    }
    .padding(16)
    .background(
        RoundedRectangle(cornerRadius: 18)
            .fill(theme.surface)
    )
}

// ── More details (bank, sender, receiver, ref) ─────────────────────────────

private var moreDetailsSection: some View {
    DisclosureGroup(
        isExpanded: $showMoreDetails,
        content: {
            VStack(spacing: 16) {
                Divider()
                HStack {
                    Text("Bank")
                        .foregroundColor(theme.muted)
                    Spacer()
                    Picker("Bank", selection: $selectedBank) {
                        ForEach(Bank.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .labelsHidden()
                }
                customTextField("Sender", text: $sender, field: .sender)
                customTextField("Receiver", text: $receiver, field: .receiver)
                customTextField("Reference ID", text: $refId, field: .refId)
            }
            .padding(.top, 8)
        },
        label: {
            Text("More Details")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(theme.ink)
        }
    )
    .padding(16)
    .background(
        RoundedRectangle(cornerRadius: 18)
            .fill(theme.surface)
    )
}

private func customTextField(_ title: String, text: Binding<String>, field: Field) -> some View {
    VStack(alignment: .leading, spacing: 4) {
        Text(title)
            .font(.caption)
            .foregroundColor(theme.muted)
        TextField(title, text: text)
            .focused($focusedField, equals: field)
            .padding(10)
            .background(theme.bg)
            .cornerRadius(8)
            .foregroundColor(theme.ink)
    }
}
```

Keep the `subTransactionsSection` computed property from the existing file as-is (just update the colors to use theme tokens — replace all `Color.blue` with `theme.brand`, all `Color(uiColor: .secondarySystemGroupedBackground)` with `theme.surface`, `Color(uiColor: .tertiarySystemGroupedBackground)` with `theme.bg`).

- [ ] **Step 2: Build to verify**

Run the build command. If there are compile errors, read the error messages carefully — most will be about missing properties in the body that reference `categoryButton` or `slipImageSection`. Keep those helpers from the original file. Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git -C /Users/jackkahod/Desktop/File/Project/Meow-Jod-Clone-App/.worktrees/feat/full-ui-redesign \
  add BROKE/Views/AddTransactionView.swift && \
git -C /Users/jackkahod/Desktop/File/Project/Meow-Jod-Clone-App/.worktrees/feat/full-ui-redesign \
  commit -m "feat: rebuild AddTransactionView with 92pt hero amount and 4-col category grid"
```

---

## Task 8: Rebuild AnalyticsView

**Files:**
- Modify: `BROKE/Views/AnalyticsView.swift`

Key changes: pill segmented control (not system), mascot insight card, category rows with coloured progress bars. Keep all existing data logic (grouping, comparison, flattenTransactions) unchanged. Rebuild only the visual layer.

- [ ] **Step 1: Replace the visual layer of AnalyticsView.swift**

The file is large. Keep all data-computation code (`getTransactions`, `chartTransactions`, `monthStats`, `averageMonthlyExpense3Months`, `comparisonToAverage`, `flattenTransactions` etc.) unchanged. Replace only the structs that render UI:

**Replace `AnalyticsView.body`:**
```swift
var body: some View {
    ScrollView {
        VStack(spacing: 20) {
            analyticsHeader
                .padding(.top, 56)

            SummaryStatsBoard(stats: monthStats)

            TypeFilterTabs(selectedTab: $selectedTab)
                .padding(.horizontal, 16)

            CategoryBreakdownChart(
                transactions: chartTransactions,
                contextMonth: currentDate,
                contextType: selectedTab,
                totalAmount: selectedTab == .expense ? monthStats.expense : monthStats.income
            )

            if selectedTab == .expense {
                ComparisonTagView(
                    diff: comparisonToAverage.diff,
                    isLower: comparisonToAverage.isLower,
                    avg: averageMonthlyExpense3Months
                )

                BehaviorInsightCard(
                    transactions: currentMonthTransactions,
                    avgExpense: averageMonthlyExpense3Months
                )

                MonthlyComparisonChart(
                    currentDate: currentDate,
                    transactionStore: transactionStore,
                    average: averageMonthlyExpense3Months
                )

                CategoryPerformanceList(
                    currentTransactions: chartTransactions,
                    previous3Months: previous3Months,
                    transactionStore: transactionStore
                )
            }

            Spacer(minLength: 20)
        }
    }
    .background(theme.bg.ignoresSafeArea())
    .navigationBarTitleDisplayMode(.inline)
}

private var analyticsHeader: some View {
    HStack(spacing: 14) {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(theme.softBrand)
                .frame(width: 44, height: 44)
            MascotView(size: 28, mood: .sleepy)
        }
        VStack(alignment: .leading, spacing: 3) {
            Text("Where it went")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundColor(theme.ink)
            Text(currentDate.formatted(.dateTime.month(.wide).year()))
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(theme.muted)
        }
        Spacer()
        // Month navigation
        HStack(spacing: 0) {
            Button { changeMonth(by: -1) } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(theme.muted)
                    .frame(width: 32, height: 32)
            }
            Button { changeMonth(by: 1) } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(theme.muted)
                    .frame(width: 32, height: 32)
            }
        }
    }
    .padding(.horizontal, 20)
}

private func changeMonth(by value: Int) {
    if let d = Calendar.current.date(byAdding: .month, value: value, to: currentDate) {
        currentDate = d
    }
}
```

**Replace `MonthYearNavigator`** — no longer used (absorbed into `analyticsHeader` above). Remove or leave as dead code (it won't be referenced).

**Replace `SummaryStatsBoard`:**
```swift
struct SummaryStatsBoard: View {
    let stats: (income: Double, expense: Double, balance: Double)
    @EnvironmentObject var theme: ThemeManager

    var body: some View {
        HStack(spacing: 8) {
            statPill(label: "Income",  value: stats.income,  color: theme.income,  arrow: "arrow.down")
            statPill(label: "Expense", value: stats.expense, color: theme.expense, arrow: "arrow.up")
        }
        .padding(.horizontal, 16)
    }

    private func statPill(label: String, value: Double, color: Color, arrow: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: arrow)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(color)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(theme.muted)
                Text("฿\(Int(value).formattedWithSeparator)")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(color)
            }
            Spacer()
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(theme.surface))
        .frame(maxWidth: .infinity)
    }
}
```

**Replace `TypeFilterTabs`:**
```swift
struct TypeFilterTabs: View {
    @Binding var selectedTab: TransactionType
    @EnvironmentObject var theme: ThemeManager

    var body: some View {
        HStack(spacing: 0) {
            tabBtn("Expense", .expense)
            tabBtn("Income",  .income)
        }
        .padding(4)
        .background(Capsule().fill(theme.surface))
    }

    private func tabBtn(_ title: String, _ type: TransactionType) -> some View {
        let active = selectedTab == type
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) { selectedTab = type }
        } label: {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(Capsule().fill(active ? theme.brand : Color.clear))
                .foregroundColor(active ? theme.brandInk : theme.muted)
        }
        .buttonStyle(.plain)
    }
}
```

**Replace `ComparisonTagView`:**
```swift
struct ComparisonTagView: View {
    let diff: Double
    let isLower: Bool
    let avg: Double
    @EnvironmentObject var theme: ThemeManager

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isLower ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                .foregroundColor(isLower ? theme.income : theme.expense)
            if avg == 0 {
                Text("No comparison data yet")
                    .font(.system(size: 14))
                    .foregroundColor(theme.muted)
            } else {
                Text("\(isLower ? "Lower" : "Higher") than avg by ฿\(Int(diff).formattedWithSeparator)")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(theme.ink)
            }
            Spacer()
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(theme.surface))
        .padding(.horizontal, 16)
    }
}
```

**Replace `BehaviorInsightCard`** — keep `insightText` logic, replace visual wrapper:
```swift
struct BehaviorInsightCard: View {
    let transactions: [Transaction]
    let avgExpense: Double
    @EnvironmentObject var theme: ThemeManager

    // (keep existing insightText computed property unchanged)

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.softBrand)
                    .frame(width: 36, height: 36)
                MascotView(size: 22, mood: .happy)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("INSIGHT")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1)
                    .foregroundColor(theme.muted)
                Text(insightText)
                    .font(.system(size: 14))
                    .foregroundColor(theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.brand.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(theme.brand.opacity(0.15), lineWidth: 1))
        )
        .padding(.horizontal, 16)
    }
}
```

**Replace `CategoryPerformanceList`** — keep `rows` data logic, replace visual output:
```swift
struct CategoryPerformanceList: View {
    let currentTransactions: [Transaction]
    let previous3Months: [Date]
    var transactionStore: TransactionStore
    @EnvironmentObject var theme: ThemeManager

    // (keep existing CategoryPerf struct and rows computed property unchanged)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Category Performance")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(theme.ink)
                .padding(.bottom, 12)

            VStack(spacing: 0) {
                ForEach(rows) { row in
                    categoryRow(row)
                    if row.id != rows.last?.id {
                        Divider().padding(.leading, 52)
                    }
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 20).fill(theme.surface))
        .padding(.horizontal, 16)
    }

    private func categoryRow(_ row: CategoryPerf) -> some View {
        NavigationLink(destination: CategoryDetailView(
            category: row.category,
            transactions: currentTransactions.filter { $0.categoryId == row.category }
        )) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(row.category.color.opacity(0.14))
                        .frame(width: 36, height: 36)
                    Image(systemName: row.category.icon)
                        .font(.system(size: 16))
                        .foregroundColor(row.category.color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(row.category.displayName)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(theme.ink)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(theme.rule).frame(height: 4)
                            let max = rows.first?.currentAmount ?? 1
                            let w = max > 0 ? geo.size.width * min(row.currentAmount / max, 1) : 0
                            Capsule()
                                .fill(row.category.color)
                                .frame(width: w, height: 4)
                        }
                    }
                    .frame(height: 4)

                    if row.avgPast > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: row.isLower ? "arrow.down" : "arrow.up")
                                .font(.system(size: 9))
                            Text("\(row.isLower ? "−" : "+")฿\(Int(abs(row.delta)).formattedWithSeparator) vs avg")
                                .font(.system(size: 11))
                        }
                        .foregroundColor(row.isLower ? theme.income : theme.expense)
                    }
                }

                Spacer()

                Text("฿\(Int(row.currentAmount).formattedWithSeparator)")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(theme.ink)
            }
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
    }
}
```

**Replace `MonthlyComparisonChart`** — keep chart data logic, update visual chrome:
```swift
struct MonthlyComparisonChart: View {
    let currentDate: Date
    let transactionStore: TransactionStore
    let average: Double
    @EnvironmentObject var theme: ThemeManager

    // (keep existing MonthlyCategoryData struct and chartData computed property unchanged)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Last 4 Months")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(theme.ink)
            Chart {
                ForEach(chartData) { item in
                    BarMark(
                        x: .value("Month", item.month, unit: .month),
                        y: .value("Amount", item.amount)
                    )
                    .foregroundStyle(item.category.color)
                }
                RuleMark(y: .value("Average", average))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    .foregroundStyle(theme.muted)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) { _ in
                    AxisValueLabel(format: .dateTime.month(.abbreviated))
                }
            }
            .frame(height: 160)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 20).fill(theme.surface))
        .padding(.horizontal, 16)
    }
}
```

**Update `AnalyticsView_Previews`:**
```swift
struct AnalyticsView_Previews: PreviewProvider {
    static var previews: some View {
        AnalyticsView()
            .environmentObject(TransactionStore())
            .environmentObject(ThemeManager())
    }
}
```

- [ ] **Step 2: Build to verify**

Run the build command. Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git -C /Users/jackkahod/Desktop/File/Project/Meow-Jod-Clone-App/.worktrees/feat/full-ui-redesign \
  add BROKE/Views/AnalyticsView.swift && \
git -C /Users/jackkahod/Desktop/File/Project/Meow-Jod-Clone-App/.worktrees/feat/full-ui-redesign \
  commit -m "feat: rebuild AnalyticsView with pill tabs, mascot insight card, category progress bars"
```

---

## Task 9: Rebuild SettingsView

**Files:**
- Modify: `BROKE/Views/SettingsView.swift`

Key changes: hero card with mascot, mascot switcher (two-card picker), appearance pickers. All existing functional sections preserved.

- [ ] **Step 1: Replace SettingsView.swift**

```swift
//
//  SettingsView.swift
//  BROKE
//

import PhotosUI
import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @EnvironmentObject var transactionStore: TransactionStore
    @EnvironmentObject var theme: ThemeManager
    @AppStorage("lastScannedDate") private var lastScannedDate: Date?
    @State private var isRequestingAccess = false
    @State private var isImportingFile = false
    @State private var exportedFileURL: URL?
    @State private var isShareSheetPresented = false

    private var dateFormatter: DateFormatter {
        let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .none; return f
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // ── Hero card ──────────────────────────────
                heroCard
                    .padding(.top, 56)

                // ── Mascot switcher ────────────────────────
                mascotSwitcher
                    .padding(.horizontal, 16)

                // ── Appearance ─────────────────────────────
                settingsCard("Appearance") {
                    labeledPicker("Theme",      selection: $theme.character) {
                        Label("Penguin", systemImage: "snowflake").tag(ThemeCharacter.penguin)
                        Label("Dragon",  systemImage: "flame").tag(ThemeCharacter.dragon)
                    }
                    Divider()
                    labeledPicker("Mode", selection: $theme.appearance) {
                        Label("Light",  systemImage: "sun.max").tag(AppearanceMode.light)
                        Label("Dark",   systemImage: "moon").tag(AppearanceMode.dark)
                        Label("System", systemImage: "circle.lefthalf.filled").tag(AppearanceMode.system)
                    }
                }
                .padding(.horizontal, 16)

                // ── Photo library ──────────────────────────
                settingsCard("Photo Library") {
                    Button("Request Photo Access") { isRequestingAccess = true }
                        .foregroundColor(theme.brand)
                        .sheet(isPresented: $isRequestingAccess) { RequestPhotoAccessView() }
                    Divider()
                    HStack {
                        Text("Scan Start Date").foregroundColor(theme.ink)
                        Spacer()
                        Text("\(viewModel.scanStartDate, formatter: dateFormatter)")
                            .foregroundColor(theme.muted)
                    }
                }
                .padding(.horizontal, 16)

                // ── SlipOK API ─────────────────────────────
                settingsCard("SlipOK API") {
                    HStack {
                        Text("Remaining Quota").foregroundColor(theme.ink)
                        Spacer()
                        if viewModel.isLoadingQuota {
                            ProgressView()
                        } else if let quota = viewModel.slipOKQuota {
                            Text("\(quota)")
                                .foregroundColor(quota < 10 ? theme.expense : theme.ink)
                        } else {
                            Text("-").foregroundColor(theme.muted)
                        }
                    }
                    if let error = viewModel.errorMessage {
                        Text(error).font(.caption).foregroundColor(theme.expense)
                    }
                    Divider()
                    Button("Refresh Quota") { viewModel.fetchQuota() }
                        .foregroundColor(theme.brand)
                        .disabled(viewModel.isLoadingQuota)
                }
                .padding(.horizontal, 16)

                // ── Data management ────────────────────────
                settingsCard("Data") {
                    if viewModel.isImporting {
                        HStack { ProgressView(); Text(viewModel.importMessage ?? "Importing…").foregroundColor(theme.muted) }
                    } else {
                        Button("Import from CSV") { isImportingFile = true }.foregroundColor(theme.brand)
                    }
                    if let msg = viewModel.importMessage, !viewModel.isImporting {
                        Text(msg).font(.caption).foregroundColor(theme.income)
                    }
                    Divider()
                    Button("Export to CSV") {
                        if let url = viewModel.exportData(store: transactionStore) {
                            exportedFileURL = url
                            isShareSheetPresented = true
                        }
                    }
                    .foregroundColor(theme.brand)
                    .sheet(isPresented: $isShareSheetPresented, onDismiss: { exportedFileURL = nil }) {
                        if let url = exportedFileURL { ShareSheet(activityItems: [url]) }
                    }
                }
                .padding(.horizontal, 16)

                Spacer(minLength: 20)
            }
        }
        .background(theme.bg.ignoresSafeArea())
        .onAppear { viewModel.fetchQuota() }
        .fileImporter(isPresented: $isImportingFile, allowedContentTypes: [.commaSeparatedText, .plainText], allowsMultipleSelection: false) { result in
            if case let .success(urls) = result, let url = urls.first {
                viewModel.importCSV(from: url, into: transactionStore)
            }
        }
    }

    // MARK: - Hero card

    private var heroCard: some View {
        ZStack(alignment: .topTrailing) {
            // Decorative mascot in corner
            MascotView(size: 100)
                .rotationEffect(.degrees(-8))
                .opacity(0.18)
                .offset(x: 10, y: -10)

            VStack(alignment: .leading, spacing: 8) {
                Text("MEMBER SINCE")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1)
                    .foregroundColor(theme.brandInk.opacity(0.7))

                Text("Punyaphat S.")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundColor(theme.brandInk)

                let label = theme.character == .penguin
                    ? "slips caught by the penguin"
                    : "slips toasted by the dragon"
                Text("428 \(label)")
                    .font(.system(size: 13))
                    .foregroundColor(theme.brandInk.opacity(0.8))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(22)
        }
        .background(
            RoundedRectangle(cornerRadius: 26)
                .fill(theme.brand)
                .clipped()
        )
        .padding(.horizontal, 16)
    }

    // MARK: - Mascot switcher

    private var mascotSwitcher: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Choose your mascot")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(theme.muted)

            HStack(spacing: 12) {
                mascotCard(.penguin, label: "Penguin")
                mascotCard(.dragon,  label: "Dragon")
            }
        }
    }

    private func mascotCard(_ char: ThemeCharacter, label: String) -> some View {
        let active = theme.character == char
        return Button { theme.character = char } label: {
            VStack(spacing: 10) {
                // Temporarily switch character for preview
                MascotView(size: 64)
                    .environmentObject(previewTheme(for: char))
                Text(label)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(active ? theme.brand : theme.muted)
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(active ? theme.softBrand : theme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(active ? theme.brand : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    /// Returns a ThemeManager that has the given character but inherits current appearance mode.
    private func previewTheme(for char: ThemeCharacter) -> ThemeManager {
        let t = ThemeManager()
        t.character = char
        t.appearance = theme.appearance
        return t
    }

    // MARK: - Helpers

    @ViewBuilder
    private func settingsCard<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .tracking(0.5)
                .foregroundColor(theme.muted)
                .padding(.bottom, 10)

            VStack(spacing: 12) {
                content()
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 18).fill(theme.surface))
        }
    }

    @ViewBuilder
    private func labeledPicker<T: Hashable, Content: View>(
        _ label: String,
        selection: Binding<T>,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack {
            Text(label).foregroundColor(theme.ink)
            Spacer()
            Picker(label, selection: selection) {
                content()
            }
            .labelsHidden()
        }
    }
}
```

- [ ] **Step 2: Build to verify**

Run the build command. Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git -C /Users/jackkahod/Desktop/File/Project/Meow-Jod-Clone-App/.worktrees/feat/full-ui-redesign \
  add BROKE/Views/SettingsView.swift && \
git -C /Users/jackkahod/Desktop/File/Project/Meow-Jod-Clone-App/.worktrees/feat/full-ui-redesign \
  commit -m "feat: rebuild SettingsView with hero card, mascot switcher, and themed sections"
```

---

## Task 10: Add formattedWithSeparator to Int (fix compile dependency)

**Files:**
- Modify: `BROKE/Utils/Extensions.swift`

The `Int.formattedWithSeparator` property is used in AnalyticsView and is defined there as a local extension. Move it to `Extensions.swift` so all new views can use it.

- [ ] **Step 1: Add Int extension to Extensions.swift**

Add to the bottom of `BROKE/Utils/Extensions.swift`:

```swift
extension Int {
    var formattedWithSeparator: String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return f.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}
```

Remove the duplicate `extension Int { var formattedWithSeparator }` from inside `AnalyticsView.swift` (it's defined there as a top-level extension at the bottom of the file).

- [ ] **Step 2: Build to verify**

Run the build command. Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git -C /Users/jackkahod/Desktop/File/Project/Meow-Jod-Clone-App/.worktrees/feat/full-ui-redesign \
  add BROKE/Utils/Extensions.swift BROKE/Views/AnalyticsView.swift && \
git -C /Users/jackkahod/Desktop/File/Project/Meow-Jod-Clone-App/.worktrees/feat/full-ui-redesign \
  commit -m "refactor: move Int.formattedWithSeparator to Extensions.swift"
```

---

## Self-Review

**Spec coverage:**
- ✅ Custom floating pill tab bar replacing UITabBar
- ✅ Mascot SVG (penguin + dragon) with mood variants
- ✅ Mascot in header on every screen (Home, Analytics, Settings hero)
- ✅ Balance card with brand-color background and in/out row
- ✅ SlipBanner with mascot speech text
- ✅ Transaction rows with coloured icon tile + bank pill
- ✅ Grouped date sections as rounded card containers
- ✅ 92pt hero amount in AddTransactionView
- ✅ 4-column category grid with solid/tinted active states
- ✅ Pill segmented controls throughout
- ✅ Analytics: mascot insight card, category progress bars, monthly chart
- ✅ Settings: hero card, mascot switcher (two-card picker), all existing functional sections
- ✅ Full token set (bg/surface/raised/ink/bodyText/muted/rule/brand/brandInk/softBrand/chipBg/income/expense)
- ✅ All existing business logic, ViewModels, Services untouched

**Potential compile issues to watch:**
- `HomeViewModel.getTransactions(from:)` — must accept a `TransactionStore` argument (Task 5)
- `HomeViewModel.isCurrentMonthAndYear` — bool property (Task 5)
- `TransactionStore.totalIncome()` / `totalExpense()` — must return Double (Task 4, BalanceCard)
- `Int.formattedWithSeparator` — used in Tasks 4–9, defined in Task 10 (do Task 10 first if you see missing-member errors)

**Type consistency:** All token names consistent: `theme.bg`, `theme.surface`, `theme.raised`, `theme.ink`, `theme.bodyText`, `theme.muted`, `theme.rule`, `theme.brand`, `theme.brandInk`, `theme.softBrand`, `theme.chipBg`, `theme.income`, `theme.expense`.
