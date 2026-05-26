# detailed-anatomical-muscle-map Specification

## Purpose
TBD - created by archiving change detailed-muscle-map. Update Purpose after archive.
## Requirements
### Requirement: Render Detailed Anatomical SVG Muscle Map
The system SHALL render detailed, anatomically-accurate SVG maps of the human body muscles instead of simplified geometric blocks, showing realistic muscle contours, fibers, and subdivisions.

#### Scenario: View muscle map in library
- **WHEN** the user navigates to the "Thư viện bài tập" tab and chooses "Bản đồ cơ"
- **THEN** the system SHALL display the detailed SVG muscle map corresponding to the selected side (Anterior by default)

### Requirement: Toggle Front and Back Views
The system SHALL provide a toggle mechanism to switch between the Anterior (Mặt trước) and Posterior (Mặt sau) views of the detailed muscle map.

#### Scenario: Switch view to posterior
- **WHEN** the user taps the "Mặt sau" toggle button
- **THEN** the system SHALL load and display the posterior detailed SVG muscle map and clear any active selections from the anterior view

### Requirement: Select and Highlight Muscle Groups
The system SHALL support hit-testing on interactive SVG regions. When a user taps a valid muscle region (such as shoulders, chest, biceps, triceps, abs, legs, back), that region SHALL be highlighted with a distinctive brand primary color overlay and border.

#### Scenario: Tap a muscle group
- **WHEN** the user taps on the chest region in the Anterior view
- **THEN** the system SHALL highlight the chest region SVG path with primary color and show the info badge for "Ngực"

### Requirement: Display Muscle Info Badge
The system SHALL display an interactive floating info badge next to the selected muscle group showing its name and the count of available exercises.

#### Scenario: Show exercise count on selected muscle group
- **WHEN** a muscle group is selected (e.g. "Tay trước")
- **THEN** the system SHALL display a badge showing "Tay trước" and the number of exercises (e.g. "X bài") at the anchor position of the selected region

### Requirement: Navigate to Exercise Details
The system SHALL navigate to the detailed exercise list page for the selected muscle group when the user taps a highlighted region again or taps the info badge.

#### Scenario: Tap info badge to view exercises
- **WHEN** a muscle group is selected and the user taps the floating info badge
- **THEN** the system SHALL navigate to the `ExerciseGroupDetailPage` for that muscle group

