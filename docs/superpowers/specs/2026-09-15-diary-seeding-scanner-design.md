# Kalai: Diary, Food Search, Data Seeding, and Barcode Scanner Design

## Overview
This spec defines the core daily logging experience of Kalai, closely mimicking the 20-year-proven workflow of MyFitnessPal (MFP). It introduces robust SwiftData models for food logging, an instant offline food database seeded from MFP datasets, a classic modal food search flow, and a native barcode scanner. 

**Goal:** Deliver a 1:1 functional MFP food logging experience (Search, Scan, Log) backed by a completely offline, seeded catalog database, utilizing the earthy dark theme.

## Data Architecture (SwiftData)

### 1. `FoodRecord` (Represents a logged food entry)
- `id: UUID`
- `name: String`
- `brand: String`
- `calories: Double`
- `protein: Double`
- `carbs: Double`
- `fat: Double`
- `portionSize: Double`
- `portionUnit: String`
- `mealType: String` (e.g., "Breakfast", "Lunch", "Dinner", "Snacks")
- `date: Date`
- `diary: DailyDiary?` (Relationship)

### 2. `DailyDiary` (Represents a single day's container)
- `id: UUID`
- `date: Date` (Normalized to midnight)
- `foods: [FoodRecord]` (Relationship with cascade delete)

### 3. `CatalogFoodEntry` (Represents an item in the offline searchable database)
- `id: String` (UPC or generated UUID)
- `name: String`
- `brand: String`
- `calories: Double`
- `protein: Double`
- `carbs: Double`
- `fat: Double`
- `servingSize: Double`
- `servingUnit: String`
- `barcode: String?` (Indexed for fast scanning lookups)

## UI Architecture

### 1. `DiaryView` (Main Screen)
- **Top Bar:** Current Date (with left/right arrows to change day), "Complete" button.
- **Daily Summary:** A compact version of the Dashboard rings showing Consumed / Remaining calories.
- **Sections:** Four distinct sections: `Breakfast`, `Lunch`, `Dinner`, `Snacks`.
- Each section has a header and an `+ Add Food` button.
- Logged foods inside the section display Name, Calories, and a swipe-to-delete action.
- **Bottom:** "Add Water" and "Add Exercise" (placeholder buttons for now).

### 2. `FoodSearchView` (Full-screen modal)
Triggered by `+ Add Food`.
- **Navigation Bar:** "Cancel" on the left, Title "Add Food" in the middle.
- **Search Bar:** Prominent text field (`TextField`) with a `Barcode Scanner` (camera icon) button overlayed or placed immediately to the right.
- **Segmented Picker:** `All` and `Recent` tabs. 
- **Results List:** Displays `CatalogFoodEntry` matching the query.
- **Item Detail:** Tapping a result expands a detail view with portion size adjustment (e.g., "1.5 serving", "100 g") and macro breakdown.
- **Log Button:** A sticky bottom button: "Log (X cal)".

### 3. `BarcodeScannerView` (Full-screen camera)
- Uses `AVFoundation` to read 1D/2D barcodes.
- Overlays a dark semi-transparent layer with a clear rectangle cutout and a scanning line animation.
- On successful read:
  - Query `CatalogFoodEntry` by barcode.
  - If found: Navigate directly to the `Item Detail` view.
  - If not found: Show "Food not in database" with an option to manually enter it.

## Data Seeding Strategy
- On app launch (`KalaiApp`), check if `CatalogFoodEntry` is empty.
- If empty, run `DataIngestor.loadSeedData()`:
  - Read `foods.json` from the app bundle.
  - Map `CatalogFood` (Codable) to `CatalogFoodEntry` (SwiftData) in batches of 500 to avoid memory spikes.
  - Save the context.

## Theming Constraints
- Strict adherence to `KalaiTheme`.
- Backgrounds: `Dark Charcoal (#1C1E1B)`.
- List Rows: `Muted Olive (#3F4B3B)`.
- Text: `Soft Cream (#F0EAD6)`.
- Accents/Buttons: `Ochre (#C2A895)`.
- No pure black (`#000000`) or pure white (`#FFFFFF`).
- Fluid spring animations on modal presentation and row expansions.

## Testing Strategy
- **Unit Tests:**
  - Verify `FoodRecord` properly associates with `DailyDiary` and respects `mealType`.
  - Verify `CatalogFoodEntry` query by name and barcode returns expected results.
  - Verify data seeding does not duplicate entries on repeated calls.
- **View Compilation Tests:**
  - Ensure `DiaryView`, `FoodSearchView`, and `BarcodeScannerView` compile and render with mock data.
