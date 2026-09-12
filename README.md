# ECHO

ECHO is a top-down temporal survival puzzle for iPhone with 77 maps arranged as 11 seven-map epochs. Clearing the complete timeline starts a new named difficulty cycle while preserving previous records.

The later epochs introduce moving debris, timed crystals, laser arrays, spatial folds, mirrored controls, gravity wells, black holes and a temporary Candy Timeline pocket dimension. The in-game Wiki documents every rule, while Settings includes a confirmed full-progress reset that preserves accessibility/audio preferences.

A path-replay puzzle for iPhone and iPad. You steer a glowing orb, collect sparks, and reach the exit. Every few seconds a copy of you appears and walks the line you already drew. The past is the hazard.

> You don't cooperate with your past. You survive it.

<p align="center">
  <img src="docs/screenshots/01-splash.png" width="220" alt="ECHO splash">
  <img src="docs/screenshots/02-home.png" width="220" alt="Home">
  <img src="docs/screenshots/03-play.png" width="220" alt="Event Horizon arena">
  <br>
  <img src="docs/screenshots/04-shop.png" width="220" alt="Temporal Lab">
  <img src="docs/screenshots/05-research.png" width="220" alt="Timeline Matrix research tree">
  <img src="docs/screenshots/06-ricochet.png" width="220" alt="Ricochet arena">
  <br>
  <img src="docs/screenshots/07-wiki.png" width="220" alt="Timeline Archive wiki">
</p>

## The loop

Drag anywhere. The orb seeks your finger. Sparks open the exit. Echoes replay your path and kill on contact. After the first move, the purple ring at spawn counts down to the next copy.

Seventy-seven maps in eleven seven-map epochs: TRACE, DRIFT, FRACTURE, DEBRIS, PARADOX, SINGULARITY, RIFT, GRAVITY, MIRAGE, CONFECTION, and ETERNITY. Each map has three Temporal Seals — CLEAR, CONTROL, PARADOX. Play continues from the next unbeaten level. Clearing all 77 begins a harder named cycle with faster hazards and a fresh seal record. Arenas shift palette and atmosphere; every map receives route-aware floor landmarks such as trajectory lanes, sector anchors, hazard rings, and reactor diagrams, while clear arenas deliberately omit the heavy nebula haze. A geometry audit verifies every objective, orbit, patrol, laser endpoint, gravity well, and arena boundary.

A crash can **Paradox Rewind** three seconds. The failed branch stays as an unstable echo. After a clear, a short **Temporal Replay** plays the whole route at once.

## Hazards and tools

- **Echoes** — up to five copies. Double-tap to dash.
- **Asteroids** — bounce, patrol, or orbit. Freeze stops them too.
- **Temporal lasers** — generated mechanical emitters telegraph, charge, discharge, and send energy pulses down staggered beams. Event Horizon adds a sweeping beam; Freeze suspends and disarms every laser.
- **Reality rifts** — calm tears freeze time, collapsing tears kill, Warp tears fold space and mirror steering, and Candy tears open a faster pocket timeline with a wider Resonance window.
- **Black holes** — bend movement inside their lensing radius and destroy the timeline at the core. Freeze suspends their pull.
- **Time gates** — bars that vanish and return on a clock. Freeze holds them too.
- **Time collisions** — when two copies occupy the same beat they leave a lethal scar for a few seconds.
- **Paradox ghosts** — a rewind leaves the discarded timeline walking for a few seconds.
- **Timed crystals** — secure them before the ring expires for bonus Freeze time and points. Freeze pauses their countdown.
- **Resonance routes** — collect sparks within 3.25 seconds of one another to build a visible chain and earn a route-planning score bonus.
- **Lab** — equip a limited active loadout, stock charges, and navigate a 12-node Timeline Matrix. Its three branches cover movement and dash recovery, slots/reserves/shield protocol, and cooldown/laser forecast/Freeze/Shift/Rewind research.
- **Timeline Archive** — an in-game wiki covering controls, clocks, rewards, every hazard and skill, the full research tree, and all 77 maps by epoch.

The first time you meet an echo, a rock, a rift, a gate, freeze, phase, or a time collision, a short card explains it. Freeze tints the arena and crystals the orb. Daily Rift uses a stable calendar seed and pays points only on the first clear.

## Requirements

- Xcode 16+ / iOS 18 SDK
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)

```bash
cd Echo
xcodegen generate
xed Echo.xcodeproj
```

Bundle ID `com.sergiiziborov.Echo`.

```bash
xcodebuild test -scheme Echo -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

## Layout

```
Echo/          SwiftUI shell, SpriteKit arena, simulation
EchoTests/     recorder, spawn, collision, rewind, daily, seals
```

`WorldSimulation` is independent of SpriteKit so the rules run in tests.

## License

MIT. © 2026 Sergii Ziborov.
