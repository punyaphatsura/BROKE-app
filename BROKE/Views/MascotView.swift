// BROKE/Views/MascotView.swift
import SwiftUI

enum MascotMood { case happy, sleepy, alert }

struct MascotView: View {
    @EnvironmentObject var theme: ThemeManager
    var size: CGFloat = 36
    var mood: MascotMood = .happy

    var body: some View {
        if theme.character == .penguin {
            PenguinShape(size: size, mood: mood, color: theme.primary, ink: theme.textPrimary)
        } else {
            DragonShape(size: size, mood: mood, color: theme.primary, ink: theme.textPrimary)
        }
    }
}

struct PenguinShape: View {
    let size: CGFloat
    let mood: MascotMood
    let color: Color
    let ink: Color

    var body: some View {
        Canvas { ctx, _ in
            let s = size
            ctx.fill(ellipsePath(cx: s*0.17, cy: s*0.625, rx: s*0.08, ry: s*0.17, angle: -12), with: .color(color))
            ctx.fill(ellipsePath(cx: s*0.83, cy: s*0.625, rx: s*0.08, ry: s*0.17, angle: 12), with: .color(color))
            ctx.fill(ellipsePath(cx: s*0.5, cy: s*0.53, rx: s*0.31, ry: s*0.34), with: .color(color))
            ctx.fill(ellipsePath(cx: s*0.5, cy: s*0.59, rx: s*0.19, ry: s*0.25), with: .color(.white))
            var beak = Path()
            beak.move(to: CGPoint(x: s*0.44, y: s*0.52))
            beak.addLine(to: CGPoint(x: s*0.56, y: s*0.52))
            beak.addLine(to: CGPoint(x: s*0.5, y: s*0.59))
            beak.closeSubpath()
            ctx.fill(beak, with: .color(Color(hex: "FF9A3C")))
            drawMoodEyes(ctx: ctx, s: s, mood: mood, ink: ink, lx: 0.36, rx: 0.60, y: 0.44)
            ctx.fill(ellipsePath(cx: s*0.41, cy: s*0.86, rx: s*0.07, ry: s*0.04), with: .color(Color(hex: "FF9A3C")))
            ctx.fill(ellipsePath(cx: s*0.59, cy: s*0.86, rx: s*0.07, ry: s*0.04), with: .color(Color(hex: "FF9A3C")))
        }
        .frame(width: size, height: size)
    }
}

struct DragonShape: View {
    let size: CGFloat
    let mood: MascotMood
    let color: Color
    let ink: Color

    var body: some View {
        Canvas { ctx, _ in
            let s = size
            let horn = Color(hex: "F0A53A")
            var lh = Path()
            lh.move(to: CGPoint(x: s*0.30, y: s*0.34))
            lh.addLine(to: CGPoint(x: s*0.33, y: s*0.14))
            lh.addLine(to: CGPoint(x: s*0.41, y: s*0.33))
            lh.closeSubpath()
            var rh = Path()
            rh.move(to: CGPoint(x: s*0.70, y: s*0.34))
            rh.addLine(to: CGPoint(x: s*0.67, y: s*0.14))
            rh.addLine(to: CGPoint(x: s*0.59, y: s*0.33))
            rh.closeSubpath()
            ctx.fill(lh, with: .color(horn))
            ctx.fill(rh, with: .color(horn))
            ctx.fill(ellipsePath(cx: s*0.5, cy: s*0.56, rx: s*0.34, ry: s*0.31), with: .color(color))
            ctx.fill(ellipsePath(cx: s*0.5, cy: s*0.66, rx: s*0.17, ry: s*0.11), with: .color(.black.opacity(0.06)))
            ctx.fill(Circle().path(in: CGRect(x: s*0.44, y: s*0.62, width: s*0.035, height: s*0.035)), with: .color(ink))
            ctx.fill(Circle().path(in: CGRect(x: s*0.52, y: s*0.62, width: s*0.035, height: s*0.035)), with: .color(ink))
            ctx.fill(ellipsePath(cx: s*0.27, cy: s*0.625, rx: s*0.038, ry: s*0.038), with: .color(horn.opacity(0.5)))
            ctx.fill(ellipsePath(cx: s*0.73, cy: s*0.625, rx: s*0.038, ry: s*0.038), with: .color(horn.opacity(0.5)))
            drawMoodEyes(ctx: ctx, s: s, mood: mood, ink: ink, lx: 0.34, rx: 0.61, y: 0.47)
            drawSmile(ctx: ctx, s: s, ink: ink)
        }
        .frame(width: size, height: size)
    }
}

private func ellipsePath(cx: CGFloat, cy: CGFloat, rx: CGFloat, ry: CGFloat, angle: CGFloat = 0) -> Path {
    var p = Path(ellipseIn: CGRect(x: cx - rx, y: cy - ry, width: rx * 2, height: ry * 2))
    if angle != 0 {
        let t = CGAffineTransform(translationX: cx, y: cy)
            .rotated(by: angle * .pi / 180)
            .translatedBy(x: -cx, y: -cy)
        p = p.applying(t)
    }
    return p
}

private func drawMoodEyes(ctx: GraphicsContext, s: CGFloat, mood: MascotMood, ink: Color, lx: CGFloat, rx: CGFloat, y: CGFloat) {
    switch mood {
    case .happy:
        var le = Path()
        le.move(to: CGPoint(x: s*lx, y: s*y))
        le.addQuadCurve(to: CGPoint(x: s*(lx+0.08), y: s*y), control: CGPoint(x: s*(lx+0.04), y: s*(y-0.04)))
        var re = Path()
        re.move(to: CGPoint(x: s*rx, y: s*y))
        re.addQuadCurve(to: CGPoint(x: s*(rx+0.08), y: s*y), control: CGPoint(x: s*(rx+0.04), y: s*(y-0.04)))
        ctx.stroke(le, with: .color(ink), style: StrokeStyle(lineWidth: s*0.034, lineCap: .round))
        ctx.stroke(re, with: .color(ink), style: StrokeStyle(lineWidth: s*0.034, lineCap: .round))
    case .sleepy:
        var le = Path()
        le.move(to: CGPoint(x: s*lx, y: s*y))
        le.addLine(to: CGPoint(x: s*(lx+0.08), y: s*y))
        var re = Path()
        re.move(to: CGPoint(x: s*rx, y: s*y))
        re.addLine(to: CGPoint(x: s*(rx+0.08), y: s*y))
        ctx.stroke(le, with: .color(ink), style: StrokeStyle(lineWidth: s*0.034, lineCap: .round))
        ctx.stroke(re, with: .color(ink), style: StrokeStyle(lineWidth: s*0.034, lineCap: .round))
    case .alert:
        ctx.fill(Circle().path(in: CGRect(x: s*(lx+0.01), y: s*(y-0.03), width: s*0.06, height: s*0.06)), with: .color(ink))
        ctx.fill(Circle().path(in: CGRect(x: s*(rx+0.01), y: s*(y-0.03), width: s*0.06, height: s*0.06)), with: .color(ink))
    }
}

private func drawSmile(ctx: GraphicsContext, s: CGFloat, ink: Color) {
    var p = Path()
    p.move(to: CGPoint(x: s*0.41, y: s*0.69))
    p.addQuadCurve(to: CGPoint(x: s*0.59, y: s*0.69), control: CGPoint(x: s*0.5, y: s*0.76))
    ctx.stroke(p, with: .color(ink), style: StrokeStyle(lineWidth: s*0.028, lineCap: .round))
}
