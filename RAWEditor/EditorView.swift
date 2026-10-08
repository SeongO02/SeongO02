import SwiftUI

struct EditorView: View {
    @ObservedObject var vm: EditorViewModel

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Color.black
                if let image = vm.previewImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                }
            }
            .frame(maxHeight: .infinity)
            // 길게 누르는 동안 원본(촬영 당시 값)을 보여준다
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in if !vm.showOriginal { vm.showOriginal = true } }
                    .onEnded { _ in vm.showOriginal = false }
            )

            controls
        }
        .onChange(of: vm.settings) { _ in vm.rerender() }
        .onChange(of: vm.showOriginal) { _ in vm.rerender() }
    }

    private var controls: some View {
        VStack(spacing: 0) {
            HStack {
                Text("이미지를 누르고 있으면 원본").font(.caption).foregroundStyle(.secondary)
                Spacer()
                Button("전체 초기화") { vm.resetAll() }.font(.caption)
            }
            .padding(.horizontal).padding(.vertical, 8)

            ScrollView {
                VStack(spacing: 14) {
                    ForEach(Adjustment.allCases) { adj in
                        VStack(spacing: 2) {
                            HStack {
                                Text(adj.title).font(.subheadline)
                                    .onTapGesture(count: 2) { vm.reset(adj) }
                                Spacer()
                                Text(adj.display(vm.settings[keyPath: adj.keyPath]))
                                    .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                            }
                            Slider(value: Binding(
                                get: { vm.settings[keyPath: adj.keyPath] },
                                set: { vm.settings[keyPath: adj.keyPath] = $0 }
                            ), in: adj.range)
                        }
                    }
                }
                .padding(.horizontal).padding(.bottom, 16)
            }
            .frame(height: 260)
        }
        .background(.ultraThinMaterial)
    }
}
