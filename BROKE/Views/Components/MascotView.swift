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
            Circle()
                .fill(theme.ink)
                .frame(width: s(3.8), height: s(3.8))
                .offset(x: s(25.5 - 32), y: s(29 - 32))
            Circle()
                .fill(theme.ink)
                .frame(width: s(3.8), height: s(3.8))
                .offset(x: s(38.5 - 32), y: s(29 - 32))
        case .happy, .sleepy:
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
            let x: CGFloat = leftEye ? 23 : 36
            p.move(to: CGPoint(x: x * s, y: 29 * s))
            p.addLine(to: CGPoint(x: (x + 5) * s, y: 29 * s))
        } else {
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
