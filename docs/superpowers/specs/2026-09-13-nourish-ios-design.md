# Nourish: Minimalist iOS 17 Food & Health Tracker

## Overview
A native iOS 17.0+ SwiftUI application designed as a completely free, elegant alternative to MyFitnessPal. The app emphasizes a calming, "mindful health" aesthetic featuring deep earth tones in dark mode, fluid spring animations, and local-first architecture. It features guided metabolic onboarding, HealthKit integration, and three distinct camera scanning modes (Barcode, OCR Label, and AI Plate Recognition).

## Architecture
**Pattern:** Modern MVVM with an independent Service Layer.
- **UI/View Layer**: SwiftUI views relying heavily on the iOS 17 `@Observable` macro. Focused entirely on layout, animations, and presentation.
- **ViewModel Layer**: Handles UI state and connects the views to the underlying services.
- **Service Layer**: 
  - `ScannerService`: Manages AVFoundation camera feeds, Vision API OCR, and CoreML tasks.
  - `HealthEngine`: Calculates TDEE/BMR and manages reading/writing to HealthKit.
  - `DatabaseService`: Interacts with OpenFoodFacts API and local raw food datasets.
- **Persistence Layer**: `SwiftData` for fast, private, offline-first storage.

## UI/UX & Aesthetics
- **Color Palette:** Deep backgrounds (`#121212`, `#1A1A1A`) accented with soft earthern tones:
  - Protein: Warm Terracotta (`#CC7A6B`)
  - Carbs: Soft Ochre / Sand (`#D4A373`)
  - Fat: Muted Sage Green (`#899878`)
  - Water/Fluid: Deep Ocean / Slate (`#4A6FA5`)
- **Animations:**
  - **Fluid Rings:** Swift Charts and custom Path progress rings using `.spring(response: 0.4, dampingFraction: 0.8)` for liquid-smooth updating.
  - **Haptics:** `UIImpactFeedbackGenerator` tied to significant user actions (logging a meal, hitting a calorie goal).
  - **Transitions:** `matchedGeometryEffect` for seamless expansion from the dashboard diary into meal detail views.
- **Typography:** SF Pro Rounded for numerical data/calories to soften the interface, standard SF Pro for body text.

## Core Features & Data Engine

### 1. Onboarding & Health Engine
- **Guided Setup:** Users input height, weight, age, biological sex, activity level, and goals.
- **Math Model:** Uses the Mifflin-St Jeor equation to calculate BMR and multiply by activity factors for TDEE.
- **Dynamic Targets:** Calculates basal calorie goals and maps out a default macro split (e.g., 30/40/30) adjustable via sliders.

### 2. Local Persistence (SwiftData)
- **`UserProfile` Model:** Stores biometrics, goals, and macro targets.
- **`DailyLog` Model:** Core aggregate for a given day. Owns relationships to food consumed, water intake, and active energy burned.
- **`FoodItem` Model:** Granular record of a macro/calorie entry.

### 3. Apple HealthKit Integration
- **Import:** Reads `HKQuantityTypeIdentifier.stepCount` and `activeEnergyBurned`. Option to dynamically offset the daily calorie budget directly on the dashboard.
- **Export:** Pushes dietary energy, protein, carbohydrates, total fat, and water to Apple Health to keep systems unified.

## Scanning Intelligence (Camera Features)

### 1. Barcode Scanning
- **Engine:** `AVFoundation` + `Vision` (`VNDetectBarcodesRequest`).
- **Data Source:** Valid codes are sent to the open-source **OpenFoodFacts API**.
- **UX:** Instant detection, haptic bump upon reading, and a smooth slide-up sheet displaying the retrieved macros.

### 2. Nutrition Label Scanning (OCR)
- **Engine:** `Vision` framework (`VNRecognizeTextRequest`).
- **Parsing:** Custom Regex targets keywords ("Calories", "Protein", "Total Carbohydrate", "Total Fat") from the recognized text array, mapping numerical values automatically into the manual entry form.

### 3. AI Meal Photo Recognition
- **Engine:** On-device CoreML (using a quantized MobileNetV2 or customized Food101 dataset model) via `VNClassifyImageRequest`.
- **Flow:** User snaps a plate -> CoreML infers the top 3 items -> App cross-references those items with a local dataset of whole foods to provide a baseline macro/calorie estimate. User fine-tunes via a slider.

## Error Handling & Edge Cases
- **No Internet Connectivity:** Barcode API (OpenFoodFacts) will fail gracefully, prompting the user to use the OCR Label Scanner or manual entry instead.
- **HealthKit Permissions Denied:** App degrades gracefully, hiding the "Calories Burned" offset features and relying entirely on static TDEE.
- **Scanning Failures:** A manual fallback entry form is always one tap away from any scanning screen.
