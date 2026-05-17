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
    @AppStorage("themeCharacter") var character: ThemeCharacter = .penguin
    @AppStorage("appearanceMode") var appearance: AppearanceMode = .light

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

    // MARK: - Backward-compat aliases
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
