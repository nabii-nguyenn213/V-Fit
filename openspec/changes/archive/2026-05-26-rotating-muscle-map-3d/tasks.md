## 1. Integration in ExerciseLibraryPage

- [x] 1.1 Import `InteractiveMuscleModelViewer` and remove `InteractiveMuscleMap` in `exercise_library_page.dart`
- [x] 1.2 Update the map display block in `exercise_library_page.dart` to render `InteractiveMuscleModelViewer`
- [x] 1.3 Configure selection callback to handle navigation to `ExerciseGroupDetailPage` with both group and `subGroupId` parameters

## 2. Verify Mapping and Sub-group Behavior

- [x] 2.1 Verify subGroup IDs defined in `interactive_muscle_model_viewer.dart` match those in the exercise catalog database / API (e.g., `front-delt`, `side-delt`, `rear-delt`, etc.)
- [x] 2.2 Verify that `ExerciseGroupDetailPage` correctly expands the `initialSubGroupId` matching the selected 3D zone

## 3. Testing and Verification

- [x] 3.1 Verify compile correctness with `flutter analyze`
- [x] 3.2 Verify drag-to-rotate interaction and tapping hit-testing on the 3D model
