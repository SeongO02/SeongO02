import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var vm = EditorViewModel()
    @State private var pickerItem: PhotosPickerItem?
    @State private var showFileImporter = false

    var body: some View {
        NavigationStack {
            Group {
                if vm.hasImage {
                    EditorView(vm: vm)
                } else {
                    emptyState
                }
            }
            .navigationTitle(vm.hasImage ? vm.fileName : "RAW Editor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if vm.hasImage {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Menu {
                            PhotosPicker("사진 앱에서 열기", selection: $pickerItem, matching: .images)
                            Button("파일 앱에서 열기") { showFileImporter = true }
                        } label: { Image(systemName: "plus") }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button("JPEG로 저장") { Task { await vm.saveToPhotos(heic: false) } }
                            Button("HEIC로 저장") { Task { await vm.saveToPhotos(heic: true) } }
                        } label: { Image(systemName: "square.and.arrow.up") }
                    }
                }
            }
        }
        .overlay { if vm.isBusy { ProgressView().controlSize(.large).padding().background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12)) } }
        .alert("알림", isPresented: Binding(get: { vm.message != nil }, set: { if !$0 { vm.message = nil } })) {
            Button("확인", role: .cancel) {}
        } message: { Text(vm.message ?? "") }
        .onChange(of: pickerItem) { item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    await vm.load(data: data, fileName: "photo.dng")
                } else {
                    vm.message = "사진을 불러오지 못했어요."
                }
                pickerItem = nil
            }
        }
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.rawImage, .image]) { result in
            guard case .success(let url) = result else { return }
            Task {
                let scoped = url.startAccessingSecurityScopedResource()
                defer { if scoped { url.stopAccessingSecurityScopedResource() } }
                if let data = try? Data(contentsOf: url) {
                    await vm.load(data: data, fileName: url.lastPathComponent)
                } else {
                    vm.message = "파일을 읽지 못했어요."
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.aperture").font(.system(size: 56)).foregroundStyle(.secondary)
            Text("RAW 사진을 불러오세요").font(.headline)
            PhotosPicker(selection: $pickerItem, matching: .images) {
                Label("사진 앱에서 (iPhone ProRAW)", systemImage: "photo.on.rectangle")
                    .frame(maxWidth: 280)
            }.buttonStyle(.borderedProminent)
            Button { showFileImporter = true } label: {
                Label("파일 앱에서 (Sony ARW 등)", systemImage: "folder").frame(maxWidth: 280)
            }.buttonStyle(.bordered)
        }
    }
}
