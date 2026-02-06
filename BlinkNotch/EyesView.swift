import SwiftUI
import Combine
import CoreGraphics

struct EyesView: View {
    @ObservedObject var model: BlinkModel
    private let currentStyle: EyeStyle = .v2

    var body: some View {
        ZStack {
            HStack(spacing: 60) {
                eyeShape(flipped: false)
                eyeShape(flipped: true)
            }
            .opacity(1.0)
        }
        .frame(width: 190, height: 80)
        .opacity(model.opacity)
        .offset(y: model.islandOffsetY)
        .animation(.none, value: model.opacity)
    }

    private func eyeShape(flipped: Bool) -> some View {
        let containerWidth: CGFloat = currentStyle.referenceSize.width
        let containerHeight: CGFloat = currentStyle.referenceSize.height

        if currentStyle == .v2 {
            // V2: blinking uses rounded-rect squish; sore uses morph
            let minScale: CGFloat = 4.0 / 60.0 // closed height over open height
            let t = max(0.0, min(1.0, model.eyeMorph / 2.0)) // 0=open, 1=closed
            let scaleY = 1.0 - (1.0 - minScale) * t
            let currentHeight = containerHeight * scaleY
            let cornerRadius = currentHeight / 2.0

            if model.isSoreActive {
                let soreT = max(0.0, min(1.0, model.soreMorph)) // 0=open, 1=sore
                return AnyView(
                    ZStack {
                        MorphingEyeShape(style: currentStyle, progress: soreT)
                        .fill(Color.white)
                            .frame(width: containerWidth, height: containerHeight)

                        // Stable pill on top to mask minor morph glitches
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(Color.white)
                            .frame(width: containerWidth, height: 10)
                    }
                    .scaleEffect(x: flipped ? -1.0 : 1.0, y: 1.0, anchor: .center)
                )
            }

            return AnyView(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.white)
                    .frame(width: containerWidth, height: currentHeight)
                    .scaleEffect(x: flipped ? -1.0 : 1.0, y: 1.0, anchor: .center)
            )
        } else {
            return AnyView(
                MorphingEyeShape(style: currentStyle, progress: model.eyeMorph)
                    .fill(Color.white)
                    .frame(width: containerWidth, height: containerHeight)
                    .scaleEffect(x: flipped ? -1.0 : 1.0, y: 1.0, anchor: .center)
            )
        }
    }
}


struct EyeShape: Shape {
    /// 0.0 = no pinch, 0.20 = stronger pinch
    var innerPinch: CGFloat

    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let r = min(w, h) * 0.45
        let pinch = max(0, min(0.25, innerPinch))

        let leftX: CGFloat = 0
        let rightX: CGFloat = w
        let topY: CGFloat = 0
        let bottomY: CGFloat = h
        let midY: CGFloat = h * 0.5

        // How much to pull the inner edge inward
        let innerInset = w * (0.08 + pinch)
        let outerInset = w * 0.02

        var p = Path()
        p.move(to: CGPoint(x: w * 0.5, y: topY))

        // Top-right curve
        p.addCurve(
            to: CGPoint(x: rightX, y: midY * 0.55),
            control1: CGPoint(x: w * 0.82, y: topY),
            control2: CGPoint(x: rightX, y: topY + r)
        )

        // Inner-right pinch curve
        p.addCurve(
            to: CGPoint(x: rightX - innerInset, y: midY),
            control1: CGPoint(x: rightX, y: midY * 0.75),
            control2: CGPoint(x: rightX - innerInset * 0.6, y: midY * 0.9)
        )

        // Bottom-right curve
        p.addCurve(
            to: CGPoint(x: w * 0.5, y: bottomY),
            control1: CGPoint(x: rightX - outerInset, y: midY + r),
            control2: CGPoint(x: w * 0.82, y: bottomY)
        )

        // Bottom-left curve
        p.addCurve(
            to: CGPoint(x: leftX + innerInset, y: midY),
            control1: CGPoint(x: w * 0.18, y: bottomY),
            control2: CGPoint(x: leftX + outerInset, y: midY + r)
        )

        // Inner-left pinch curve
        p.addCurve(
            to: CGPoint(x: leftX, y: midY * 0.55),
            control1: CGPoint(x: leftX + innerInset * 0.6, y: midY * 0.9),
            control2: CGPoint(x: leftX, y: midY * 0.75)
        )

