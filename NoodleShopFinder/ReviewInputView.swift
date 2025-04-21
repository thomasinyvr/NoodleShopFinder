import SwiftUI
import PhotosUI
import AVFoundation

struct ReviewInputView: View {
    let title: String
    let isPublic: Bool
    let onSubmit: (ReviewContent) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedMedia: PhotosPickerItem?
    @State private var mediaPreview: MediaPreview?
    @State private var reviewText = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isRecording = false
    @State private var showCamera = false
    
    private let maxCharacters = 400
    private let maxVideoDuration: TimeInterval = 30
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Add Media")) {
                    HStack(spacing: 20) {
                        PhotosPicker(selection: $selectedMedia, matching: .any(of: [.images, .videos])) {
                            Label("Photo/Video", systemImage: "photo.on.rectangle")
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action: { showCamera = true }) {
                            Label("Camera", systemImage: "camera")
                        }
                        .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                    
                    if let preview = mediaPreview {
                        preview
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                
                Section(header: Text("Review")) {
                    TextEditor(text: $reviewText)
                        .frame(height: 100)
                        .overlay(
                            Text("\(reviewText.count)/\(maxCharacters)")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(8),
                            alignment: .bottomTrailing
                        )
                }
                
                Section {
                    Button(action: submit) {
                        HStack {
                            Spacer()
                            Text("Submit")
                            Spacer()
                        }
                    }
                    .disabled(reviewText.isEmpty && mediaPreview == nil)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .onChange(of: selectedMedia) { _, newItem in
                Task {
                    if let item = newItem {
                        await loadMedia(from: item)
                    }
                }
            }
            .sheet(isPresented: $showCamera) {
                CameraView { result in
                    switch result {
                    case .success(let url):
                        mediaPreview = .video(url)
                    case .failure(let error):
                        errorMessage = error.localizedDescription
                        showError = true
                    }
                }
            }
        }
    }
    
    private func loadMedia(from item: PhotosPickerItem) async {
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                if item.supportedContentTypes.contains(.image) {
                    if let image = UIImage(data: data) {
                        mediaPreview = .image(image)
                    }
                } else if item.supportedContentTypes.contains(.movie) {
                    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mov")
                    try data.write(to: tempURL)
                    
                    let asset = AVAsset(url: tempURL)
                    let duration = try await asset.load(.duration)
                    
                    if duration.seconds > maxVideoDuration {
                        errorMessage = "Video must be less than 30 seconds"
                        showError = true
                        return
                    }
                    
                    mediaPreview = .video(tempURL)
                }
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func submit() {
        let content = ReviewContent(
            text: reviewText,
            media: mediaPreview,
            isPublic: isPublic
        )
        onSubmit(content)
        dismiss()
    }
}

enum MediaPreview {
    case image(UIImage)
    case video(URL)
    
    var body: some View {
        switch self {
        case .image(let image):
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
        case .video(let url):
            VideoPlayer(url: url)
                .aspectRatio(contentMode: .fit)
        }
    }
}

struct ReviewContent {
    let text: String
    let media: MediaPreview?
    let isPublic: Bool
}

struct CameraView: UIViewControllerRepresentable {
    let onResult: (Result<URL, Error>) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.mediaTypes = ["public.movie"]
        picker.videoMaximumDuration = 30
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onResult: onResult)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onResult: (Result<URL, Error>) -> Void
        
        init(onResult: @escaping (Result<URL, Error>) -> Void) {
            self.onResult = onResult
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let url = info[.mediaURL] as? URL {
                onResult(.success(url))
            } else {
                onResult(.failure(NSError(domain: "CameraView", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to capture video"])))
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
} 