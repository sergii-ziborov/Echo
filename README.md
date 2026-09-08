# ECHO

A minimal puzzle for iPhone and iPad. You steer a glowing orb, collect sparks, and reach the exit. Every few seconds a copy of you appears and replays the path you already took. The past becomes the obstacle.

> Every move creates a new you.

<p align="center">
  <img src="docs/screenshots/01-splash.png" width="280" alt="ECHO splash screen">
</p>

## Promise

Your past is the most dangerous opponent on the board. The first session is usually a pretty loop through the center. The second session is the lesson: send that first line along the edge so the future still has room to move.

This repository is the playable prototype of that hypothesis — one arena, a handful of walls, six sparks, four echoes, instant restart, and a short collision replay. There is no shop, no campaign plot, and no meta-economy. Stars and shards are local session stats.

## Why this loop is first

- The whole cycle can be tested on a single arena.
- The player authors the changing hazard.
- A collision can be explained with a two-second replay instead of a tip card.

That is a claim about the feel of a session, not a claim about retention.

## Stop condition

If people only drive the outer ring, or cannot explain why they died, change the arena and the spark layout. Do not add cosmetics.

The prototype arena puts the exit and one spark in the center so a lap of the walls cannot finish the level.

## Play

- Drag on the arena. The orb seeks your finger at a constant speed.
- You are a hex. Echoes are circles. Color is not the only difference.
- HUD: sparks collected, live echo count, pause. Bottom: countdown to the next copy.
- A warning pulse marks the origin before a copy appears. A closing echo telegraphs its next motion.
- Collision freezes the last seconds and names the copy you met, then restarts.

World 1 *Awakening* has four playable layouts. The rest of the grid is locked on purpose.

## Requirements

- Xcode 16+ / iOS 18 SDK
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)

```bash
cd Echo
xcodegen generate
xed Echo.xcodeproj
```

Destination: any iPhone or iPad simulator, or a development-signed device. Bundle ID is `com.sergiiziborov.Echo`.

```bash
xcodebuild test -scheme Echo -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

## Layout

```
Echo/                 SwiftUI shell, SpriteKit arena, simulation
EchoTests/            recorder, spawn timing, collision, layout invariants
scripts/generate_sounds.py
```

The simulation (`WorldSimulation`) is independent of SpriteKit so the rules can be tested without a scene.

## License

MIT. © 2026 Sergii Ziborov.
