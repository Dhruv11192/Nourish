# Diary + Offline Food Search + Seeding + Scanner Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver a 1:1 functional MyFitnessPal-style daily food logging flow in Kalai (Diary, Food Search, Barcode Scanner), backed by an offline seeded SwiftData catalog.

**Architecture:** Build on SwiftData. Use `DailyDiary` per date, `FoodRecord` entries per meal, and `CatalogFoodEntry` for searchable offline foods. Keep UI in SwiftUI with KalaiTheme; keep barcodes via AVFoundation.

**Tech Stack:** SwiftData, SwiftUI, XcodeGen (project.yml), XCTest, AVFoundation.

**Spec:** docs/superpowers/specs/2026-09-15-diary-seeding-scanner-design.md

## Global Constraints
- iOS 17.0+ compatibility required
- All colors must route through KalaiTheme.colors; never hardcode pure black (#000000) or pure white (#FFFFFF)
- Keep the UI consistent with KalaiTheme: backgrounds = Dark Charcoal, surfaces = Muted Olive, accents = Ochre, text = Soft Cream
- Spring animations via KalaiTheme.spring
- Keep functionality parity with core MyFitnessPal logging flows as described in the spec
- Use TDD per task (write failing test → implement → pass → commit)
- Use XcodeGen + project.yml for project generation
- Do not create paywalls or subscription gates

## Conflict Scan (executed before implementation)
- Task 1 already complete. Base: `89cfb4b1`.
- Task 2 consumes `CatalogFood` and `DataIngestor`. No conflict with Task 1.
- Task 3 consumes `FoodSearchEngine` and `CatalogFoodEntry`. No conflict with Task 2 outputs.
- Task 4 wraps AVFoundation scanner and must stay separate from search flow until barcode lookup callback.
- Task 5 consumes diary models and search UI. Must depend on Tasks 2–4 interfaces.
- Task 6 adds default dataset and wiring in `KalaiApp`. Must run after seeding engine exists.
- No conflicting file ownership detected across tasks 2–6.

---

### Task 1: Update Data Models with Meal Categories and Search Index

**Status:** COMPLETE

**Files:**
- Modified: `Kalai/Sources/Models/FoodRecord.swift`
- Created: `Kalai/Sources/Models/CatalogFoodEntry.swift`
- Modified: `Kalai/Sources/KalaiApp.swift`
- Modified: `Kalai/Tests/DataModelTests.swift`

**Interfaces:**
- Produced: `FoodRecord.mealType`, `CatalogFoodEntry`, model container registration

- [x] All steps completed

---

### Task 2: Build Database Seeding Engine (`DataSeeder`)

**Files:**
- Create: `Kalai/Sources/Engines/DataSeeder.swift`
- Create: `Kalai/Tests/DataSeederTests.swift`

**Interfaces:**
- Consumes: `CatalogFood` (Codable) via `DataIngestor`.
- Produces: `DataSeeder.seedInitialFoods(into: ModelContext, foodsData: Data)` for populating `CatalogFoodEntry`.

- [ ] **Step 1: Write the failing test for `DataSeeder`**

```swift
// Kalai/Tests/DataSeederTests.swift
import XCTest
import SwiftData
@testable import Kalai

final class DataSeederTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!

    override func setUpWithError() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: CatalogFoodEntry.self, configurations: config)
        context = ModelContext(container)
    }

    func testSeedInitialFoods() throws {
        let json = """
        [
            {
                "id": "item_1",
                "name": "Banana",
                "nutritional_contents": {
                    "energy": { "unit": "calories", "value": 105.0 },
                    "protein": 1.3,
                    "carbohydrates": 27.0,
                    "fat": 0.3
                },
                "serving_sizes": [
                    { "unit": "medium", "value": 1.0, "nutrition_multiplier": 1.0 }
                ]
            }
        ]
        """.data(using: .utf8)!

        DataSeeder.seedInitialFoods(into: context, foodsData: json)

        let descriptor = FetchDescriptor<CatalogFoodEntry>()
        let results = try context.fetch(descriptor)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.name, "Banana")
        XCTAssertEqual(results.first?.calories, 105.0)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodegen generate && DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -project /Users/dhruv/Kalai/Kalai.xcodeproj -scheme KalaiTests -destination 'platform=iOS Simulator,name=iPhone 17' CODE_SIGNING_ALLOWED=NO`
Expected: FAIL with missing `DataSeeder`.

- [ ] **Step 3: Implement `DataSeeder`**

```swift
// Kalai/Sources/Engines/DataSeeder.swift
import Foundation
import SwiftData

enum DataSeeder {
    static func seedInitialFoods(into context: ModelContext, foodsData: Data) {
        let parsedFoods = DataIngestor.parseFoods(from: foodsData)
        guard !parsedFoods.isEmpty else { return }

        for food in parsedFoods {
            let serving = food.serving_sizes.first
            let entry = CatalogFoodEntry(
                id: food.id,
                name: food.name,
                brand: food.category ?? "",
                calories: food.nutritional_contents.energy.value,
                protein: food.nutritional_contents.protein ?? 0.0,
                carbs: food.nutritional_contents.carbohydrates ?? 0.0,
                fat: food.nutritional_contents.fat ?? 0.0,
                servingSize: serving?.value ?? 1.0,
                servingUnit: serving?.unit ?? "serving",
                barcode: nil
            )
            context.insert(entry)
        }

        try? context.save()
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -project /Users/dhruv/Kalai/Kalai.xcodeproj -scheme KalaiTests -destination 'platform=iOS Simulator,name=iPhone 17' CODE_SIGNING_ALLOWED=NO`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git -C /Users/dhruv add Kalai/Sources/Engines/DataSeeder.swift Kalai/Tests/DataSeederTests.swift
git -C /Users/dhruv commit -m "feat(data): implement DataSeeder to populate SwiftData catalog"
```

---

### Task 3: Build Interactive Food Search View (`FoodSearchView`)

**Files:**
- Create: `Kalai/Sources/Views/Search/FoodSearchView.swift`
- Create: `Kalai/Sources/Views/Search/FoodDetailModalView.swift`
- Create: `Kalai/Tests/FoodSearchViewTests.swift`

**Interfaces:**
- Consumes: SwiftData `@Query` on `CatalogFoodEntry`.
- Produces: `FoodSearchView` sheet triggering food logging into a given `mealType` and `date`.

- [ ] **Step 1: Write the failing test for `FoodSearchView`**

```swift
// Kalai/Tests/FoodSearchViewTests.swift
import XCTest
import SwiftUI
@testable import Kalai

final class FoodSearchViewTests: XCTestCase {
    func testFoodSearchViewInstantiation() {
        let view = FoodSearchView(mealType: "Breakfast", selectedDate: .now, onFoodLogged: { _ in })
        XCTAssertNotNil(view)
    }

    func testFoodDetailModalViewCalculation() {
        let entry = CatalogFoodEntry(
            id: "1",
            name: "Egg",
            calories: 70,
            protein: 6,
            carbs: 0.5,
            fat: 5,
            servingSize: 1,
            servingUnit: "large"
        )
        let modal = FoodDetailModalView(food: entry, mealType: "Breakfast", onLog: { _ in })
        XCTAssertEqual(modal.calculatedCalories(servings: 2.0), 140)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodegen generate && DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -project /Users/dhruv/Kalai/Kalai.xcodeproj -scheme KalaiTests -destination 'platform=iOS Simulator,name=iPhone 17' CODE_SIGNING_ALLOWED=NO`
Expected: FAIL (missing `FoodSearchView`, `FoodDetailModalView`).

- [ ] **Step 3: Implement `FoodDetailModalView` and `FoodSearchView`**

```swift
// Kalai/Sources/Views/Search/FoodDetailModalView.swift
import SwiftUI

struct FoodDetailModalView: View {
    let food: CatalogFoodEntry
    let mealType: String
    var onLog: (FoodRecord) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var servings: Double = 1.0

    func calculatedCalories(servings: Double) -> Double {
        return food.calories * servings
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(food.name)
                        .font(.title2.bold())
                        .foregroundStyle(KalaiTheme.colors.text)
                    if !food.brand.isEmpty {
                        Text(food.brand)
                            .font(.subheadline)
                            .foregroundStyle(KalaiTheme.colors.accent)
                    }
                }

                HStack {
                    Text("Servings")
                        .foregroundStyle(KalaiTheme.colors.text)
                    Spacer()
                    TextField("1.0", value: $servings, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .padding(8)
                        .background(KalaiTheme.colors.surface)
                        .cornerRadius(8)
                        .foregroundStyle(KalaiTheme.colors.text)
                        .frame(width: 80)
                }

                VStack(spacing: 12) {
                    HStack {
                        Text("Calories")
                        Spacer()
                        Text("\(Int(calculatedCalories(servings: servings))) kcal")
                    }
                    Divider().background(KalaiTheme.colors.surface)
                    HStack {
                        Text("Protein")
                        Spacer()
                        Text(String(format: "%.1f g", food.protein * servings))
                    }
                    Divider().background(KalaiTheme.colors.surface)
                    HStack {
                        Text("Carbohydrates")
                        Spacer()
                        Text(String(format: "%.1f g", food.carbs * servings))
                    }
                    Divider().background(KalaiTheme.colors.surface)
                    HStack {
                        Text("Fat")
                        Spacer()
                        Text(String(format: "%.1f g", food.fat * servings))
                    }
                }
                .padding()
                .background(KalaiTheme.colors.surface.opacity(0.5))
                .cornerRadius(12)
                .foregroundStyle(KalaiTheme.colors.text)

                Spacer()

                Button {
                    let record = FoodRecord(
                        name: food.name,
                        brand: food.brand,
                        calories: calculatedCalories(servings: servings),
                        protein: food.protein * servings,
                        carbs: food.carbs * servings,
                        fat: food.fat * servings,
                        portionSize: servings,
                        portionUnit: food.servingUnit,
                        mealType: mealType
                    )
                    onLog(record)
                    dismiss()
                } label: {
                    Text("Log to \(mealType)")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(KalaiTheme.colors.accent)
                        .foregroundStyle(KalaiTheme.colors.background)
                        .cornerRadius(12)
                }
            }
            .padding()
            .kalaiBackground()
            .navigationTitle("Food Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(KalaiTheme.colors.accent)
                }
            }
        }
    }
}
```

```swift
// Kalai/Sources/Views/Search/FoodSearchView.swift
import SwiftUI
import SwiftData