        // Top-left curve back to start
        p.addCurve(
            to: CGPoint(x: w * 0.5, y: topY),
            control1: CGPoint(x: leftX, y: topY + r),
            control2: CGPoint(x: w * 0.18, y: topY)
        )

        p.closeSubpath()
        return p
    }
}

private struct MorphingEyeShape: Shape {
    var style: EyeStyle
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let useHighQualitySore = (style == .v2 && progress <= 1.0)
        let data = MorphingEyeData.shared(for: style, highQualitySore: useHighQualitySore)
        let ref = data.referenceSize

        let t = max(0, min(2, progress))
        // V2: open->sore morph only; closed is a separate pill
        let tClamped = style == .v2 ? min(t, 1.0) : t
        let (a, b, localT) = data.segment(for: tClamped)

        var points = data.interpolate(from: a, to: b, t: localT)
        if style == .v2 {
            points = MorphingEyeShape.normalizeWidth(points, targetWidth: ref.width)
        }
        let sx = rect.width / ref.width
        let sy = rect.height / ref.height

        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: CGPoint(x: first.x * sx + rect.minX, y: first.y * sy + rect.minY))
        for p in points.dropFirst() {
            path.addLine(to: CGPoint(x: p.x * sx + rect.minX, y: p.y * sy + rect.minY))
        }
        path.closeSubpath()
        return path
    }

    private static func normalizeWidth(_ points: [CGPoint], targetWidth: CGFloat) -> [CGPoint] {
        guard let minX = points.map({ $0.x }).min(),
              let maxX = points.map({ $0.x }).max(),
              maxX > minX
        else { return points }

        let currentWidth = maxX - minX
        let scaleX = targetWidth / currentWidth
        let centerX = (minX + maxX) * 0.5
        let targetCenterX = targetWidth * 0.5

        return points.map { p in
            let x = (p.x - centerX) * scaleX + targetCenterX
            return CGPoint(x: x, y: p.y)
        }
    }
}

private final class MorphingEyeData {
    static let sharedV1 = MorphingEyeData(definition: .v1)
    static let sharedV2 = MorphingEyeData(definition: .v2)
    static let sharedV2High = MorphingEyeData(definition: .v2High)

    let referenceSize: CGSize
    let openPoints: [CGPoint]
    let sorePoints: [CGPoint]
    let closedPoints: [CGPoint]

    private init(definition: EyeStyleDefinition) {
        referenceSize = definition.referenceSize
        openPoints = MorphingEyeData.makePoints(
            path: definition.openPath(),
            viewBox: definition.openViewBox,
            reference: definition.referenceSize,
            sampleCount: definition.sampleCount,
            smoothPasses: definition.smoothPasses
        )
        sorePoints = MorphingEyeData.makePoints(
            path: definition.sorePath(),
            viewBox: definition.soreViewBox,
            reference: definition.referenceSize,
            sampleCount: definition.sampleCount,
            smoothPasses: definition.smoothPasses
        )
        closedPoints = MorphingEyeData.makePoints(
            path: definition.closedPath(),
            viewBox: definition.closedViewBox,
            reference: definition.referenceSize,
            sampleCount: definition.sampleCount,
            smoothPasses: definition.smoothPasses
        )
    }

    static func shared(for style: EyeStyle, highQualitySore: Bool) -> MorphingEyeData {
        switch style {
        case .v1:
            return sharedV1
        case .v2:
            return highQualitySore ? sharedV2High : sharedV2
        }
    }

    func segment(for t: CGFloat) -> ([CGPoint], [CGPoint], CGFloat) {
        if t < 1 {
            return (openPoints, sorePoints, t)
        } else {
            return (sorePoints, closedPoints, t - 1)
        }
    }

    func interpolate(from a: [CGPoint], to b: [CGPoint], t: CGFloat) -> [CGPoint] {
        let clamped = max(0, min(1, t))
        return zip(a, b).map { p1, p2 in
            CGPoint(
                x: p1.x + (p2.x - p1.x) * clamped,
                y: p1.y + (p2.y - p1.y) * clamped
            )
        }
    }

