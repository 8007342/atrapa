# Offline Policy Training

## Purpose

Define reproducible offline learning and evaluation that produces small local opponent policies while preserving Atrapa's authoritative gameplay and timing contracts.

## ADDED Requirements

### Requirement: Shared authoritative simulation
The training system SHALL reuse the authoritative gameplay rules through a headless interface, with explicit elapsed simulation time, seeded randomness, configurable arenas, command schedules, and replayable outcomes. It SHALL NOT create a competing gameplay clock or independently reimplement movement, collision, or resource rules.

#### Scenario: Replay a training episode
- **WHEN** an episode is replayed with the same rules version, seed, configuration, elapsed-time sequence, and commands
- **THEN** its authoritative states and outcomes match the recorded episode independently of rendering and inference wall time

### Requirement: Unresolved gameplay gate
Training experiments SHALL identify provisional rules and SHALL NOT label a policy ready for final gameplay until growth, self-collision, match completion, and powerup semantics have been reviewed and resolved in the gameplay contract. Experiments before that gate SHALL record their assumptions and require reevaluation after relevant rule changes.

#### Scenario: Evaluate before gameplay review
- **WHEN** a candidate is trained while a required gameplay semantic remains unresolved
- **THEN** its report identifies the unresolved rule and marks its results provisional rather than claiming final gameplay readiness

### Requirement: Progressive offline learning
The training pipeline SHALL establish scripted opponents and demonstration baselines, support imitation learning, and evaluate subsequent self-play against varied opponents and a versioned pool of historical policies. Training SHALL occur offline; deployed matches SHALL use packaged policy inference without requiring online training or a hosted decision service.

#### Scenario: Promote a self-play candidate
- **WHEN** a self-play candidate is evaluated for promotion
- **THEN** its results include comparisons with scripted baselines and historical policies rather than only its current training opponent

### Requirement: Temporal training fidelity
Training and evaluation SHALL exercise level speed, resource state, opponent count, and difficulty-specific decision schedules. They SHALL model delayed or missing inference results, action expiry, and stale-result rejection using the gameplay and scheduling contracts. Randomization SHALL include documented cadence and latency ranges without granting actions unavailable to a human controller.

#### Scenario: Train with delayed decisions
- **WHEN** a simulated inference result arrives after its allowed application boundary
- **THEN** the episode rejects it and follows the same continuation and command-expiry rules as the runtime

### Requirement: Reproducible policy bundles
Each candidate SHALL have a versioned manifest identifying architecture, parameter count, precision, weight and schema hashes, observation normalization, action meanings, gameplay version, training configuration, seeds, provenance, and evaluation results. Bundle metadata SHALL permit reproducing an experiment and detecting incompatible runtime contracts.

#### Scenario: Inspect an exported candidate
- **WHEN** an evaluator loads a candidate bundle
- **THEN** its manifest identifies the exact weights, input/output contracts, training configuration, and gameplay version used to produce it

### Requirement: Small policy experiments
The pipeline SHALL compare small policy architectures and exported precision options against measured playing quality and runtime costs. A proposed 10,000–100,000-parameter policy and approximately 40–400 KB of float32 weights SHALL be treated as an initial experiment estimate, excluding runtime and metadata overhead, rather than a promised trained outcome or an acceptance budget.

#### Scenario: Compare candidate sizes
- **WHEN** a candidate exceeds the initial size estimate or a smaller candidate plays poorly
- **THEN** the comparison records measured quality and total delivery costs and leaves selection to the acceptance criteria

### Requirement: Held-out acceptance tournament
Candidate evaluation SHALL use held-out maps, seeds, opponents, and schedule combinations separated from training and tuning. Reports SHALL compare survival, match outcomes, collision behavior, resource use, and difficulty ordering across level speeds. Numerical acceptance thresholds and minimum sample counts SHALL be recorded before final candidate selection, including uncertainty in reported outcomes.

#### Scenario: Evaluate difficulty ordering
- **WHEN** a candidate is tested under HARD, HARDER, and HARDERER decision schedules
- **THEN** its report compares outcomes on the same held-out conditions and records any failure of the intended difficulty ordering

### Requirement: Export and runtime parity
An exported policy SHALL be checked against its training representation on a fixed observation corpus and replay scenarios, using documented numerical tolerances and action-agreement criteria. Reduced precision or backend changes SHALL trigger renewed parity and gameplay evaluation before acceptance.

#### Scenario: Quantize a candidate
- **WHEN** a candidate is exported at reduced precision
- **THEN** its report records output differences, action agreement, and tournament effects before treating that artifact as interchangeable with the training model

### Requirement: Device-based runtime evidence
Acceptance SHALL include real-device browser measurements of cold and warm startup, inference p50 and p95 latency, deadline misses, frame pacing, memory, transferred and unpacked download size, and sustained multi-opponent operation. Measurements SHALL identify device, browser, backend, model, level speed, and cadence; desktop training throughput SHALL NOT substitute for target-device evidence.

#### Scenario: Assess a mobile candidate
- **WHEN** a candidate is proposed for browser use on the supported mobile device range
- **THEN** its acceptance report includes sustained runtime measurements on representative real mobile devices under the intended opponent load

### Requirement: Verified offline compute allocation
Training plans SHALL treat the reported 20-core Intel i9, 64 GB RAM, and 24 GB RTX A5000 fleet host as unverified available capacity until access, resources, and scheduling are checked. Plans SHALL keep training language and framework evidence-driven, respect the repository's automation policy, and require an explicit operational allocation before launching remote GPU jobs.

#### Scenario: Prepare remote training
- **WHEN** an experiment proposes use of a remote fleet GPU
- **THEN** the plan records verified access, actual device capacity, resource allocation, and reproducible execution details before any remote job starts

### Requirement: Selected episode viewing
The training workflow SHALL support selecting an episode for observation and running a paced local exhibition with a versioned policy. Views SHALL identify live feed, exhibition, or replay, along with episode, policy, rules version, source tick and playback lag where applicable. Viewing SHALL reuse the gameplay arena presentation without requiring a renderer in headless workers.

#### Scenario: Watching training progress
- **WHEN** a user selects an available training episode feed
- **THEN** the viewer displays its authoritative snapshots and reliable outcomes with source identity and freshness

#### Scenario: Watching without an active training feed
- **WHEN** the user starts a local exhibition from a compatible saved policy
- **THEN** the shared simulation runs at a visible pace and the surface identifies it as an exhibition rather than live training

### Requirement: Observation does not backpressure learning
Training observation SHALL use bounded, replaceable visual snapshots separately from learning transitions and reliable episode events. A slow or paused viewer SHALL NOT slow the trainer, drop its required learning data, or mutate the observed match. Reconnection SHALL restore a consistent snapshot and retained outcome or explicitly report unavailable history.

#### Scenario: Viewer falls behind
- **WHEN** a browser cannot render every emitted training snapshot
- **THEN** obsolete visual snapshots are replaced while simulation, learning records and terminal outcome processing continue independently

#### Scenario: Viewer pauses and reconnects
- **WHEN** the user pauses or disconnects from a remotely running training episode
- **THEN** training continues and reconnecting shows current consistent state or a visible unavailable status rather than replaying a stale command backlog
