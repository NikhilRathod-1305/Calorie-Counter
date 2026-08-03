import SwiftUI
import AVFoundation
import Photos

/// Live embedded camera controller for meal photo capture, shown inline in
/// the scan card rather than pushing to a separate full-screen camera flow.
final class MealCameraController: UIViewController, AVCapturePhotoCaptureDelegate {
    var onCapture: ((UIImage) -> Void)?
    private let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer?

    static var isAvailable: Bool {
        AVCaptureDevice.default(for: .video) != nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        configureSession()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    private func configureSession() {
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else { return }
        session.beginConfiguration()
        session.sessionPreset = .photo
        session.addInput(input)

        guard session.canAddOutput(photoOutput) else {
            session.commitConfiguration()
            return
        }
        session.addOutput(photoOutput)
        session.commitConfiguration()

        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        layer.frame = view.bounds
        view.layer.addSublayer(layer)
        previewLayer = layer

        DispatchQueue.global(qos: .userInitiated).async { [session] in
            session.startRunning()
        }
    }

    func capturePhoto() {
        var settings = AVCapturePhotoSettings()
        if photoOutput.availablePhotoCodecTypes.contains(.jpeg) {
            settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        }
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil,
              let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else { return }
        onCapture?(image)
    }

    deinit {
        session.stopRunning()
    }
}

private struct MealCameraRepresentable: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void
    @Binding var controller: MealCameraController?

    func makeUIViewController(context: Context) -> MealCameraController {
        let vc = MealCameraController()
        vc.onCapture = onCapture
        DispatchQueue.main.async { controller = vc }
        return vc
    }

    func updateUIViewController(_ uiViewController: MealCameraController, context: Context) {}
}

/// SwiftUI wrapper pairing the live preview with a shutter button, so
/// `LogFoodSheet` can embed one self-contained capture control.
struct MealCameraCaptureControl: View {
    let onCapture: (UIImage) -> Void

    @State private var cameraController: MealCameraController?

    var body: some View {
        ZStack(alignment: .bottom) {
            MealCameraRepresentable(onCapture: onCapture, controller: $cameraController)
                .clipShape(RoundedRectangle(cornerRadius: 20))

            Button {
                cameraController?.capturePhoto()
            } label: {
                Circle()
                    .fill(.white)
                    .frame(width: 56, height: 56)
                    .overlay(Circle().stroke(.white.opacity(0.6), lineWidth: 3).frame(width: 66, height: 66))
            }
            .buttonStyle(.plain)
            .padding(.bottom, 14)
        }
        .frame(height: 220)
        .frame(maxWidth: .infinity)
    }
}

enum PhotoLibrarySaver {
    static func save(_ image: UIImage) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else { return }
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }
        }
    }
}
