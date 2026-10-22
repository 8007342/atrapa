# Local policy inference

## Purpose

Load small versioned trained-policy bundles locally and evaluate them through a bounded synchronous Dart runtime with honest baseline fallback.

## ADDED Requirements

### Requirement: Shared numeric contract
The policy SHALL consume the shared rules package's versioned observation and action definitions. The first contract SHALL use 252 numeric observations and coast, left, right action ordering. Offline and app encoding SHALL use the same code; rules/schema changes SHALL update the version and golden replay to signal retraining.

#### Scenario: Same observation offline and in app
- **WHEN** the same rules state is encoded in either runtime
- **THEN** the observation values and ordering match the shared schema

### Requirement: Safe versioned bundles
A bundle SHALL identify its model, rules and observation versions, action ordering, layer dimensions, numeric format, output interpretation and SHA256 of weights. The loader SHALL reject schema, dimension, checksum, finite-value or parameter-limit violations before using the model. FP32 weights SHALL use the documented row-major little-endian layout.

#### Scenario: Corrupted weights
- **WHEN** weight bytes do not match the manifest hash
- **THEN** the loader returns a visible unavailable state and the baseline continues

#### Scenario: Wrong schema
- **WHEN** an export identifies a different rules or observation version
- **THEN** the app rejects it instead of guessing a compatible mapping

### Requirement: Deterministic synchronous evaluation
Valid models SHALL evaluate synchronously in Dart at cell decision opportunities, returning finite logits and a deterministic first-maximum action. Outputs SHALL enter the same authoritative interpreter as human commands. All AI decisions at one opportunity SHALL use the pre-command snapshot.

#### Scenario: Known weight fixture
- **WHEN** the evaluator runs a committed synthetic weight/input fixture
- **THEN** FP32 output error is within 1e-6 of its reference and action choice matches

### Requirement: Readiness and fallback
Loading and evaluation SHALL require no inference server. Missing, invalid or failed model evaluation SHALL use the deterministic baseline and identify the source honestly. Loaded inference SHALL continue without network access; this does not by itself promise offline reload caching.

#### Scenario: Asset bundle is absent
- **WHEN** the expected model asset is unavailable
- **THEN** the local match starts with an explicitly labeled baseline opponent

### Requirement: Runtime measurement
The development integration SHALL report a bounded sample of synchronous decision costs. A reproducible 60-second three-bot measurement SHALL identify device/browser, policy and frame behavior. The initial investigation budget SHALL be 2 ms for all bot decisions at a boundary; physical-phone qualification SHALL remain unclaimed until measured on a named phone.

#### Scenario: Development measurement
- **WHEN** enough decisions are collected for a timing sample
- **THEN** the report identifies policy, sample count and p95 cost without substituting it for a physical-device certification
