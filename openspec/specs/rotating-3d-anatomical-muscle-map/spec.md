# rotating-3d-anatomical-muscle-map Specification

## Purpose
TBD - created by archiving change rotating-muscle-map-3d. Update Purpose after archive.
## Requirements
### Requirement: Render 3D Rotating Muscle Map
The system SHALL render a custom-painted 3D muscle map of the human body that can be rotated 360 degrees using a horizontal drag gesture or a rotation slider.

#### Scenario: Rotate muscle map
- **WHEN** the user drags horizontally on the muscle map area or drags the rotation slider
- **THEN** the system SHALL rotate the 3D muscle model to the corresponding angle and update the angle text display dynamically.

### Requirement: Hit-Test and Target Detailed Muscle Sub-groups
The system SHALL support hit-testing on detailed muscle zones (such as Vai trước, Vai giữa, Vai sau, Ngực trên, Ngực giữa, Ngực dưới, Lưng, Tay trước, Tay sau, Bụng, Chân đùi) under any rotation angle.

#### Scenario: Tap on front delts
- **WHEN** the user taps on the front delts (Vai trước) zone of the 3D model
- **THEN** the system SHALL select "Vai trước" and highlight the selected zone with a distinct primary color overlay and border.

### Requirement: Navigate to Sub-group Specific Exercises
The system SHALL pass the selected group and sub-group ID when navigating to `ExerciseGroupDetailPage` so that the specific sub-group section is automatically expanded in the exercise list.

#### Scenario: Navigate from selected front delts
- **WHEN** the user taps a highlighted zone or clicks the action button on the toolbar
- **THEN** the system SHALL navigate to `ExerciseGroupDetailPage` passing the group and `subGroupId: 'front-delt'`, which SHALL automatically expand the "Vai trước" section in the list.

