## 1. Verify and clean InteractiveMuscleMap

- [x] 1.1 Verify imports and API surface of `interactive_muscle_map.dart` to ensure it resolves all XML parsing and SVG drawing dependencies correctly
- [x] 1.2 Verify that `anterior.svg` and `posterior.svg` exist in assets and are referenced correctly in `interactive_muscle_map.dart`

## 2. Integration in ExerciseLibraryPage

- [x] 2.1 Revert `exercise_library_page.dart` to import and use `InteractiveMuscleMap` instead of `InteractiveMuscleModelViewer`
- [x] 2.2 Align callbacks between `ExerciseLibraryPage` and `InteractiveMuscleMap` (e.g. mapping `onGroupSelected` to navigations)
- [x] 2.3 Ensure responsive sizing and bounds match the screen layout appropriately

## 3. Testing and Verification

- [x] 3.1 Verify compile correctness of Flutter application
- [x] 3.2 Verify interactive tapping on regions (shoulders, chest, biceps, triceps, abs, legs, back) correctly displays overlays and info badges
- [x] 3.3 Verify navigation to `ExerciseGroupDetailPage` works from both direct double-tap/region tap or tapping the info badge
