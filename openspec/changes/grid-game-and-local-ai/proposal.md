# Proposal

## Why

Atrapa currently has a construction screen but no playable simulation or opponent decisions. Establish a grid-based, Flame-driven game foundation and an offline-trained local AI pipeline so movement, resource use, and runtime costs can be tuned before committing to artwork or a complete campaign.

## What Changes

- Add square-grid movement with 3–5 discrete substeps per cell, boundary-only turns, keyboard input, and a bottom touchpad in portrait layouts.
- Add exhaustible acceleration and costly braking, a positive minimum speed, temporary resource powerups, and loss on wall or other-snake contact.
- Separate level movement-speed progression from AI difficulty; display EASY/MEDIUM/HARD as HARD/HARDER/HARDERER.
- Schedule local opponent decisions through bounded actor-style messaging with broadcast snapshots and latest-pending replacement; reuse Flame updates and timers.
- Establish offline simulation, baseline opponents, training, small-model packaging, browser runtime comparisons, and an evaluation tournament. Runtime choice and numeric tuning remain evidence-driven.
- Draft the playable UX and a shared live-match viewer: watch paced local exhibitions or sampled training episodes using the same arena/HUD, with explicit live/replay identity and bounded observation delivery.
- Keep the construction landing screen as the public entry while a development gameplay route supports validation; update its existing Flame foundation requirement to allow this extension.
- Record unresolved gameplay semantics as explicit gates rather than inventing self-collision, growth, scoring, or a level-completion rule.

## Capabilities

### New Capabilities

- `grid-gameplay`: Grid traversal, shared controls, resource effects, collision outcomes, initial progression configuration, and responsive play/watch presentation.
- `opponent-scheduling`: Fair asynchronous opponent decision opportunities, bounded work, and stale-result rejection within Flame's lifecycle.
- `local-policy-inference`: Versioned observation/action contracts, local model loading, backend selection, and device measurements.
- `offline-policy-training`: Reusable headless simulation, demonstrations, self-play, reproducible model bundles, acceptance evaluation, and selected episode viewing.

### Modified Capabilities

- `atrapa`: Extend the Flame foundation from decoration-only to support the proposed development gameplay surface while retaining the construction entry.

## Impact

Future implementation touches `lib/game/`, application navigation and controls, tests, and new offline training/benchmark tooling. Browser inference assets may add dependencies and Cloudflare hosting configuration only after a backend is selected; native runners retain their existing platform scope. No vendor inference service, production deployment, art assets, or gameplay code is introduced by this planning change. Offline training may use remote fleet GPUs, including the operator-reported 24 GB RTX A5000 host, after resource and access checks.
