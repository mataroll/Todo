import SwiftUI
import UniformTypeIdentifiers

struct FilePicker: UIViewControllerRepresentable {
    let onPick: (URL, String) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf, .image, .text, .data])
        picker.allowsMultipleSelection = true
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ vc: UIDocumentPickerViewController, context: Context) {}

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL, String) -> Void
        init(onPick: @escaping (URL, String) -> Void) { self.onPick = onPick }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            for url in urls {
                guard url.startAccessingSecurityScopedResource() else { continue }
                defer { url.stopAccessingSecurityScopedResource() }
                let name = UUID().uuidString + "_" + url.lastPathComponent
                let dest = docs.appendingPathComponent(name)
                try? FileManager.default.copyItem(at: url, to: dest)
                DispatchQueue.main.async { self.onPick(dest, name) }
            }
        }
    }
}