    private static func makePoints(
        path: Path,
        viewBox: CGSize,
        reference: CGSize,
        sampleCount: Int,
        smoothPasses: Int
    ) -> [CGPoint] {
        let polyline = sample(path: path, segmentsPerCurve: 20)
        let resampled = resample(polyline, count: sampleCount)

        let offsetX = (reference.width - viewBox.width) / 2.0
        let offsetY = (reference.height - viewBox.height) / 2.0

        let shifted = resampled.map { pt in
            CGPoint(x: pt.x + offsetX, y: pt.y + offsetY)
        }
        return smoothPasses > 0 ? smooth(shifted, passes: smoothPasses) : shifted
    }

    private static func sample(path: Path, segmentsPerCurve: Int) -> [CGPoint] {
        var points: [CGPoint] = []
        var current = CGPoint.zero
        var start = CGPoint.zero

        path.cgPath.applyWithBlock { element in
            let type = element.pointee.type
            let pts = element.pointee.points

            switch type {
            case .moveToPoint:
                current = pts[0]
                start = current
                points.append(current)
            case .addLineToPoint:
                current = pts[0]
                points.append(current)
            case .addQuadCurveToPoint:
                let c1 = pts[0]
                let end = pts[1]
                for i in 1...segmentsPerCurve {
                    let t = CGFloat(i) / CGFloat(segmentsPerCurve)
                    let p = quadBezier(p0: current, p1: c1, p2: end, t: t)
                    points.append(p)
                }
                current = end
            case .addCurveToPoint:
                let c1 = pts[0]
                let c2 = pts[1]
                let end = pts[2]
                for i in 1...segmentsPerCurve {
                    let t = CGFloat(i) / CGFloat(segmentsPerCurve)
                    let p = cubicBezier(p0: current, p1: c1, p2: c2, p3: end, t: t)
                    points.append(p)
                }
                current = end
            case .closeSubpath:
                current = start
                points.append(start)
            @unknown default:
                break
            }
        }

        return points
    }

    private static func resample(_ points: [CGPoint], count: Int) -> [CGPoint] {
        guard points.count > 1 else { return points }

        var distances: [CGFloat] = [0]
        var total: CGFloat = 0
        for i in 1..<points.count {
            let d = hypot(points[i].x - points[i - 1].x, points[i].y - points[i - 1].y)
            total += d
            distances.append(total)
        }
        let step = total / CGFloat(count)
        var result: [CGPoint] = []
        var target: CGFloat = 0
        var i = 1
        for _ in 0..<count {
            while i < distances.count && distances[i] < target {
                i += 1
            }
            if i >= distances.count {
                result.append(points.last ?? .zero)
                target += step
                continue
            }
            let prevDist = distances[i - 1]
            let nextDist = distances[i]
            let t = nextDist == prevDist ? 0 : (target - prevDist) / (nextDist - prevDist)
            let p0 = points[i - 1]
            let p1 = points[i]
            let x = p0.x + (p1.x - p0.x) * t
            let y = p0.y + (p1.y - p0.y) * t
            result.append(CGPoint(x: x, y: y))
            target += step
        }
        return result
    }

    private static func smooth(_ points: [CGPoint], passes: Int) -> [CGPoint] {
        guard points.count > 2 else { return points }
        var current = points
        for _ in 0..<passes {
            var next = current
            for i in 1..<(current.count - 1) {
                let p0 = current[i - 1]
                let p1 = current[i]
                let p2 = current[i + 1]
                next[i] = CGPoint(
                    x: (p0.x + p1.x + p2.x) / 3.0,
                    y: (p0.y + p1.y + p2.y) / 3.0
                )
            }
            current = next
        }
        return current
    }

    private static func quadBezier(p0: CGPoint, p1: CGPoint, p2: CGPoint, t: CGFloat) -> CGPoint {
        let u = 1 - t
        let x = u * u * p0.x + 2 * u * t * p1.x + t * t * p2.x
        let y = u * u * p0.y + 2 * u * t * p1.y + t * t * p2.y
        return CGPoint(x: x, y: y)
    }

    private static func cubicBezier(p0: CGPoint, p1: CGPoint, p2: CGPoint, p3: CGPoint, t: CGFloat) -> CGPoint {
        let u = 1 - t
        let x = u * u * u * p0.x
            + 3 * u * u * t * p1.x
            + 3 * u * t * t * p2.x
            + t * t * t * p3.x
        let y = u * u * u * p0.y
            + 3 * u * u * t * p1.y
            + 3 * u * t * t * p2.y
            + t * t * t * p3.y
        return CGPoint(x: x, y: y)
    }
}

