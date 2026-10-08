import CoreImage
import CoreImage.CIFilterBuiltins

/// RAW 디코딩(CIRAWFilter) + 보정 필터 체인. GPU(Metal) 기반 CIContext로 렌더링한다.
/// Sony ARW, iPhone ProRAW(DNG) 등 iOS가 지원하는 RAW 포맷을 읽는다.
actor RAWProcessor {
    private let rawFilter: CIRAWFilter
    private let context: CIContext
    private let outputColorSpace = CGColorSpace(name: CGColorSpace.displayP3)!

    /// RAW 파일이 기록한 촬영 당시 화이트밸런스 (슬라이더 초기값)
    let defaultTemperature: Float
    let defaultTint: Float
    let nativeSize: CGSize

    init?(data: Data, hint: String?) {
        guard let filter = CIRAWFilter(imageData: data, identifierHint: hint) else { return nil }
        rawFilter = filter
        context = CIContext(options: [.workingColorSpace: CGColorSpace(name: CGColorSpace.extendedLinearDisplayP3)!])
        defaultTemperature = filter.neutralTemperature
        defaultTint = filter.neutralTint
        nativeSize = filter.nativeSize
    }

    /// 미리보기: 긴 변을 `maxDimension`으로 줄여 빠르게 렌더링.
    func renderPreview(_ s: EditSettings, maxDimension: CGFloat = 1600) -> CGImage? {
        let longEdge = max(nativeSize.width, nativeSize.height)
        let scale = min(1, maxDimension / max(longEdge, 1))
        guard let image = build(s, scale: scale) else { return nil }
        return context.createCGImage(image, from: image.extent, format: .RGBA8, colorSpace: outputColorSpace)
    }

    /// 내보내기: 원본 해상도 JPEG/HEIC 데이터.
    func export(_ s: EditSettings, heic: Bool) -> Data? {
        guard let image = build(s, scale: 1) else { return nil }
        if heic {
            return context.heifRepresentation(of: image, format: .RGBA8, colorSpace: outputColorSpace, options: [:])
        }
        return context.jpegRepresentation(of: image, colorSpace: outputColorSpace,
                                          options: [kCGImageDestinationLossyCompressionQuality as CIImageRepresentationOption: 0.95])
    }

    private func build(_ s: EditSettings, scale: CGFloat) -> CIImage? {
        rawFilter.scaleFactor = Float(scale)
        rawFilter.exposure = s.exposure
        rawFilter.neutralTemperature = s.temperature
        rawFilter.neutralTint = s.tint
        rawFilter.sharpnessAmount = s.sharpness
        rawFilter.luminanceNoiseReductionAmount = s.noiseReduction
        rawFilter.colorNoiseReductionAmount = s.noiseReduction

        guard var image = rawFilter.outputImage else { return nil }

        let hs = CIFilter.highlightShadowAdjust()
        hs.inputImage = image
        hs.highlightAmount = 1 - s.highlights
        hs.shadowAmount = s.shadows
        image = hs.outputImage ?? image

        let cc = CIFilter.colorControls()
        cc.inputImage = image
        cc.contrast = s.contrast
        cc.saturation = s.saturation
        image = cc.outputImage ?? image

        if s.vibrance != 0 {
            let v = CIFilter.vibrance()
            v.inputImage = image
            v.amount = s.vibrance
            image = v.outputImage ?? image
        }
        return image
    }
}
