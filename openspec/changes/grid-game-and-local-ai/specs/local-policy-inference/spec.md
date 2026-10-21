# Local Policy Inference

## Purpose

Define a compact, versioned local policy interface whose browser runtime and model size are selected through measured gameplay and device evaluation.

## ADDED Requirements

### Requirement: Numeric observation contract
Policies SHALL consume a versioned numeric observation describing grid geometry, relevant snake occupancy and movement, controlled-snake heading and speed, resources and temporary effects, powerups, and decision timing. The contract SHALL specify shapes, ordering, units, normalization, visibility, and simultaneous-snapshot semantics consistently across training and runtime.

#### Scenario: Training and browser encode the same state
- **WHEN** the same fixture state is encoded offline and in the browser
- **THEN** both encoders produce equivalent observations under the declared schema and numerical tolerance

### Requirement: Shared command authority
Policy outputs SHALL map to versioned game commands for coast, perpendicular turns, acceleration, and braking through the same authoritative rules used by human input. Policies SHALL NOT bypass turn boundaries, resource limits, speed bounds, or collision rules. Relative actions SHALL retain their source heading for stale-result validation.

#### Scenario: A model requests an exhausted resource
- **WHEN** a policy requests acceleration or braking without sufficient resource
- **THEN** the same authoritative resource rule that applies to a human command determines its effect

### Requirement: Verifiable model bundle
A model bundle SHALL declare model version, observation and action schema versions and hashes, artifact integrity hashes, numeric formats, compatible runtime requirements, and output interpretation. Loading SHALL reject incompatible or corrupted bundles before they control opponents.

#### Scenario: Observation schema differs
- **WHEN** a downloaded bundle declares an observation schema hash different from the installed encoder
- **THEN** loading fails visibly and the documented fallback controls the opponent

### Requirement: Local execution and readiness
Browser opponents SHALL execute inference locally without server inference calls. Model loading and warmup SHALL expose readiness and failure state. Once required application and model assets are available locally, inference SHALL require no network access. A documented deterministic fallback SHALL cover unavailable, incompatible, failed, or not-yet-ready inference.

#### Scenario: Network disappears after assets load
- **WHEN** a match starts with required application and model assets available locally and the network is unavailable
- **THEN** opponent inference continues without contacting an inference service

#### Scenario: Model warmup has not completed
- **WHEN** an opponent must act before the model becomes ready
- **THEN** the documented fallback supplies its behavior without blocking the match

### Requirement: Shared weights and isolated agent state
Opponents SHALL be able to share immutable model weights while preserving independent identity, observations, command state, and any recurrent state. Sharing weights SHALL NOT grant access to another opponent's uncommitted decision or undeclared private observation.

#### Scenario: Two opponents use one model bundle
- **WHEN** both opponents make decisions using shared weights
- **THEN** each output corresponds to its own observation and state without cross-agent state leakage

### Requirement: Measured runtime selection
Runtime selection SHALL compare at least a compact Dart evaluator and a WASM inference candidate using equivalent model inputs and weights. Selection SHALL document download size, startup and warmup, memory, sustained inference throughput and latency, frame pacing, and multiple-opponent behavior on declared devices. Numerical budgets SHALL follow measurements rather than assumed latency targets.

#### Scenario: A backend is proposed for adoption
- **WHEN** a benchmark recommends a runtime backend
- **THEN** its recorded results include device and browser versions, model identity, workload, correctness tolerance, and the resulting supported operating bounds

### Requirement: Bounded asynchronous integration
Inference integration SHALL support bounded pending work, deadline-tagged results, and observable completion or failure without blocking authoritative gameplay. Runtime evaluation SHALL distinguish dropping obsolete outputs from actually interrupting computation and include the cost of work that finishes too late.

#### Scenario: A stale computation completes
- **WHEN** computation finishes after its result has expired
- **THEN** the result is discarded and its consumed runtime is still included in performance measurements