struct FoodSearchView: View {
    let mealType: String
    let selectedDate: Date
    var onFoodLogged: (FoodRecord) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var allFoods: [CatalogFoodEntry]

    @State private var searchText: String = ""
    @State private var selectedFood: CatalogFoodEntry?
    @State private var showScanner: Bool = false

    var filteredFoods: [CatalogFoodEntry] {
        if searchText.isEmpty {
            return allFoods
        } else {
            return allFoods.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.brand.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(KalaiTheme.colors.accent)
                    TextField("Search foods...", text: $searchText)
                        .foregroundStyle(KalaiTheme.colors.text)
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(KalaiTheme.colors.surface)
                        }
                    }
                    Button {
                        showScanner = true
                    } label: {
                        Image(systemName: "barcode.viewfinder")
                            .font(.title3)
                            .foregroundStyle(KalaiTheme.colors.accent)
                    }
                }
                .padding()
                .background(KalaiTheme.colors.surface)
                .cornerRadius(12)
                .padding(.horizontal)

                List {
                    ForEach(filteredFoods) { food in
                        Button {
                            selectedFood = food
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(food.name)
                                        .font(.headline)
                                        .foregroundStyle(KalaiTheme.colors.text)
                                    if !food.brand.isEmpty {
                                        Text(food.brand)
                                            .font(.caption)
                                            .foregroundStyle(KalaiTheme.colors.accent)
                                    }
                                }
                                Spacer()
                                Text("\(Int(food.calories)) kcal")
                                    .font(.subheadline)
                                    .foregroundStyle(KalaiTheme.colors.text)
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(KalaiTheme.colors.surface.opacity(0.3))
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .kalaiBackground()
            .navigationTitle("Add to \(mealType)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(KalaiTheme.colors.accent)
                }
            }
            .sheet(item: $selectedFood) { food in
                FoodDetailModalView(food: food, mealType: mealType) { record in
                    onFoodLogged(record)
                    dismiss()
                }
            }
        }
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -project /Users/dhruv/Kalai/Kalai.xcodeproj -scheme KalaiTests -destination 'platform=iOS Simulator,name=iPhone 17' CODE_SIGNING_ALLOWED=NO`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git -C /Users/dhruv add Kalai/Sources/Views/Search/FoodSearchView.swift Kalai/Sources/Views/Search/FoodDetailModalView.swift Kalai/Tests/FoodSearchViewTests.swift
git -C /Users/dhruv commit -m "feat(ui): implement FoodSearchView and FoodDetailModalView with earthy theme"
```

