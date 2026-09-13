# Nourish iOS App Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a complete, native iOS 17.0+ SwiftUI food, calorie, and macro tracking app ("Nourish") with a soothing minimal dark earth-toned aesthetic, fluid spring animations, SwiftData local persistence, HealthKit synchronization, and an all-in-one multi-mode scanner (Barcode, Nutrition Label OCR, and AI Plate Recognition).

**Architecture:** Modern MVVM with an independent Service Layer. SwiftUI views leveraging `@Observable` view models, SwiftData for offline-first local storage, and dedicated services for HealthKit, Vision OCR parsing, OpenFoodFacts networking, and CoreML image classification.

**Tech Stack:** Swift 5.9+, SwiftUI (iOS 17.0+), SwiftData, Swift Charts, HealthKit, AVFoundation, Vision (`VNDetectBarcodesRequest`, `VNRecognizeTextRequest`, `VNClassifyImageRequest`), CoreML, XCTest.

**Spec:** `docs/superpowers/specs/2026-09-13-nourish-ios-design.md`

## Global Constraints
- Target platform: iOS 17.0+
- Design: Dark mode earth-toned color palette (Deep Charcoal `#121212`, Terracotta `#CC7A6B`, Ochre `#D4A373`, Sage Green `#899878`, Ocean Slate `#4A6FA5`).
- Fluid animations using spring physics `.spring(response: 0.4, dampingFraction: 0.8)` with haptic feedback (`UIImpactFeedbackGenerator`).
- Offline-first: SwiftData for local persistence with zero required accounts.
- OpenFoodFacts API for barcode lookups; Vision OCR for nutrition facts labels; Vision classification for food plate photo recognition.

---

### Task 1: Project Setup & Design System Foundation

**Files:**
- Create: `Nourish/DesignSystem/ThemeColors.swift`
- Create: `Nourish/DesignSystem/FluidSprings.swift`
- Create: `Nourish/DesignSystem/Components/LiquidProgressRing.swift`
- Create: `Nourish/DesignSystem/Components/MacroPillView.swift`
- Create: `Nourish/DesignSystem/Components/FrostedCard.swift`
- Test: `NourishTests/DesignSystemTests.swift`

**Interfaces:**
- Produces: `ThemeColors`, `FluidSprings`, `LiquidProgressRing`, `MacroPillView`, `FrostedCard`
- Consumes: SwiftUI, UIKit (for Haptics)

- [ ] **Step 1: Write the failing design system tests**
- [ ] **Step 2: Run test to verify it fails**
- [ ] **Step 3: Implement ThemeColors, FluidSprings, LiquidProgressRing, MacroPillView, FrostedCard**
- [ ] **Step 4: Run test to verify it passes**
- [ ] **Step 5: Commit**

---

### Task 2: SwiftData Models & Schema Definition

**Files:**
- Create: `Nourish/Models/MealType.swift`
- Create: `Nourish/Models/UserProfile.swift`
- Create: `Nourish/Models/FoodItem.swift`
- Create: `Nourish/Models/DailyLog.swift`
- Test: `NourishTests/ModelTests.swift`

**Interfaces:**
- Consumes: SwiftData, Foundation
- Produces: `UserProfile`, `DailyLog`, `FoodItem`, `MealType`

- [ ] **Step 1: Write model unit tests**
- [ ] **Step 2: Run test to verify it fails**
- [ ] **Step 3: Implement SwiftData @Model classes**
- [ ] **Step 4: Run test to verify it passes**
- [ ] **Step 5: Commit**

---

### Task 3: Calorie & Metabolic Calculation Engine

**Files:**
- Create: `Nourish/Engines/CalorieCalculationEngine.swift`
- Test: `NourishTests/CalorieCalculationEngineTests.swift`

**Interfaces:**
- Consumes: Foundation, `UserProfile`
- Produces: `CalorieCalculationEngine.calculateBMR(...)`, `calculateTDEE(...)`, `calculateMacroTargets(...)`, `recalculateGoals(...)`

