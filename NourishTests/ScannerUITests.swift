import XCTest
import SwiftUI
@testable import Nourish

@MainActor
final class ScannerUITests: XCTestCase {

    // MARK: - ScannerMode Tests

    func testScannerModeCasesAndProperties() {
        let allModes = ScannerMode.allCases
        XCTAssertEqual(allModes.count, 3)

        let barcodeMode = ScannerMode.barcode
        XCTAssertEqual(barcodeMode.id, "Barcode")
        XCTAssertEqual(barcodeMode.rawValue, "Barcode")
        XCTAssertEqual(barcodeMode.iconName, "barcode.viewfinder")

        let ocrMode = ScannerMode.ocrLabel
        XCTAssertEqual(ocrMode.id, "Nutrition Label")
        XCTAssertEqual(ocrMode.rawValue, "Nutrition Label")
        XCTAssertEqual(ocrMode.iconName, "text.viewfinder")

        let aiPlateMode = ScannerMode.aiPlate
        XCTAssertEqual(aiPlateMode.id, "AI Meal Photo")
        XCTAssertEqual(aiPlateMode.rawValue, "AI Meal Photo")
        XCTAssertEqual(aiPlateMode.iconName, "camera.macro")
    }

    // MARK: - CameraController Tests

    func testCameraControllerInitializationAndControls() {
        let controller = CameraController()
        XCTAssertNotNil(controller.session)
        XCTAssertFalse(controller.isFlashlightOn)
        XCTAssertFalse(controller.isCapturingFrames)

        controller.start()
        controller.stop()

        // Toggle flashlight (safe in test/simulator environment)
        controller.toggleFlashlight()

        let expectation = expectation(description: "Capture photo completion")
        controller.capturePhoto { image in
            XCTAssertNotNil(image)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }

    // MARK: - CameraPreviewRepresentable Tests

    func testCameraPreviewRepresentableInitialization() {
        let controller = CameraController()
        let representable = CameraPreviewRepresentable(controller: controller)
        XCTAssertNotNil(representable)
    }

    // MARK: - BarcodeScannerOverlay Tests

    func testBarcodeScannerOverlayInitialState() {
        let vm = BarcodeScannerViewModel()
        var loggedItem: FoodItem?

        let overlay = BarcodeScannerOverlay(
            viewModel: vm,
            onLogFood: { item in
                loggedItem = item
            }
        )
        XCTAssertNotNil(overlay)
        XCTAssertNil(loggedItem)
    }

    func testBarcodeScannerOverlaySuccessLogging() {
        let vm = BarcodeScannerViewModel()
        let testFood = FoodItem(
            name: "Greek Yogurt",
            barcode: "12345678",
            calories: 120,
            proteinGrams: 15,
            carbsGrams: 6,
            fatGrams: 2,
            mealType: .breakfast
        )
        vm.state = .success(testFood)

        var loggedItem: FoodItem?
        let overlay = BarcodeScannerOverlay(
            viewModel: vm,
            onLogFood: { item in
                loggedItem = item
            }
        )
        XCTAssertNotNil(overlay)

        // Trigger action
        overlay.onLogFood(testFood)
        XCTAssertEqual(loggedItem?.name, "Greek Yogurt")
        XCTAssertEqual(loggedItem?.calories, 120)
    }

    // MARK: - OCRLabelScannerOverlay Tests

    func testOCRLabelScannerOverlayInitialStateAndCapture() {
        let vm = OCRScannerViewModel()
        var captured = false
        var loggedItem: FoodItem?

        let overlay = OCRLabelScannerOverlay(
            viewModel: vm,
            captureAction: {
                captured = true
            },
            onLogFood: { item in
                loggedItem = item
            }
        )
        XCTAssertNotNil(overlay)

        overlay.captureAction()
        XCTAssertTrue(captured)
        XCTAssertNil(loggedItem)
    }

    func testOCRLabelScannerOverlayRecognizedLogging() {
        let vm = OCRScannerViewModel()
        let parsed = ParsedNutritionData(
            calories: 250,
            protein: 20,
            carbs: 30,
            fat: 5,
            servingWeightGrams: 100
        )
        vm.parsedData = parsed
        vm.state = .recognized(parsed)
        vm.nameInput = "Protein Bar"

        var loggedItem: FoodItem?
        let overlay = OCRLabelScannerOverlay(
            viewModel: vm,
            captureAction: {},
            onLogFood: { item in
                loggedItem = item
            }
        )
        XCTAssertNotNil(overlay)

        let foodItem = vm.createFoodItem()
        XCTAssertNotNil(foodItem)
        if let foodItem {
            overlay.onLogFood(foodItem)
        }
        XCTAssertEqual(loggedItem?.name, "Protein Bar")
        XCTAssertEqual(loggedItem?.calories, 250)
        XCTAssertEqual(loggedItem?.proteinGrams, 20)
    }

    // MARK: - AIPlateClassifierOverlay Tests

    func testAIPlateClassifierOverlayStatesAndAggregation() {
        let vm = AIPlateScannerViewModel()
        var captured = false
        var loggedItems: [FoodItem] = []

        let overlay = AIPlateClassifierOverlay(
            viewModel: vm,
            captureAction: {
                captured = true
            },
            onLogFoods: { items in
                loggedItems = items
            }
        )
        XCTAssertNotNil(overlay)

        overlay.captureAction()
        XCTAssertTrue(captured)

        // Populate with candidates
        let candidate1 = EstimatedFoodCandidate(
            name: "Grilled Chicken Breast",
            confidence: 0.95,
            servingGrams: 150,
            calories: 247,
            proteinGrams: 46.5,
            carbsGrams: 0,
            fatGrams: 5.4
        )
        let candidate2 = EstimatedFoodCandidate(
            name: "Brown Rice",
            confidence: 0.88,
            servingGrams: 200,
            calories: 224,
            proteinGrams: 5.0,
            carbsGrams: 46.0,
            fatGrams: 1.8
        )

        vm.state = .results([candidate1, candidate2])
        vm.selectedCandidates = [candidate1.id, candidate2.id]
        vm.portionMultiplier = 1.5

        let generated = vm.generateFoodItemsToLog()
        XCTAssertEqual(generated.count, 2)
        XCTAssertEqual(generated[0].calories, 247 * 1.5, accuracy: 0.1)
        XCTAssertEqual(generated[1].calories, 224 * 1.5, accuracy: 0.1)

        overlay.onLogFoods(generated)
        XCTAssertEqual(loggedItems.count, 2)
    }

    // MARK: - UnifiedScannerView Tests

    func testUnifiedScannerViewInitialization() {
        var loggedFood: FoodItem?
        var loggedFoods: [FoodItem]?
        var manualTapped = false

        let scanner = UnifiedScannerView(
            selectedMode: .barcode,
            onLogFood: { item in
                loggedFood = item
            },
            onLogFoods: { items in
                loggedFoods = items
            },
            onManualEntry: {
                manualTapped = true
            }
        )

        XCTAssertEqual(scanner.selectedMode, .barcode)
        XCTAssertNil(loggedFood)
        XCTAssertNil(loggedFoods)
        XCTAssertFalse(manualTapped)

        let ocrScanner = UnifiedScannerView(selectedMode: .ocrLabel)
        XCTAssertEqual(ocrScanner.selectedMode, .ocrLabel)

        let plateScanner = UnifiedScannerView(selectedMode: .aiPlate)
        XCTAssertEqual(plateScanner.selectedMode, .aiPlate)
    }
}
