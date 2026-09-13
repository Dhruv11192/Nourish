import SwiftUI
import SwiftData

struct UnifiedScannerView: View {
    @Environment(\.dismiss) private var dismiss

    var onLogFood: ((FoodItem) -> Void)?
    var onLogFoods: (([FoodItem]) -> Void)?
    var onManualEntry: (() -> Void)?

    @State var selectedMode: ScannerMode = .barcode
    @State var cameraController = CameraController()
    @State var barcodeViewModel = BarcodeScannerViewModel()
    @State var ocrViewModel = OCRScannerViewModel()
    @State var plateViewModel = AIPlateScannerViewModel()

    init(
        selectedMode: ScannerMode = .barcode,
        onLogFood: ((FoodItem) -> Void)? = nil,
        onLogFoods: (([FoodItem]) -> Void)? = nil,
        onManualEntry: (() -> Void)? = nil
    ) {
        self._selectedMode = State(initialValue: selectedMode)
        self.onLogFood = onLogFood
        self.onLogFoods = onLogFoods
        self.onManualEntry = onManualEntry
    }

    var body: some View {
        ZStack {
            // Background
            ThemeColors.deepBackground
                .ignoresSafeArea()

            // Live Camera Viewfinder Layer
            CameraPreviewRepresentable(controller: cameraController)
                .ignoresSafeArea()

            // Mode-specific Scanner Overlays
            Group {
                switch selectedMode {
                case .barcode:
                    BarcodeScannerOverlay(
                        viewModel: barcodeViewModel,
                        onLogFood: { item in
                            handleLogFood(item)
                        }
                    )
                case .ocrLabel:
                    OCRLabelScannerOverlay(
                        viewModel: ocrViewModel,
                        captureAction: {
                            capturePhotoForOCR()
                        },
                        onLogFood: { item in
                            handleLogFood(item)
                        }
                    )
                case .aiPlate:
                    AIPlateClassifierOverlay(
                        viewModel: plateViewModel,
                        captureAction: {
                            capturePhotoForPlate()
                        },
                        onLogFoods: { items in
                            handleLogFoods(items)
                        }
                    )
                }
            }
            .animation(FluidSprings.standard, value: selectedMode)

            // Top Overlay Navigation Bar
            VStack {
                topNavigationBar
                Spacer()
            }
        }
        .onAppear {
            setupCameraCallbacks()
            cameraController.start()
            if selectedMode == .barcode {
                barcodeViewModel.startScanning()
            }
        }
        .onDisappear {
            cameraController.stop()
        }
        .onChange(of: selectedMode) { _, newMode in
            handleModeChange(newMode)
        }
    }

    // MARK: - Top Navigation Bar

    private var topNavigationBar: some View {
        VStack(spacing: 12) {
            HStack {
                // Close button
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(.ultraThinMaterial)
                        .background(Color.black.opacity(0.4))
                        .clipShape(Circle())
                }

                Spacer()

                // Mode Selector Pill
                modeSelectorPill

                Spacer()

                // Flashlight Button
                Button(action: {
                    HapticFeedback.trigger(.light)
                    cameraController.toggleFlashlight()
                }) {
                    Image(systemName: cameraController.isFlashlightOn ? "bolt.fill" : "bolt.slash.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(cameraController.isFlashlightOn ? .yellow : .white)
                        .padding(10)
                        .background(.ultraThinMaterial)
                        .background(Color.black.opacity(0.4))
                        .clipShape(Circle())
                }

                // Manual Entry Shortcut Button
                Button(action: {
                    HapticFeedback.trigger(.medium)
                    if let onManualEntry {
                        onManualEntry()
                    } else {
                        dismiss()
                    }
                }) {
                    HStack(spacing: 4) {
                        Text("Manual")
                            .font(.system(.caption, design: .rounded).bold())
                        Image(systemName: "plus")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .background(Color.black.opacity(0.4))
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
        }
    }

    // MARK: - Mode Selector Pill

    private var modeSelectorPill: some View {
        HStack(spacing: 4) {
            ForEach(ScannerMode.allCases) { mode in
                modeButton(for: mode)
            }
        }
        .padding(4)
        .background(.ultraThinMaterial)
        .background(Color.black.opacity(0.4))
        .clipShape(Capsule())
    }

    private func modeButton(for mode: ScannerMode) -> some View {
        let isSelected = selectedMode == mode
        return Button(action: {
            HapticFeedback.trigger(.light)
            withAnimation(FluidSprings.standard) {
                selectedMode = mode
            }
        }) {
            HStack(spacing: 4) {
                Image(systemName: mode.iconName)
                    .font(.system(size: 12))
                Text(mode.rawValue)
                    .font(.system(.caption2, design: .rounded).bold())
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? ThemeColors.protein : Color.clear)
            .foregroundColor(isSelected ? .black : .white)
            .clipShape(Capsule())
        }
    }

    // MARK: - Actions & Handlers

    private func setupCameraCallbacks() {
        cameraController.onBarcodeScanned = { barcode in
            guard selectedMode == .barcode else { return }
            Task { @MainActor in
                await barcodeViewModel.processScannedBarcode(barcode)
            }
        }
    }

    private func handleModeChange(_ newMode: ScannerMode) {
        barcodeViewModel.reset()
        ocrViewModel.reset()
        plateViewModel.reset()

        switch newMode {
        case .barcode:
            barcodeViewModel.startScanning()
            cameraController.isCapturingFrames = false
        case .ocrLabel:
            barcodeViewModel.pauseScanning()
            cameraController.isCapturingFrames = false
        case .aiPlate:
            barcodeViewModel.pauseScanning()
            cameraController.isCapturingFrames = false
        }
    }

    private func capturePhotoForOCR() {
        cameraController.capturePhoto { image in
            Task { @MainActor in
                await ocrViewModel.processImage(image)
            }
        }
    }

    private func capturePhotoForPlate() {
        plateViewModel.state = .analyzing
        cameraController.capturePhoto { image in
            Task { @MainActor in
                await plateViewModel.analyzeImage(image)
            }
        }
    }

    private func handleLogFood(_ item: FoodItem) {
        onLogFood?(item)
        dismiss()
    }

    private func handleLogFoods(_ items: [FoodItem]) {
        if let onLogFoods {
            onLogFoods(items)
        } else if let onLogFood {
            for item in items {
                onLogFood(item)
            }
        }
        dismiss()
    }
}