- [ ] **Step 1: Write Mifflin-St Jeor and macro distribution tests**
- [ ] **Step 2: Run test to verify it fails**
- [ ] **Step 3: Implement CalorieCalculationEngine**
- [ ] **Step 4: Run test to verify it passes**
- [ ] **Step 5: Commit**

---

### Task 4: HealthKit Service Integration

**Files:**
- Create: `Nourish/Engines/HealthKitService.swift`
- Test: `NourishTests/HealthKitServiceTests.swift`

**Interfaces:**
- Consumes: HealthKit
- Produces: `HealthKitService.requestAuthorization()`, `fetchDailyBurnedEnergyAndSteps()`, `exportFoodEntry(...)`, `exportWater(...)`

- [ ] **Step 1: Write mock HealthKit service tests**
- [ ] **Step 2: Run test to verify it fails**
- [ ] **Step 3: Implement HealthKitService**
- [ ] **Step 4: Run test to verify it passes**
- [ ] **Step 5: Commit**

---

### Task 5: Barcode Scanning & OpenFoodFacts Service

**Files:**
- Create: `Nourish/Engines/OpenFoodFactsService.swift`
- Create: `Nourish/ViewModels/BarcodeScannerViewModel.swift`
- Test: `NourishTests/OpenFoodFactsServiceTests.swift`

**Interfaces:**
- Consumes: URLSession, Foundation, `FoodItem`
- Produces: `OpenFoodFactsService.fetchProduct(barcode:) -> FoodItem?`

- [ ] **Step 1: Write network parser unit tests with mock JSON**
- [ ] **Step 2: Run test to verify it fails**
- [ ] **Step 3: Implement OpenFoodFactsService and BarcodeScannerViewModel**
- [ ] **Step 4: Run test to verify it passes**
- [ ] **Step 5: Commit**

---

### Task 6: Nutrition Label OCR Scanner Engine

**Files:**
- Create: `Nourish/Engines/NutritionOCRParser.swift`
- Create: `Nourish/ViewModels/OCRScannerViewModel.swift`
- Test: `NourishTests/NutritionOCRParserTests.swift`

**Interfaces:**
- Consumes: Vision, UIKit, Foundation
- Produces: `NutritionOCRParser.parseNutritionFacts(from: [String]) -> ParsedNutritionData`

- [ ] **Step 1: Write OCR regex parser test cases against real nutrition label text**
- [ ] **Step 2: Run test to verify it fails**
- [ ] **Step 3: Implement NutritionOCRParser & OCRScannerViewModel**
- [ ] **Step 4: Run test to verify it passes**
- [ ] **Step 5: Commit**

---

### Task 7: AI Meal Photo Food Classifier Engine

**Files:**
- Create: `Nourish/Engines/FoodClassifierService.swift`
- Create: `Nourish/Engines/LocalFoodDatabase.swift`
- Create: `Nourish/ViewModels/AIPlateScannerViewModel.swift`
- Test: `NourishTests/FoodClassifierServiceTests.swift`

**Interfaces:**
- Consumes: Vision, CoreML, UIKit, `LocalFoodDatabase`
- Produces: `FoodClassifierService.classifyPlate(image:) -> [EstimatedFoodCandidate]`

- [ ] **Step 1: Write classifier and local food mapping tests**
- [ ] **Step 2: Run test to verify it fails**
- [ ] **Step 3: Implement LocalFoodDatabase & FoodClassifierService**
- [ ] **Step 4: Run test to verify it passes**
- [ ] **Step 5: Commit**

---

### Task 8: Unified Multi-Mode Camera Scanner UI

