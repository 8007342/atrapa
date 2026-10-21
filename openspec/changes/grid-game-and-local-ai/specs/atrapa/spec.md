# Spec Delta

## MODIFIED Requirements

### Requirement: Flame foundation
The app SHALL use Flame for its decorative landing background and for the development gameplay surface described by the grid-gameplay capability, while retaining the construction landing screen as the default entry.

#### Scenario: Opening the first screen
- **WHEN** the user opens the app
- **THEN** Flame renders the decorative arcade scene behind readable Flutter content
- **AND** the construction landing screen remains the default entry

#### Scenario: Opening development gameplay
- **WHEN** a developer enters the gameplay validation surface
- **THEN** the game runs through Flame's lifecycle with the grid-gameplay behavior
