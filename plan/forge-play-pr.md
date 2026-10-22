# Add the playable Flame slice and shared Dart rules

Base: `game`
Head: `work/forge-play`
Compare/create: https://github.com/8007342/atrapa/compare/game...work/forge-play?expand=1

Atrapa now has a flag-gated `/play` prototype driven by one pure-Dart rules package: growing snakes, simultaneous collision outcomes, free-space baseline opponents, portrait touch controls, and a WASD/arrow two-human duel. A defensive local policy loader/evaluator consumes the documented versioned 252-input contract and falls back visibly when no compatible model is available.

This applies the accepted design review/operator rulings and carries the cache evidence/diagnostic corrections from main into game. Training stays on macuahuitl; actual learned-weight parity remains pending its export. Default production builds retain the construction entry with play disabled.

Validation: rules and app/policy/route/replay tests, Flutter/rules analysis, strict OpenSpec validation, default and flagged release web builds, visible desktop and portrait Chromium inspection. Synthetic three-pass inference was measured in the VM and browser; it is not a physical-phone qualification. See docs/measurements/forge-play.md.
