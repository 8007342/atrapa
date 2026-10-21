# Roadmap

The active planning package is [grid-game-and-local-ai](../openspec/changes/grid-game-and-local-ai/proposal.md). Its [design](../openspec/changes/grid-game-and-local-ai/design.md) and [task list](../openspec/changes/grid-game-and-local-ai/tasks.md) own implementation dependencies and verification. The package is proposed, not implemented.

- [ ] Review input timing, resource recovery, collision ties/body rules, powerup behavior, and episode completion before dependent gameplay implementation or final training.
- [ ] Apply the grid-game-and-local-ai change in stages: Flame reuse/shared simulation, controls/resources, bounded opponent scheduling, local inference comparison, offline learning, acceptance tournament.
- [ ] Define art guidelines, storyboard, complete campaign, scoring and level unlocks in later discussions and proposals.
- [ ] Validate native builds on Android, iOS, Linux, macOS, and Windows with the appropriate SDKs and signing credentials.
- [ ] Publish the approved web build to Cloudflare at atrapa.tlatoani.net.
