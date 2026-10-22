# Opponent Scheduling

## Purpose

Define fair, bounded local opponent decisions that preserve authoritative gameplay while asynchronous inference runs within Flame-driven match timing.

## ADDED Requirements

### Requirement: Authoritative nonblocking simulation
The match SHALL advance from Flame updates and existing timing facilities without waiting for inference. Decision scheduling SHALL use simulation ticks and eligible cell boundaries, rather than a second independent game clock.

#### Scenario: Inference is unfinished
- **WHEN** an opponent inference request remains unfinished at its application boundary
- **THEN** the match advances using the documented continuation behavior and records the missed deadline

### Requirement: Bounded replaceable work
The scheduler SHALL bound inference work and retain only the latest pending observation when capacity is occupied. Observations SHALL support latest-value broadcast, while authoritative outcomes SHALL use reliable delivery. Discarding a result SHALL NOT be treated as evidence that its computation was cancelled.

#### Scenario: Observations outpace inference
- **WHEN** several snapshots arrive while inference capacity is occupied
- **THEN** pending obsolete observations are replaced without creating an unbounded queue or delaying simulation

#### Scenario: A match ends during inference
- **WHEN** a loss occurs while replaceable snapshots are being superseded
- **THEN** the authoritative outcome remains deliverable and inference completion cannot undo it

### Requirement: Decision identity and expiry
Each decision SHALL identify its match, snake, source observation tick, intended application tick, and deadline. The simulation SHALL reject mismatched, expired, or already superseded decisions, including relative turns whose source heading no longer matches the authoritative heading.

#### Scenario: A turn arrives after heading changes
- **WHEN** an inference result proposes a relative turn from a heading that has since changed
- **THEN** the result is discarded rather than reinterpreted against the new heading

#### Scenario: An earlier match produces a result
- **WHEN** inference completes after its match has ended or been replaced
- **THEN** the result cannot affect the current match

### Requirement: Fair application of simultaneous decisions
Opponents sharing a logical decision opportunity SHALL observe the same authoritative snapshot and apply accepted commands at the designated boundary before subsequent simulation advances. Worker completion order SHALL NOT expose earlier opponents' accepted decisions to later opponents in that opportunity.

#### Scenario: Two opponents finish in different orders
- **WHEN** two eligible opponents return valid decisions before their shared deadline
- **THEN** both decisions use the shared snapshot and the documented simultaneous application rule

### Requirement: Difficulty and speed calibration
EASY, MEDIUM, and HARD SHALL display as HARD, HARDER, and HARDERER respectively. Their decision-opportunity schedules SHALL be configured separately from level movement speed, calibrated against cell-boundary deadlines, and evaluated for difficulty ordering within declared tested operating bounds.

#### Scenario: A level increases movement speed
- **WHEN** a level uses faster movement intervals
- **THEN** its decision schedule is evaluated against the new boundary timing without silently redefining the selected difficulty tier

### Requirement: Observable overload handling
Overload SHALL produce measurable deadline misses, replacements, and rejected results. Recovery SHALL NOT replay accumulated decisions in a burst. Any cadence degradation SHALL remain within documented tested bounds and preserve tier ordering there; unsupported conditions SHALL be reported rather than claiming universal device parity.

#### Scenario: A device cannot sustain the configured schedule
- **WHEN** inference demand exceeds the measured runtime budget
- **THEN** bounded replacement and the documented continuation policy keep the match advancing and telemetry exposes the overload

### Requirement: Time-based resource accounting
Boost and braking consumption SHALL be determined by authoritative simulation time and accepted command duration, independently of inference frequency.

#### Scenario: Equal commands at different decision cadences
- **WHEN** two command schedules produce the same accepted resource action over the same simulation duration
- **THEN** resource consumption is equal regardless of the number of inference calls
