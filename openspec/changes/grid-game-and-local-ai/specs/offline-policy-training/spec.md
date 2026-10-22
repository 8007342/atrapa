# Offline policy training

## Purpose

Keep macuahuitl training and browser inference on one shared rules contract and preserve reproducible, verifiable small-model exports.

## ADDED Requirements

### Requirement: One authoritative simulator
The trainer SHALL directly import packages/atrapa_rules and use seeded configurations, commands and episode outcomes shared with the app. No independent rules implementation SHALL substitute for it. A committed golden episode SHALL replay equivalently in the rules tests and app test environment.

#### Scenario: Replay a golden episode
- **WHEN** the recorded seed, profile and command schedule are replayed
- **THEN** the final state matches its recorded digest in both environments

### Requirement: Offline compute ownership
Actual gameplay training and retraining SHALL run on macuahuitl rather than the laptop forge. The training workflow SHALL include two to four snakes, the free-space teacher, scripted opposition and self-play. Laptop verification SHALL be limited to fixed fixtures, replay, export validation and inference.

#### Scenario: Rules version changes
- **WHEN** a rules/schema version changes with its golden replay
- **THEN** old incompatible bundles remain rejected until the compute host provides a newly trained compatible export

### Requirement: Reproducible model exports
Exports SHALL include weights, model/schema versions, training provenance, seeds/configuration and reference observations/logits. Slice A SHALL target at most 25,000 parameters while enforcing a runtime cap of 100,000; models outside the target SHALL have explicit measured justification.

#### Scenario: Inspect a host export
- **WHEN** a bundle is proposed as the app's learned opponent
- **THEN** its manifest and provenance identify the exact shared rules and action/observation contract used in training

### Requirement: Export parity and meaningful acceptance
A host FP32 export SHALL match reference logits within its documented numerical tolerance and preserve expected action choice on reference observations. Synthetic toy-grid or XOR models SHALL NOT count as Atrapa training acceptance. Reports SHALL compare the learned policy against the scripted baseline on held-out seeded conditions.

#### Scenario: Provisional infrastructure weights
- **WHEN** weights were trained on a different toy environment
- **THEN** their report remains an infrastructure result and the app does not identify them as a compatible Atrapa opponent

### Requirement: Competitive victory objective
The learned opponent SHALL optimize sole-survivor victory against every other snake independently. Survival duration alone SHALL NOT establish policy strength. Evaluation SHALL report held-out terminal wins, losses and draws by player count and seat, including mutual elimination and timeout rates. The free-space teacher SHALL remain a bootstrap baseline rather than the final objective. Tactical opportunities and representation limitations SHALL follow docs/winning-ai.md.

#### Scenario: Longer survival without more wins
- **WHEN** a candidate survives longer but does not improve terminal victory outcomes against the baseline
- **THEN** it is not promoted on survival duration alone

#### Scenario: Multiplayer competition
- **WHEN** multiple AI snakes compete with a human
- **THEN** each pursues its own victory against all opponents without hidden cooperation or privileged human targeting