private enum PathsV1 {
    static func open() -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 37.3148, y: 19.0239))
        path.addCurve(
            to: CGPoint(x: 19.8924, y: 0.0),
            control1: CGPoint(x: 38.2151, y: 8.79862),
            control2: CGPoint(x: 30.1572, y: 0.0)
        )
        path.addLine(to: CGPoint(x: 17.3552, y: 0.0))
        path.addCurve(
            to: CGPoint(x: 0.59192, y: 15.1376),
            control1: CGPoint(x: 8.71219, y: 0.0),
            control2: CGPoint(x: 1.47058, y: 6.53929)
        )
        path.addCurve(
            to: CGPoint(x: 0.325774, y: 35.372),
            control1: CGPoint(x: -0.0951715, y: 21.8612),
            control2: CGPoint(x: -0.184236, y: 28.6326)
        )
        path.addLine(to: CGPoint(x: 0.860387, y: 42.4366))
        path.addCurve(
            to: CGPoint(x: 19.243, y: 59.3302),
            control1: CGPoint(x: 1.58154, y: 51.9661),
            control2: CGPoint(x: 9.68629, y: 59.3302)
        )
        path.addCurve(
            to: CGPoint(x: 37.3008, y: 39.6648),
            control1: CGPoint(x: 29.7635, y: 59.3302),
            control2: CGPoint(x: 38.2011, y: 50.1467)
        )
        path.addCurve(
            to: CGPoint(x: 37.3148, y: 19.0239),
            control1: CGPoint(x: 36.7136, y: 32.828),
            control2: CGPoint(x: 36.7129, y: 25.8594)
        )
        path.closeSubpath()
        return path
    }

    static func sore() -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 36.5021, y: 13.6311))
        path.addCurve(
            to: CGPoint(x: 22.8253, y: 0.23034),
            control1: CGPoint(x: 37.9369, y: 5.59346),
            control2: CGPoint(x: 30.8321, y: -1.36799)
        )
        path.addLine(to: CGPoint(x: 14.4286, y: 1.91526))
        path.addCurve(
            to: CGPoint(x: 0.662551, y: 16.8745),
            control1: CGPoint(x: 7.08179, y: 3.38948),
            control2: CGPoint(x: 1.52238, y: 9.43076)
        )
        path.addLine(to: CGPoint(x: 0.338409, y: 19.6806))
        path.addCurve(
            to: CGPoint(x: 0.758876, y: 34.3434),
            control1: CGPoint(x: -0.225569, y: 24.5631),
            control2: CGPoint(x: -0.0839618, y: 29.5013)
        )
        path.addCurve(
            to: CGPoint(x: 16.3936, y: 44.2633),
            control1: CGPoint(x: 2.02447, y: 41.6143),
            control2: CGPoint(x: 9.27628, y: 46.2154)
        )
        path.addCurve(
            to: CGPoint(x: 16.8214, y: 44.146),
            control1: CGPoint(x: 16.3936, y: 44.2633),
            control2: CGPoint(x: 16.8214, y: 44.146)
        )
        path.addCurve(
            to: CGPoint(x: 24.028, y: 43.4581),
            control1: CGPoint(x: 19.166, y: 43.5029),
            control2: CGPoint(x: 21.6041, y: 43.2702)
        )
        path.addCurve(
            to: CGPoint(x: 24.3927, y: 43.4864),
            control1: CGPoint(x: 24.028, y: 43.4581),
            control2: CGPoint(x: 24.3927, y: 43.4864)
        )
        path.addCurve(
            to: CGPoint(x: 36.1373, y: 30.6493),
            control1: CGPoint(x: 31.5492, y: 44.0411),
            control2: CGPoint(x: 37.3247, y: 37.7283)
        )
        path.addCurve(
            to: CGPoint(x: 36.2179, y: 15.2231),
            control1: CGPoint(x: 35.2804, y: 25.5406),
            control2: CGPoint(x: 35.3076, y: 20.3226)
        )
        path.addLine(to: CGPoint(x: 36.5021, y: 13.6311))
        path.closeSubpath()
        return path
    }

    static func closed() -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 38.4631, y: 2.02484))
        path.addCurve(
            to: CGPoint(x: 35.9152, y: 0.399206),
            control1: CGPoint(x: 38.3105, y: 0.804466),
            control2: CGPoint(x: 37.0862, y: 0.0233096)
        )
        path.addLine(to: CGPoint(x: 33.7234, y: 1.10276))
        path.addCurve(
            to: CGPoint(x: 5.23225, y: 1.10276),
            control1: CGPoint(x: 24.4592, y: 4.07659),
            control2: CGPoint(x: 14.4965, y: 4.07659)
        )
        path.addLine(to: CGPoint(x: 1.98529, y: 0.0604869))
        path.addCurve(
            to: CGPoint(x: 0.403442, y: 0.875293),
            control1: CGPoint(x: 1.32341, y: -0.151974),
            control2: CGPoint(x: 0.614756, y: 0.213056)
        )
        path.addCurve(
            to: CGPoint(x: 0.251044, y: 5.51908),
            control1: CGPoint(x: -0.0764534, y: 2.37923),
            control2: CGPoint(x: -0.129213, y: 3.98691)
        )
        path.addLine(to: CGPoint(x: 0.535072, y: 6.66351))
        path.addCurve(
            to: CGPoint(x: 1.77915, y: 7.99432),
            control1: CGPoint(x: 0.69122, y: 7.29268),
            control2: CGPoint(x: 1.16191, y: 7.79618)
        )
        path.addLine(to: CGPoint(x: 3.43505, y: 8.52586))
        path.addCurve(
            to: CGPoint(x: 35.5206, y: 8.52586),
            control1: CGPoint(x: 13.8681, y: 11.8749),
            control2: CGPoint(x: 25.0876, y: 11.8749)
        )
        path.addLine(to: CGPoint(x: 36.5209, y: 8.20478))
        path.addCurve(
            to: CGPoint(x: 38.3842, y: 5.95756),
            control1: CGPoint(x: 37.5263, y: 7.88204),
            control2: CGPoint(x: 38.2532, y: 7.00536)
        )
        path.addLine(to: CGPoint(x: 38.4631, y: 5.32636))
        path.addCurve(
            to: CGPoint(x: 38.4631, y: 2.02484),
            control1: CGPoint(x: 38.6001, y: 4.23012),
            control2: CGPoint(x: 38.6001, y: 3.12108)
        )
        path.closeSubpath()
        return path
    }
}

