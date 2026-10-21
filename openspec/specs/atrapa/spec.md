# Atrapa

## Purpose

A game by Tlatoāni for web, mobile, and desktop, paying homage to the original Atrapa by Bulloncito. Gameplay will be specified separately.

## Requirements

### Requirement: Cross-platform foundation
The project SHALL use Flutter with Flame and include web, Android, iOS, Linux, macOS, and Windows runners.

#### Scenario: Building for a supported target
- **WHEN** a developer builds on a host with the target SDK installed
- **THEN** the same Dart application supplies the first screen

### Requirement: Construction landing page
The app SHALL display Atrapa branding and the exact text "Under Construction" in a responsive first screen.

#### Scenario: Opening the site on a phone or desktop
- **WHEN** a visitor opens the app
- **THEN** the construction message and Tlatoāni attribution are visible without horizontal scrolling

### Requirement: Flame foundation
The landing screen SHALL mount a Flame game for its decorative background, without inventing gameplay.

#### Scenario: Opening the first screen
- **WHEN** the screen loads
- **THEN** Flame renders the decorative arcade scene behind readable Flutter content

### Requirement: Cloudflare hosting
The web build SHALL be served by Wrangler locally and be configured for future publication at atrapa.tlatoani.net.

#### Scenario: Previewing a release build
- **WHEN** a developer builds the web app and starts Wrangler
- **THEN** Wrangler serves the generated Flutter assets locally
