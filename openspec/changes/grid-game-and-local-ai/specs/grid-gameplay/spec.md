# Grid gameplay

## Purpose

Define Atrapa's grid movement, shared player controls, finite speed resources, and level progression before visual and campaign design.

## ADDED Requirements

### Requirement: Grid traversal and turning
The game SHALL represent the arena as square cells, traverse each cell through a configurable integer of 3–5 movement substeps, and apply perpendicular turns only at cell boundaries. Substeps per cell SHALL be configured separately from substeps per second.

#### Scenario: Traversing a cell
- **WHEN** a snake advances with a configured four substeps per cell
- **THEN** four substep advances cross one cell regardless of the configured substep frequency

#### Scenario: Requesting a perpendicular turn
- **WHEN** a snake receives a perpendicular direction while between cell boundaries
- **THEN** its heading changes only at an eligible cell boundary

### Requirement: Human and opponent controls
A match SHALL support one human snake against one or more AI snakes. Human controls SHALL accept keyboard arrow directions and a touchscreen directional touchpad below the play area in portrait layouts. Human and AI commands SHALL obey the same movement and resource rules.

#### Scenario: Playing with a keyboard
- **WHEN** the human presses an arrow key during a match
- **THEN** its direction is interpreted relative to the human snake's current heading

#### Scenario: Playing on a portrait touchscreen
- **WHEN** the human plays in a portrait touch layout
- **THEN** a directional touchpad is available below the play area

#### Scenario: Applying an opponent command
- **WHEN** an AI snake requests a direction or resource action
- **THEN** the simulation applies the same movement constraints and resource limits as for the human

### Requirement: Finite acceleration
Requesting the current direction SHALL accelerate a snake smoothly toward a configured maximum speed while consuming a finite acceleration resource. Exhausted acceleration SHALL prevent further resource-funded acceleration until an allowed resource effect supplies capacity.

#### Scenario: Accelerating with capacity
- **WHEN** a snake requests its current direction with acceleration capacity available
- **THEN** its speed increases smoothly without exceeding its configured maximum and its acceleration resource decreases

#### Scenario: Exhausting acceleration
- **WHEN** acceleration capacity reaches zero
- **THEN** further acceleration requests cannot provide additional resource-funded acceleration

### Requirement: Costly finite braking
Requesting the opposite direction SHALL reduce speed using a costly finite braking resource, without reversing direction or reducing speed below a configured positive minimum. Braking SHALL exhaust after a limited duration of use.

#### Scenario: Braking toward minimum speed
- **WHEN** a snake requests the opposite direction with braking capacity available
- **THEN** its speed decreases, braking capacity is consumed, and the snake continues forward above or at the positive minimum speed

#### Scenario: Exhausting braking
- **WHEN** braking capacity reaches zero
- **THEN** continued opposite-direction requests cannot continue resource-funded braking or stop the snake

### Requirement: Temporary resource powerups
Powerups SHALL appear during play and temporarily extend acceleration or braking resources. Each effect SHALL have an explicit configured duration and resource benefit.

#### Scenario: Receiving a temporary resource effect
- **WHEN** a snake collects a resource powerup
- **THEN** the corresponding resource benefit applies for its configured duration and expires according to that effect's rules

### Requirement: Collision loss
Contact with an arena wall or another snake SHALL cause the contacting snake to lose the match.

#### Scenario: Contacting a wall
- **WHEN** a snake hits an arena wall
- **THEN** that snake loses the match

#### Scenario: Contacting another snake
- **WHEN** a snake hits another snake
- **THEN** the contacting snake loses the match

### Requirement: Level progression and opponent tiers
The first level SHALL use a small arena and slow initial movement. Later levels SHALL support increased baseline movement speed with separately calibrated inference cadence. Internal EASY, MEDIUM, and HARD opponent tiers SHALL display as HARD, HARDER, and HARDERER respectively and control AI decision opportunity frequency separately from level speed.

#### Scenario: Starting the first level
- **WHEN** a player starts the first level
- **THEN** the configured small arena and slow baseline movement apply

#### Scenario: Increasing level speed
- **WHEN** a later level increases baseline movement speed
- **THEN** its inference cadence can be calibrated for that speed independently of the selected opponent tier

#### Scenario: Displaying opponent difficulty
- **WHEN** a player selects EASY, MEDIUM, or HARD internally
- **THEN** the corresponding visible label is HARD, HARDER, or HARDERER

### Requirement: Time and viewport fairness
Movement, resource consumption, and temporary effect duration SHALL depend on simulation time rather than rendered frame count or inference call count. Resizing the viewport SHALL preserve the match's logical arena, snake positions, resources, and movement rules.

#### Scenario: Varying render or inference frequency
- **WHEN** equivalent commands run over equal simulation time with different render or inference frequencies
- **THEN** movement and resource accounting produce equivalent outcomes

#### Scenario: Resizing an active match
- **WHEN** the viewport changes between portrait and landscape
- **THEN** presentation adapts while the logical match state and movement rules remain unchanged