**Files:**
- Create: `Nourish/Views/Scanner/CameraPreviewRepresentable.swift`
- Create: `Nourish/Views/Scanner/BarcodeScannerOverlay.swift`
- Create: `Nourish/Views/Scanner/OCRLabelScannerOverlay.swift`
- Create: `Nourish/Views/Scanner/AIPlateClassifierOverlay.swift`
- Create: `Nourish/Views/Scanner/UnifiedScannerView.swift`

**Interfaces:**
- Consumes: `OpenFoodFactsService`, `NutritionOCRParser`, `FoodClassifierService`, `ThemeColors`, `FluidSprings`
- Produces: `UnifiedScannerView` with interactive tabs (Barcode, Label OCR, AI Meal Plate)

- [ ] **Step 1: Build CameraPreviewRepresentable with AVFoundation capture session**
- [ ] **Step 2: Build individual scanner overlays with fluid scan guides**
- [ ] **Step 3: Build UnifiedScannerView with mode switcher and haptic feedback**
- [ ] **Step 4: Test in preview and verify camera lifecycle**
- [ ] **Step 5: Commit**

---

### Task 9: Guided Onboarding Flow

**Files:**
- Create: `Nourish/ViewModels/OnboardingViewModel.swift`
- Create: `Nourish/Views/Onboarding/OnboardingFlowView.swift`
- Create: `Nourish/Views/Onboarding/MetricInputStepView.swift`
- Create: `Nourish/Views/Onboarding/GoalSelectionStepView.swift`
- Test: `NourishTests/OnboardingViewModelTests.swift`

**Interfaces:**
- Consumes: `CalorieCalculationEngine`, `UserProfile`, `ThemeColors`
- Produces: `OnboardingFlowView`

- [ ] **Step 1: Write OnboardingViewModel tests**
- [ ] **Step 2: Implement OnboardingFlowView with animated step transitions**
- [ ] **Step 3: Implement MetricInputStepView & GoalSelectionStepView**
- [ ] **Step 4: Verify goal calculation and SwiftData persistence**
- [ ] **Step 5: Commit**

---

### Task 10: Diary, Dashboard & Food Logging UI

**Files:**
- Create: `Nourish/ViewModels/DashboardViewModel.swift`
- Create: `Nourish/ViewModels/DiaryViewModel.swift`
- Create: `Nourish/Views/Dashboard/DailyCalorieSummaryCard.swift`
- Create: `Nourish/Views/Dashboard/MacroBreakdownRow.swift`
- Create: `Nourish/Views/Dashboard/DashboardView.swift`
- Create: `Nourish/Views/Diary/MealSectionCard.swift`
- Create: `Nourish/Views/Diary/WaterTrackerCard.swift`
- Create: `Nourish/Views/Diary/DiaryView.swift`
- Create: `Nourish/Views/FoodLogging/FoodDetailSheet.swift`
- Create: `Nourish/Views/FoodLogging/ManualFoodEntryView.swift`
- Create: `Nourish/Views/MainTabView.swift`
- Create: `Nourish/NourishApp.swift`

**Interfaces:**
- Consumes: All models, services, view models, and design system components
- Produces: Full app entry point and main dashboard/diary views

- [ ] **Step 1: Build DailyCalorieSummaryCard with animated LiquidProgressRing**
- [ ] **Step 2: Build MealSectionCard and WaterTrackerCard with fluid expansion**
- [ ] **Step 3: Build FoodDetailSheet and ManualFoodEntryView**
- [ ] **Step 4: Build MainTabView and wire NourishApp with ModelContainer**
- [ ] **Step 5: Commit**

---

### Task 11: End-to-End Verification & Fluid Animation Polish

**Files:**
- Test: `NourishTests/IntegrationTests.swift`
- Verify: Full app flow, camera permissions, SwiftData persistence, HealthKit export/import

- [ ] **Step 1: Run complete unit & integration test suite**
- [ ] **Step 2: Verify fluid transitions, haptics, and dark-earth color palette rendering**
- [ ] **Step 3: Final commit and summary**
