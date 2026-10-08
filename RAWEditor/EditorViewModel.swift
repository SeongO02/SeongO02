import SwiftUI
import Photos

@MainActor
final class EditorViewModel: ObservableObject {
    @Published var settings = EditSettings()
    @Published var previewImage: UIImage?
    @Published var showOriginal = false
    @Published var isBusy = false
    @Published var message: String?
    @Published private(set) var fileName = ""

    private var processor: RAWProcessor?
    private var baseline = EditSettings()
    private var renderTask: Task<Void, Never>?

    var hasImage: Bool { processor != nil }

    func load(data: Data, fileName: String) async {
        isBusy = true
        defer { isBusy = false }
        let ext = (fileName as NSString).pathExtension
        guard let p = RAWProcessor(data: data, hint: ext.isEmpty ? nil : ext) else {
            message = "이 파일은 RAW로 읽을 수 없어요."
            return
        }
        processor = p
        self.fileName = fileName
        var initial = EditSettings()
        initial.temperature = await p.defaultTemperature
        initial.tint = await p.defaultTint
        baseline = initial
        settings = initial
        showOriginal = false
        rerender()
    }

    /// 슬라이더가 움직일 때마다 호출. 이전 렌더는 취소하고 최신 값만 그린다.
    func rerender() {
        guard let processor else { return }
        let target = showOriginal ? baseline : settings
        renderTask?.cancel()
        renderTask = Task {
            let cg = await processor.renderPreview(target)
            guard !Task.isCancelled, let cg else { return }
            previewImage = UIImage(cgImage: cg)
        }
    }

    func reset(_ adjustment: Adjustment) {
        settings[keyPath: adjustment.keyPath] = baseline[keyPath: adjustment.keyPath]
    }

    func resetAll() { settings = baseline }

    func saveToPhotos(heic: Bool) async {
        guard let processor else { return }
        isBusy = true
        defer { isBusy = false }

        guard await PHPhotoLibrary.requestAuthorization(for: .addOnly) != .denied,
              let data = await processor.export(settings, heic: heic) else {
            message = "저장에 실패했어요. 사진 접근 권한을 확인해 주세요."
            return
        }
        do {
            try await PHPhotoLibrary.shared().performChanges {
                let request = PHAssetCreationRequest.forAsset()
                request.addResource(with: .photo, data: data, options: nil)
            }
            message = "사진 보관함에 저장했어요."
        } catch {
            message = "저장 실패: \(error.localizedDescription)"
        }
    }
}