private enum PathsV2 {
    static func open() -> Path {
        var path = Path()
        path.addRoundedRect(in: CGRect(x: 0, y: 0, width: 40, height: 60), cornerSize: CGSize(width: 19, height: 19))
        return path
    }

    static func sore() -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 25.5328))
        path.addCurve(
            to: CGPoint(x: 0.527787, y: 15.5885),
            control1: CGPoint(x: 0, y: 20.3648),
            control2: CGPoint(x: 0, y: 17.7808)
        )
        path.addCurve(
            to: CGPoint(x: 12.4789, y: 2.18981),
            control1: CGPoint(x: 2.01694, y: 9.40304),
            control2: CGPoint(x: 6.50315, y: 4.37343)
        )
        path.addCurve(
            to: CGPoint(x: 22.2984, y: 0.533415),
            control1: CGPoint(x: 14.5968, y: 1.41589),
            control2: CGPoint(x: 17.164, y: 1.12173)
        )
        path.addCurve(
            to: CGPoint(x: 29.902, y: 0.110327),
            control1: CGPoint(x: 26.2815, y: 0.0770219),
            control2: CGPoint(x: 28.273, y: -0.151175)
        )
        path.addCurve(
            to: CGPoint(x: 39.5548, y: 8.72018),
            control1: CGPoint(x: 34.5234, y: 0.852196),
            control2: CGPoint(x: 38.2916, y: 4.21334)
        )
        path.addCurve(
            to: CGPoint(x: 40, y: 16.3225),
            control1: CGPoint(x: 40, y: 10.3088),
            control2: CGPoint(x: 40, y: 12.3134)
        )
        path.addLine(to: CGPoint(x: 40, y: 33.5051))
        path.addCurve(
            to: CGPoint(x: 39.9838, y: 35.2903),
            control1: CGPoint(x: 40, y: 34.4336),
            control2: CGPoint(x: 40, y: 34.8979)
        )
        path.addCurve(
            to: CGPoint(x: 21.7852, y: 53.4889),
            control1: CGPoint(x: 39.5753, y: 45.1669),
            control2: CGPoint(x: 31.6618, y: 53.0804)
        )
        path.addCurve(
            to: CGPoint(x: 20, y: 53.5051),
            control1: CGPoint(x: 21.3928, y: 53.5051),
            control2: CGPoint(x: 20.9285, y: 53.5051)
        )
        path.addCurve(
            to: CGPoint(x: 18.2148, y: 53.4889),
            control1: CGPoint(x: 19.0715, y: 53.5051),
            control2: CGPoint(x: 18.6072, y: 53.5051)
        )
        path.addCurve(
            to: CGPoint(x: 0.0162306, y: 35.2903),
            control1: CGPoint(x: 8.33817, y: 53.0804),
            control2: CGPoint(x: 0.424732, y: 45.1669)
        )
        path.addCurve(
            to: CGPoint(x: 0, y: 33.5051),
            control1: CGPoint(x: 0, y: 34.8979),
            control2: CGPoint(x: 0, y: 34.4336)
        )
        path.addLine(to: CGPoint(x: 0, y: 25.5328))
        path.closeSubpath()
        return path
    }

    static func closed() -> Path {
        var path = Path()
        path.addRoundedRect(in: CGRect(x: 0, y: 0, width: 40, height: 8), cornerSize: CGSize(width: 4, height: 4))
        return path
    }
}

