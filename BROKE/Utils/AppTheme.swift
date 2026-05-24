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
    @Published var character: ThemeCharacter {
        didSet { UserDefaults.standard.set(character.rawValue, forKey: "themeCharacter") }
    }
    @Published var appearance: AppearanceMode {
        didSet { UserDefaults.standard.set(appearance.rawValue, forKey: "appearanceMode") }
    }

    init() {
        character = UserDefaults.standard.string(forKey: "themeCharacter")
            .flatMap(ThemeCharacter.init(rawValue:)) ?? .penguin
        appearance = UserDefaults.standard.string(forKey: "appearanceMode")
            .flatMap(AppearanceMode.init(rawValue:)) ?? .light
    }

    var preferredColorScheme: ColorScheme? {
        switch appearance {
        case .light:  return .light
        case .dark:   return .dark
        case .system: return nil
        }
    }

    // MARK: - Public tokens

    var background: Color     { resolve(.background) }
    var cardBackground: Color { resolve(.cardBackground) }
    var primary: Color        { resolve(.primary) }
    var accent: Color         { resolve(.accent) }
    var textPrimary: Color    { resolve(.textPrimary) }
    var textSecondary: Color  { resolve(.textPrimary).opacity(0.5) }
    var income: Color         { resolve(.income) }
    var expense: Color        { resolve(.expense) }
    var separator: Color      { resolve(.primary).opacity(0.12) }

    // MARK: - Private

    private enum Token {
        case background, cardBackground, primary, accent, textPrimary, income, expense
    }

    private func resolve(_ token: Token) -> Color {
        switch appearance {
        case .light:
            return lightColor(token, for: character)
        case .dark:
            return darkColor(token, for: character)
        case .system:
            return Color(uiColor: UIColor { [self] traits in
                UIColor(
                    traits.userInterfaceStyle == .dark
                        ? self.darkColor(token, for: self.character)
                        : self.lightColor(token, for: self.character)
                )
            })
        }
    }

    private func lightColor(_ token: Token, for character: ThemeCharacter) -> Color {
        switch (character, token) {
        case (.penguin, .background):     return Color(hex: "F0F7FF")
        case (.penguin, .cardBackground): return Color(hex: "DDEEFF")
        case (.penguin, .primary):        return Color(hex: "3D9BF0")
        case (.penguin, .accent):         return Color(hex: "FFA94D")
        case (.penguin, .textPrimary):    return Color(hex: "1A1410")
        case (.penguin, .income):         return Color(hex: "1A8A50")
        case (.penguin, .expense):        return Color(hex: "D93030")
        case (.dragon, .background):      return Color(hex: "FFF6EC")
        case (.dragon, .cardBackground):  return Color(hex: "F0EEE9")
        case (.dragon, .primary):         return Color(hex: "F5BC1A")
        case (.dragon, .accent):          return Color(hex: "FF8A3D")
        case (.dragon, .textPrimary):     return Color(hex: "2A1F08")
        case (.dragon, .income):          return Color(hex: "1A8A50")
        case (.dragon, .expense):         return Color(hex: "CC3300")
        }
    }

    private func darkColor(_ token: Token, for character: ThemeCharacter) -> Color {
        switch (character, token) {
        case (.penguin, .background):     return Color(hex: "0A1628")
        case (.penguin, .cardBackground): return Color(hex: "0D2847")
        case (.penguin, .primary):        return Color(hex: "3D9BF0")
        case (.penguin, .accent):         return Color(hex: "FFA94D")
        case (.penguin, .textPrimary):    return Color(hex: "FFFCF1")
        case (.penguin, .income):         return Color(hex: "40C8A0")
        case (.penguin, .expense):        return Color(hex: "FF6B8A")
        case (.dragon, .background):      return Color(hex: "1C0E08")
        case (.dragon, .cardBackground):  return Color(hex: "2D1206")
        case (.dragon, .primary):         return Color(hex: "F5BC1A")
        case (.dragon, .accent):          return Color(hex: "FF8A3D")
        case (.dragon, .textPrimary):     return Color(hex: "FFFCF1")
        case (.dragon, .income):          return Color(hex: "40C8A0")
        case (.dragon, .expense):         return Color(hex: "FF6B8A")
        }
    }
}
