import Foundation

/// 편집 슬라이더 값 모음. 값이 바뀌면 미리보기를 다시 렌더링한다.
struct EditSettings: Equatable {
    var exposure: Float = 0          // EV, -3...3
    var temperature: Float = 6500    // K (로드 시 RAW의 값으로 초기화)
    var tint: Float = 0              // -150...150
    var contrast: Float = 1          // 0.5...1.5
    var highlights: Float = 0        // 0...1 (하이라이트 복구량)
    var shadows: Float = 0           // -1...1
    var saturation: Float = 1        // 0...2
    var vibrance: Float = 0          // -1...1
    var sharpness: Float = 0.4       // 0...2
    var noiseReduction: Float = 0    // 0...1
}

/// 슬라이더 한 줄에 해당하는 항목.
enum Adjustment: String, CaseIterable, Identifiable {
    case exposure, temperature, tint, contrast, highlights, shadows
    case saturation, vibrance, sharpness, noiseReduction

    var id: String { rawValue }

    var title: String {
        switch self {
        case .exposure: return "노출"
        case .temperature: return "색온도"
        case .tint: return "색조"
        case .contrast: return "대비"
        case .highlights: return "하이라이트 복구"
        case .shadows: return "섀도"
        case .saturation: return "채도"
        case .vibrance: return "생동감"
        case .sharpness: return "선명도"
        case .noiseReduction: return "노이즈 감소"
        }
    }

    var range: ClosedRange<Float> {
        switch self {
        case .exposure: return -3...3
        case .temperature: return 2000...12000
        case .tint: return -150...150
        case .contrast: return 0.5...1.5
        case .highlights: return 0...1
        case .shadows: return -1...1
        case .saturation: return 0...2
        case .vibrance: return -1...1
        case .sharpness: return 0...2
        case .noiseReduction: return 0...1
        }
    }

    var keyPath: WritableKeyPath<EditSettings, Float> {
        switch self {
        case .exposure: return \.exposure
        case .temperature: return \.temperature
        case .tint: return \.tint
        case .contrast: return \.contrast
        case .highlights: return \.highlights
        case .shadows: return \.shadows
        case .saturation: return \.saturation
        case .vibrance: return \.vibrance
        case .sharpness: return \.sharpness
        case .noiseReduction: return \.noiseReduction
        }
    }

    func display(_ value: Float) -> String {
        switch self {
        case .temperature: return "\(Int(value))K"
        case .tint: return String(format: "%.0f", value)
        default: return String(format: "%.2f", value)
        }
    }
}
