# Winning opponents: design and training handoff

User clarification, 2026-10-22: an opponent should try to win by making the human
and other snakes lose, rather than merely surviving. This extends the accepted
cutoff/enclosure strategy in [the rulings](../plan/rulings-2026-10-21.md).
Status: design guidance, not evidence of implemented tactics or trained ability.
Macuahuitl (Claude) owns training; this forge owns app integration, rules evolution,
replays and runtime validation. No new rules or observation schema are introduced
by this document.

## Objective and guardrails

Terminal sole-survivor victory is the principal objective. Death is a loss and a
tick-limit/all-dead result is a draw under current rules. Survival duration is a
secondary diagnostic, not the success criterion. A positive reward every tick can
make safe circling more profitable than winning; any shaping must be bounded,
reported separately, and tested against this failure mode. First establish an
outcome-only training/evaluation baseline before adding shaping.

Avoid unvalidated kill bonuses: elimination has no unambiguous causal owner, a
mutual head collision is not a win, and a suicidal attacker can benefit a third
snake. Evaluate whether territorial or elimination shaping actually improves
terminal outcomes. Do not promote a policy solely because a proxy score rises.

Every AI independently competes against every remaining player, including other
AIs. Human identity is not a privileged target signal; no hidden team play,
shared private intentions, or scripted sacrifices for another bot. Rationally
avoiding a dangerous confrontation is compatible with winning. Aggression is a
means, not a requirement to attack at every opportunity.

Candidate tactics include reaching a chokepoint before a rival; safely cutting
off an escape route; enclosing a rival while preserving one's own route; and
intercepting a predicted path without causing a head swap or shared-cell death.
These are desired outcomes, not claims that the present baseline performs them.

## Current representation and training path

The current free-space teacher chooses locally reachable empty space. Imitating
it bootstraps safe movement but does not supply an explicit competitive objective.
The 252-input encoder provides an absolute-axis, head-centered 9x9 occupancy and
other-head window, own heading/speed, and four clear rays. It does not explicitly
encode opponent headings, identities, global connected territory, growth phase,
or remaining match horizon. Some motion may be inferred from visible bodies,
but a memoryless policy cannot reliably reconstruct omitted state in all cases.

Start with the committed schema and evaluate these limitations before requesting
changes. A full-state teacher/search may label different actions for identical
student observations: log these aliasing cases rather than assuming the student
can learn unavailable information. If changes are justified, the forge versions
rules/observation contracts, refreshes goldens, and requests retraining. Never
silently append inputs, introduce hidden teacher features at runtime, or change
the three-action contract.

Suggested host sequence:

1. Establish held-out free-space, random/legal and historical-policy baselines.
2. Bootstrap imitation, then optimize actual match outcomes in self-play with a
   diverse opponent pool; retain older checkpoints to detect cycling strategies.
3. Investigate offensive teacher/search labels using the shared simulator, with
   safe escapes and simultaneous opponent responses considered. Distill only
   when the compact student demonstrates a measured benefit.
4. Evaluate two-, three- and four-player matches across seats, seeds and speeds;
   include exploiters or adversarial scripted opponents and replay failures.
5. Deliver the normal [policy bundle](policy-bundle.md), parity corpus,
   provenance, tournament results and representative win/loss/draw replays.

The forge can add deterministic fixtures, render replays and measure inference.
It does not run gameplay training. Any larger teachers/search are host-side
experiments; browser models remain within the existing bundle budget.

## Proposed tactical fixture suite

These are construction recipes, not runnable or validated fixtures. Implementers
must commit exact valid nonoverlapping state/config, seed, command schedule and
expected outcomes before treating them as tests. Use paired mirrored/rotated
layouts and swap player seats. Suggested seed labels below are fixed identifiers;
explicit geometry, not the seed alone, establishes the tactical opportunity.

| Seed | Constructed situation | Evidence to inspect |
|---|---|---|
| 22101 | Two snakes approach a narrow passage; the candidate can safely close it before the rival arrives, or retreat into a large loop. | Chooses a viable cutoff and converts to a sole-survivor win against fixed responses; avoids premature shared-cell collision. |
| 22102 | A rival enters a pocket with two exits; one can be sealed while the candidate retains an outside route. | Seals the useful exit and survives the subsequent trap; does not seal itself in. |
| 22103 | A head-on interception offers mutual elimination; a perpendicular escape offers a later winning line. | Rejects the suicidal shortcut and wins against the specified continuation. |
| 22104 | In a three-snake match, attacking the closest rival hands victory to the third; another route preserves a winning chance. | Outcomes favor independent victory rather than a local elimination bonus. |
| 22105 | A spacious loop permits a tick-limit draw; a reachable chokepoint enables a forced win against a fixed passive opponent. | Converts the opportunity rather than repeating the loop until timeout. |
| 22106 | The candidate is behind a separating body wall with no safe immediate attack. | Preserves an escape instead of blindly chasing the nearest head; later conversion is evaluated separately. |
| 22107 | Two full states share the same local observation but differ in an unseen rival route/heading. | Quantifies conflicting optimal labels and representation limits; no demand for impossible perfect decisions from identical inputs. |

A tactical fixture should establish whether a winning line actually exists by
bounded search or documented opponent continuations. Passing a fixed continuation
is evidence for that situation, not proof of general tactical strength.

## Acceptance report

Pre-register the held-out seed/configuration set and promotion thresholds before
selecting a checkpoint. Report terminal win/loss/draw rates with sample counts and
uncertainty, including results by player count, seat, speed and opponent type.
Use paired games against the free-space baseline and historical candidates;
exclude training seeds and tactical fixtures used for teacher labels from the
held-out generalization claim. Preserve losses and timeouts, not just highlights.

Promotion should show a statistically supported win-rate improvement against the
baseline without unexplained regressions in multiplayer or seats. Report tactical
conversion rate only on validated winnable fixtures, mutual-elimination rate,
self-collision rate, tick-limit draw rate and duration conditional on outcome.
Reject a survival-only claim when longer episodes or territory scores rise but
wins do not. Flag repetitive timeout paths; rerun without shaping and against
opponents that punish the loop. Retain model size, parity and browser latency
requirements alongside strength: a winning teacher alone is not a ready browser
policy.