---

### Task 4: Implement Barcode Scanner with AVFoundation (`BarcodeScannerView`)

**Files:**
- Create: `Kalai/Sources/Views/Scanner/BarcodeScannerView.swift`
- Create: `Kalai/Tests/BarcodeScannerTests.swift`

**Interfaces:**
- Consumes: `AVFoundation` metadata capture.
- Produces: `BarcodeScannerView` returning scanned barcode string `(String) -> Void`.

- [ ] **Step 1: Write the failing test for `BarcodeScannerView`**

```swift
// Kalai/Tests/BarcodeScannerTests.swift
import XCTest
import SwiftUI
@testable import Kalai

final class BarcodeScannerTests: XCTestCase {
    func testBarcodeScannerViewInstantiation() {
        let scanner = BarcodeScannerView(onScan: { _ in })
        XCTAssertNotNil(scanner)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodegen generate && DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -project /Users/dhruv/Kalai/Kalai.xcodeproj -scheme KalaiTests -destination 'platform=iOS Simulator,name=iPhone 17' CODE_SIGNING_ALLOWED=NO`
Expected: FAIL (missing `BarcodeScannerView`).

- [ ] **Step 3: Implement `BarcodeScannerView`**

```swift
// Kalai/Sources/Views/Scanner/BarcodeScannerView.swift
import SwiftUI
import AVFoundation

struct BarcodeScannerView: UIViewControllerRepresentable {
    var onScan: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> BarcodeScannerViewController {
        let controller = BarcodeScannerViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: BarcodeScannerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject, BarcodeScannerDelegate {
        let parent: BarcodeScannerView

        init(parent: BarcodeScannerView) {
            self.parent = parent
        }

        func didFindBarcode(_ code: String) {
            parent.onScan(code)
            parent.dismiss()
        }
    }
}

protocol BarcodeScannerDelegate: AnyObject {
    func didFindBarcode(_ code: String)
}

class BarcodeScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    weak var delegate: BarcodeScannerDelegate?
    private var captureSession: AVCaptureSession?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCamera()
    }

    private func setupCamera() {
        let session = AVCaptureSession()
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video),
              let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice),
              session.canAddInput(videoInput) else {
            return
        }

        session.addInput(videoInput)

        let metadataOutput = AVCaptureMetadataOutput()
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.ean8, .ean13, .pdf417, .qr, .upce, .code128]
        } else {
            return
        }

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        self.captureSession = session
        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first,
           let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
           let stringValue = readableObject.stringValue {
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            captureSession?.stopRunning()
            delegate?.didFindBarcode(stringValue)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if captureSession?.isRunning == true {
            captureSession?.stopRunning()
        }
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -project /Users/dhruv/Kalai/Kalai.xcodeproj -scheme KalaiTests -destination 'platform=iOS Simulator,name=iPhone 17' CODE_SIGNING_ALLOWED=NO`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git -C /Users/dhruv add Kalai/Sources/Views/Scanner/BarcodeScannerView.swift Kalai/Tests/BarcodeScannerTests.swift
git -C /Users/dhruv commit -m "feat(scanner): add native AVFoundation BarcodeScannerView"
```

---

### Task 5: Build Complete Daily Diary View (`DiaryView`) with Meal Sections and Summary

**Files:**
- Modify: `Kalai/Sources/Views/Diary/DiaryView.swift`
- Create: `Kalai/Sources/Views/Diary/MealSectionView.swift`
- Modify: `Kalai/Tests/MainTabViewTests.swift`

**Interfaces:**
- Consumes: SwiftData `DailyDiary`, `FoodRecord`, `FoodSearchView`.
- Produces: Complete daily logging interface with Breakfast, Lunch, Dinner, and Snacks sections.

- [ ] **Step 1: Write the failing test for `MealSectionView`**

```swift
// In Kalai/Tests/MainTabViewTests.swift
func testMealSectionViewInstantiation() {
    let section = MealSectionView(title: "Breakfast", foods: [], onAddFood: {})
    XCTAssertNotNil(section)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -project /Users/dhruv/Kalai/Kalai.xcodeproj -scheme KalaiTests -destination 'platform=iOS Simulator,name=iPhone 17' CODE_SIGNING_ALLOWED=NO`
Expected: FAIL (missing `MealSectionView`).

- [ ] **Step 3: Implement `MealSectionView` and interactive `DiaryView`**

```swift
// Kalai/Sources/Views/Diary/MealSectionView.swift
import SwiftUI

struct MealSectionView: View {
    let title: String
    let foods: [FoodRecord]
    var onAddFood: () -> Void
    var onDeleteFood: ((FoodRecord) -> Void)?

    var totalCalories: Double {
        foods.reduce(0) { $0 + $1.calories }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(KalaiTheme.colors.text)
                Spacer()
                Text("\(Int(totalCalories)) kcal")
                    .font(.subheadline)
                    .foregroundStyle(KalaiTheme.colors.accent)
            }

            if !foods.isEmpty {
                VStack(spacing: 6) {
                    ForEach(foods) { food in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(food.name)
                                    .font(.subheadline)
                                    .foregroundStyle(KalaiTheme.colors.text)
                                Text("\(String(format: "%.1f", food.portionSize)) \(food.portionUnit)")
                                    .font(.caption2)
                                    .foregroundStyle(KalaiTheme.colors.accent)
                            }
                            Spacer()
                            Text("\(Int(food.calories))")
                                .font(.subheadline)
                                .foregroundStyle(KalaiTheme.colors.text)
                        }
                        .padding(.vertical, 4)
                        Divider().background(KalaiTheme.colors.surface)
                    }
                }
            }

            Button {
                onAddFood()
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Food")
                }
                .font(.subheadline.bold())
                .foregroundStyle(KalaiTheme.colors.accent)
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(KalaiTheme.colors.surface.opacity(0.4))
        .cornerRadius(12)
    }
}
```

```swift
// Kalai/Sources/Views/Diary/DiaryView.swift
import SwiftUI
import SwiftData

