# Kalai: Minimalist & Free Health Tracker (MFP Architecture)
Date: 2026-09-15

## 1. Overview
Kalai is an iOS health and fitness tracking application designed to provide 1:1 functional parity with MyFitnessPal, but completely reimagined with a dark, earthy, minimal aesthetic and a 100% free, unlocked feature model. Target users are students and fitness enthusiasts who need robust tracking without paywalls or visual clutter.

## 2. Core Functional Requirements (Feature Parity)
Kalai must replicate the mature functionality of a 20-year industry standard app:
- **Comprehensive Diary:** Multi-meal tracking, water intake, active calorie/exercise logging.
- **Deep Nutrition Tracking:** Support for complex serving sizes, dynamic portion multipliers, and granular macro/micro-nutrient logging.
- **Goal Setting:** Daily overarching goals with support for granular, customizable day-to-day macro and calorie targets.
- **Search & Logging Unified:** An instant, robust search engine encompassing text search, barcode scanning, and history. 
- **Offline Reliability:** Core datasets must be available locally.

## 3. Aesthetic & UI Direction
The app will heavily prioritize a calm, focus-driven user experience.
- **Color Palette:** 
  - Backgrounds: Dark Charcoal (`#1C1E1B`), Matte Black (`#111211`)
  - Accents: Muted Olive (`#3F4B3B`), Ochre (`#C2A895`), Earthy Brown (`#8B7E74`)
  - Text: Soft Cream (`#F0EAD6`), Muted Grey (`#8E8E93`)
- **Typography:** Clean, sans-serif, standard weights. Eradicate visual noise.
- **Animations:** Standardized fluid SwiftUI springs (`response: 0.5, dampingFraction: 0.7`) for all transitions, modal presentations, and macro ring animations.
- **Layout:** Flat, card-based UI without aggressive drop shadows.

## 4. Architecture & Engineering Approach
To ensure the #1 priority (bug-free, unbroken functionality), Kalai will be built as a **clean, fresh workspace**, rather than inheriting bugs from the older `Nourish` codebase.

- **Project Generation:** `XcodeGen` will handle project scaffolding (`project.yml`) to ensure a reproducible, clean `.xcodeproj` without merge conflicts.
- **Data Layer (SwiftData):** Complete rewrite of data models to support MFP's complex schemas (e.g., separating `FoodCatalogItem` from the `LoggedFoodItem`).
- **Data Ingestion:** We will utilize the decrypted IPA assets (e.g., `most_popular_foods.json`, `activities_local.json`) to seed a robust local database, ensuring the app feels "mature" and fully populated from day one.
- **Architecture Pattern:** MVVM (Model-View-ViewModel) paired with SwiftData `@Query` for reactive UI updates across the application.

## 5. Security & Deployment
Like its predecessor, Kalai will be configured for local installation.
- Overridden code signing (`CODE_SIGNING_ALLOWED=NO`) to support local/TrollStore deployment.
- Strict Apple privacy adherence for Camera (scanning) and HealthKit (step/active energy tracking).