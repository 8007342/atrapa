# Grid gameplay

## Purpose

Provide deterministic growing-snake matches through shared rules used identically by the playable Flame app and offline training.

## ADDED Requirements

### Requirement: Shared grid transition
The game SHALL use a pure-Dart rules package without Flame or Flutter dependencies. Configurations SHALL separate integer substeps per square cell from substeps per simulation second. The default development profile SHALL use four substeps per cell and a slow small arena; the schema SHALL support profiles with three and five substeps per cell.

#### Scenario: Traversing a cell
- **WHEN** a snake advances four substeps in the default profile
- **THEN** its head advances one cell independently of rendered frame count

#### Scenario: Equivalent elapsed time
- **WHEN** the same seeded commands advance over equal elapsed simulation time partitioned into different frames
- **THEN** the authoritative state is identical

### Requirement: Boundary command interpretation
Perpendicular direction presses SHALL queue a turn, with latest press winning and at most one turn consumed per boundary. Same-heading and opposite-heading requests SHALL NOT reverse the snake. Slice A SHALL use constant-speed movement; boost/brake resource effects are post-slice behavior.

#### Scenario: Multiple presses before a boundary
- **WHEN** a human presses two perpendicular directions before a turn boundary
- **THEN** only the latest eligible request applies at that boundary

### Requirement: Players and responsive controls
The development app SHALL support one human against one to three AI snakes, keyboard arrows, and a directional touchpad below the portrait arena. A two-human demo SHALL accept WASD for snake one and arrows for snake two. A match SHALL contain two to four snakes and all inputs SHALL use the shared command interpreter.

#### Scenario: Two humans share a keyboard
- **WHEN** WASD or an arrow direction is pressed in a two-human match
- **THEN** only its assigned human snake receives the direction

#### Scenario: Narrow portrait layout
- **WHEN** play opens in a 320-pixel-wide viewport
- **THEN** the board and controls fit without horizontal overflow and touch targets do not obscure cells

### Requirement: Growth and body collision
Snakes SHALL start at a configured length and grow at configured cell-movement intervals. A head entering a wall or any occupied body, including its own, SHALL lose. Tail occupancy SHALL follow the documented simultaneous-movement rule consistently for surviving and eliminated snakes.

#### Scenario: Self collision
- **WHEN** a snake moves into its own non-vacating body cell
- **THEN** it loses with a body-collision reason

#### Scenario: Scheduled growth
- **WHEN** the configured growth movement is reached
- **THEN** the moving snake retains its tail and increases body length by one

### Requirement: Simultaneous collision and match outcome
Moves SHALL resolve from a common pre-move state. Heads meeting in the same cell or swapping cells SHALL both lose. One remaining snake SHALL win; zero survivors or reaching the configured tick limit without a sole survivor SHALL produce a draw.

#### Scenario: Head swap
- **WHEN** two snakes simultaneously target each other's head cell
- **THEN** both lose in the same transition regardless of iteration order

#### Scenario: One survivor
- **WHEN** a transition leaves one live snake
- **THEN** that snake is the recorded winner and no further movement changes the terminal state

### Requirement: Reachable-free-space baseline
A deterministic baseline opponent SHALL count reachable free cells within a bounded Manhattan distance for candidate directions and prefer the most open safe direction. Opponents due together SHALL choose from the same pre-command state.

#### Scenario: Obstacle ahead
- **WHEN** a safe turn opens more reachable cells than another safe candidate
- **THEN** the baseline selects the more open candidate without bypassing collision rules

### Requirement: Local lifecycle and visible state
The play surface SHALL use Flame's update, pause and resize lifecycle, retain logical state when resized, and visibly identify pause, terminal outcomes, snake identities and baseline or learned-policy source. Restart SHALL create a fresh match. A long-frame catch-up limit SHALL pause rather than skip collision checks.

#### Scenario: Pause and restart
- **WHEN** the user pauses and then restarts the match
- **THEN** paused time does not advance gameplay and restart restores the configured seeded initial match

#### Scenario: Model is unavailable
- **WHEN** no compatible learned model can load
- **THEN** the labeled baseline remains playable rather than claiming a trained opponent is active