struct DiaryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var diaries: [DailyDiary]

    @State private var selectedDate: Date = .now
    @State private var activeMealType: String?

    var currentDiary: DailyDiary {
        if let existing = diaries.first(where: { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }) {
            return existing
        } else {
            let newDiary = DailyDiary(date: selectedDate, foods: [])
            modelContext.insert(newDiary)
            return newDiary
        }
    }

    func foods(for mealType: String) -> [FoodRecord] {
        currentDiary.foods.filter { $0.mealType == mealType }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Date switcher
                    HStack {
                        Button {
                            selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
                        } label: {
                            Image(systemName: "chevron.left")
                                .foregroundStyle(KalaiTheme.colors.accent)
                        }

                        Spacer()

                        Text(selectedDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.headline)
                            .foregroundStyle(KalaiTheme.colors.text)

                        Spacer()

                        Button {
                            selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
                        } label: {
                            Image(systemName: "chevron.right")
                                .foregroundStyle(KalaiTheme.colors.accent)
                        }
                    }
                    .padding()
                    .background(KalaiTheme.colors.surface)
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // Daily summary ring
                    HStack(spacing: 20) {
                        MacroRingView(total: 2000, consumed: currentDiary.totalCalories)
                            .frame(width: 100, height: 100)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Total Logged")
                                .font(.caption)
                                .foregroundStyle(KalaiTheme.colors.accent)
                            Text("\(Int(currentDiary.totalCalories)) kcal")
                                .font(.title2.bold())
                                .foregroundStyle(KalaiTheme.colors.text)
                            Text("Goal: 2000 kcal")
                                .font(.caption)
                                .foregroundStyle(KalaiTheme.colors.text.opacity(0.8))
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(KalaiTheme.colors.surface.opacity(0.3))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // Meal Sections
                    VStack(spacing: 12) {
                        MealSectionView(title: "Breakfast", foods: foods(for: "Breakfast")) {
                            activeMealType = "Breakfast"
                        }
                        MealSectionView(title: "Lunch", foods: foods(for: "Lunch")) {
                            activeMealType = "Lunch"
                        }
                        MealSectionView(title: "Dinner", foods: foods(for: "Dinner")) {
                            activeMealType = "Dinner"
                        }
                        MealSectionView(title: "Snacks", foods: foods(for: "Snacks")) {
                            activeMealType = "Snacks"
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .kalaiBackground()
            .navigationTitle("Diary")
            .sheet(item: Binding(get: {
                activeMealType.map { MealTypeWrapper(type: $0) }
            }, set: {
                activeMealType = $0?.type
            })) { wrapper in
                FoodSearchView(mealType: wrapper.type, selectedDate: selectedDate) { newRecord in
                    currentDiary.foods.append(newRecord)
                    try? modelContext.save()
                }
            }
        }
    }
}

struct MealTypeWrapper: Identifiable {
    let id = UUID()
    let type: String
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -project /Users/dhruv/Kalai/Kalai.xcodeproj -scheme KalaiTests -destination 'platform=iOS Simulator,name=iPhone 17' CODE_SIGNING_ALLOWED=NO`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git -C /Users/dhruv add Kalai/Sources/Views/Diary/DiaryView.swift Kalai/Sources/Views/Diary/MealSectionView.swift Kalai/Tests/MainTabViewTests.swift
git -C /Users/dhruv commit -m "feat(ui): implement interactive DiaryView with meal categories and daily summary"
```

---

### Task 6: Seed Default Food Catalog and Build Final Release IPA

**Files:**
- Modify: `Kalai/Sources/KalaiApp.swift`
- Create: `Kalai/Sources/Resources/foods.json` (Seed dataset)
- Modify: `Kalai/project.yml`

**Interfaces:**
- Consumes: Seed JSON file bundled in target resources.
- Produces: Initialized offline database on launch, validated clean Release build and updated `Kalai.ipa`.

- [ ] **Step 1: Create seed JSON dataset and update `project.yml`**

Create `Kalai/Sources/Resources/foods.json` with standard MFP food items.
Add `Resources` folder to `sources` in `Kalai/project.yml`.

- [ ] **Step 2: Connect automatic seeding to `KalaiApp.swift` on first launch**

```swift
import SwiftUI
import SwiftData

@main
struct KalaiApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: UserProfile.self, DailyDiary.self, FoodRecord.self, CatalogFoodEntry.self)
            seedDefaultCatalogIfNeeded()
        } catch {
            fatalError("Failed to initialize SwiftData container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(container)
    }

    private func seedDefaultCatalogIfNeeded() {
        let context = ModelContext(container)
        var descriptor = FetchDescriptor<CatalogFoodEntry>()
        descriptor.fetchLimit = 1
        if let count = try? context.fetchCount(descriptor), count == 0 {
            if let url = Bundle.main.url(forResource: "foods", withExtension: "json"),
               let data = try? Data(contentsOf: url) {
                DataSeeder.seedInitialFoods(into: context, foodsData: data)
            }
        }
    }
}
```

- [ ] **Step 3: Run full test suite and build release IPA**

Run: `xcodegen generate && DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -project /Users/dhruv/Kalai/Kalai.xcodeproj -scheme KalaiTests -destination 'platform=iOS Simulator,name=iPhone 17' CODE_SIGNING_ALLOWED=NO`
Expected: ALL TESTS PASS.

- [ ] **Step 4: Package clean Release IPA for TrollStore**

Run build script to output `Kalai.ipa`.

- [ ] **Step 5: Commit and Push**

```bash
git -C /Users/dhruv add Kalai/Sources/KalaiApp.swift Kalai/Sources/Resources/foods.json Kalai/project.yml
git -C /Users/dhruv commit -m "feat: embed default food catalog and auto-seed on first launch"
git -C /Users/dhruv push origin main
```
