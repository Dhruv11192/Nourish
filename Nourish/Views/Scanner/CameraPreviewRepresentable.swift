import SwiftUI
import AVFoundation

#if canImport(UIKit)
import UIKit
typealias PlatformView = UIView
typealias ViewRepresentable = UIViewRepresentable
#elseif canImport(AppKit)
import AppKit
typealias PlatformView = NSView
typealias ViewRepresentable = NSViewRepresentable
#endif

@Observable
final class CameraController: NSObject, AVCapturePhotoCaptureDelegate, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureMetadataOutputObjectsDelegate {

    var session = AVCaptureSession()
    var isFlashlightOn = false
    var isCapturingFrames = false

    private var photoOutput = AVCapturePhotoOutput()
    private var videoOutput = AVCaptureVideoDataOutput()
    private var metadataOutput = AVCaptureMetadataOutput()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")

    #if canImport(UIKit)
    typealias ImageType = UIImage
    #elseif canImport(AppKit)
    typealias ImageType = NSImage
    #endif

    var onPhotoCaptured: ((ImageType) -> Void)?
    var onFrameCaptured: ((CGImage) -> Void)?
    var onBarcodeScanned: ((String) -> Void)?

    override init() {
        super.init()
        #if !targetEnvironment(simulator)
        setupSession()
        #endif
    }

    private func setupSession() {
        sessionQueue.async {
            self.session.beginConfiguration()

            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice),
                  self.session.canAddInput(videoDeviceInput) else {
                self.session.commitConfiguration()
                return
            }
            self.session.addInput(videoDeviceInput)

            // Photo Output
            if self.session.canAddOutput(self.photoOutput) {
                self.session.addOutput(self.photoOutput)
            }

            // Video Frame Output for OCR
            if self.session.canAddOutput(self.videoOutput) {
                self.session.addOutput(self.videoOutput)
                self.videoOutput.alwaysDiscardsLateVideoFrames = true
                self.videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera.video.queue"))
            }

            // Metadata Output for Barcodes
            if self.session.canAddOutput(self.metadataOutput) {
                self.session.addOutput(self.metadataOutput)
                self.metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                self.metadataOutput.metadataObjectTypes = [.ean8, .ean13, .pdf417, .qr, .upce]
            }

            self.session.commitConfiguration()
        }
    }

    func start() {
        sessionQueue.async {
            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }

    func stop() {
        sessionQueue.async {
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }

    func toggleFlashlight() {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            isFlashlightOn.toggle()
            device.torchMode = isFlashlightOn ? .on : .off
            device.unlockForConfiguration()
        } catch {
            print("Torch could not be used")
        }
    }

    func capturePhoto(completion: @escaping (ImageType) -> Void) {
        self.onPhotoCaptured = completion
        let settings = AVCapturePhotoSettings()
        #if !targetEnvironment(simulator)
        if photoOutput.connection(with: .video) != nil {
            photoOutput.capturePhoto(with: settings, delegate: self)
            return
        }
        #endif
        // Dummy/fallback photo logic for simulator or headless test runners
        #if canImport(UIKit)
        completion(UIImage())
        #elseif canImport(AppKit)
        completion(NSImage())
        #endif
    }

    // MARK: - Delegates

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(), let image = ImageType(data: data) else { return }
        DispatchQueue.main.async { [weak self] in
            self?.onPhotoCaptured?(image)
        }
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard isCapturingFrames else { return }
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }

        onFrameCaptured?(cgImage)
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject, let stringValue = metadataObject.stringValue {
            onBarcodeScanned?(stringValue)
        }
    }
}

struct CameraPreviewRepresentable: ViewRepresentable {
    let controller: CameraController

    #if targetEnvironment(simulator)
    func makeUIView(context: Context) -> PlatformView {
        let view = PlatformView()
        #if canImport(UIKit)
        view.backgroundColor = UIColor(ThemeColors.deepBackground)
        #else
        view.wantsLayer = true
        view.layer?.backgroundColor = ThemeColors.deepBackground.cgColor
        #endif
        return view
    }

    #if canImport(UIKit)
    func updateUIView(_ uiView: PlatformView, context: Context) {}
    #else
    func updateNSView(_ nsView: PlatformView, context: Context) {}
    #endif

    #else

    // On macOS layerClass isn't needed in the same way, but let's just make it a simple view for now
    class VideoPreviewView: PlatformView {
        #if canImport(UIKit)
        override class var layerClass: AnyClass {
            return AVCaptureVideoPreviewLayer.self
        }
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            return layer as! AVCaptureVideoPreviewLayer
        }
        #else
        var videoPreviewLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer()
        override init(frame frameRect: NSRect) {
            super.init(frame: frameRect)
            wantsLayer = true
            layer?.addSublayer(videoPreviewLayer)
        }
        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
        override func layout() {
            super.layout()
            videoPreviewLayer.frame = layer?.bounds ?? .zero
        }
        #endif
    }

    #if canImport(UIKit)
    func makeUIView(context: Context) -> VideoPreviewView {
        let view = VideoPreviewView()
        view.videoPreviewLayer.session = controller.session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: VideoPreviewView, context: Context) {
        uiView.videoPreviewLayer.session = controller.session
    }
    #else
    func makeNSView(context: Context) -> VideoPreviewView {
        let view = VideoPreviewView()
        view.videoPreviewLayer.session = controller.session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateNSView(_ nsView: VideoPreviewView, context: Context) {
        nsView.videoPreviewLayer.session = controller.session
    }
    #endif
    #endif
}