private enum EyeStyle: String {
    case v1
    case v2

    var referenceSize: CGSize {
        switch self {
        case .v1:
            return CGSize(width: 38, height: 60)
        case .v2:
            return CGSize(width: 40, height: 60)
        }
    }
}

private struct EyeStyleDefinition {
    let referenceSize: CGSize
    let openViewBox: CGSize
    let soreViewBox: CGSize
    let closedViewBox: CGSize
    let sampleCount: Int
    let smoothPasses: Int
    let openPath: () -> Path
    let sorePath: () -> Path
    let closedPath: () -> Path

    static let v1 = EyeStyleDefinition(
        referenceSize: CGSize(width: 38, height: 60),
        openViewBox: CGSize(width: 38, height: 60),
        soreViewBox: CGSize(width: 37, height: 45),
        closedViewBox: CGSize(width: 39, height: 12),
        sampleCount: 140,
        smoothPasses: 0,
        openPath: { PathsV1.open() },
        sorePath: { PathsV1.sore() },
        closedPath: { PathsV1.closed() }
    )

    static let v2 = EyeStyleDefinition(
        referenceSize: CGSize(width: 40, height: 60),
        openViewBox: CGSize(width: 40, height: 60),
        soreViewBox: CGSize(width: 40, height: 54),
        closedViewBox: CGSize(width: 40, height: 8),
        sampleCount: 240,
        smoothPasses: 2,
        openPath: { PathsV2.open() },
        sorePath: { PathsV2.sore() },
        closedPath: { PathsV2.closed() }
    )

    // Higher quality sampling for sore morph to reduce jitter
    static let v2High = EyeStyleDefinition(
        referenceSize: CGSize(width: 40, height: 60),
        openViewBox: CGSize(width: 40, height: 60),
        soreViewBox: CGSize(width: 40, height: 54),
        closedViewBox: CGSize(width: 40, height: 8),
        sampleCount: 360,
        smoothPasses: 4,
        openPath: { PathsV2.open() },
        sorePath: { PathsV2.sore() },
        closedPath: { PathsV2.closed() }
    )
}

//Preview//
#Preview {
    struct PreviewWrapper: View {
        @StateObject private var model = BlinkModel()

        var body: some View {
            EyesView(model: model)
                .frame(width: 190, height: 80)
                .padding()
                .background(Color.black)
                .task {
                    model.opacity = 1.0
                    // Preview-safe: run a few times instead of infinite loop
                    for _ in 0..<3 {
                        if Task.isCancelled { break }
                        await model.playOnce()
                        try? await Task.sleep(nanoseconds: 800_000_000)
                    }
                }
        }
    }

    return PreviewWrapper()
}

