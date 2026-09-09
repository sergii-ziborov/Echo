# ECHO

A path-replay puzzle for iPhone and iPad. You steer a glowing orb, collect sparks, and reach the exit. Every few seconds a copy of you appears and walks the line you already drew. The past is the hazard.

> Every move creates a new you.

<p align="center">
  <img src="docs/screenshots/01-splash.png" width="220" alt="ECHO splash">
  <img src="docs/screenshots/02-home.png" width="220" alt="Home">
  <img src="docs/screenshots/03-play.png" width="220" alt="Arena">
  <img src="docs/screenshots/04-shop.png" width="220" alt="Shop">
</p>

## The loop

Drag anywhere. The orb seeks your finger. Sparks open the exit. Echoes replay your path and kill on contact. A shield eats one hit. Freeze holds echoes, rocks, and rifts still. After the first move, the purple ring at spawn counts down to the next copy.

Thirty maps in World 1 *Awakening*. Play continues from the next unbeaten level. Arenas shift palette — void, ember, moss, ion, ice, dust.

## Hazards and tools

- **Echoes** — up to five copies. Double-tap to dash.
- **Asteroids** — bounce, patrol, or orbit. Freeze stops them too.
- **Time rifts** — open and close. A calm tear skips time. A collapsing one is a collision.
- **Time collisions** — two pasts occupying the same beat. The crack is a warning; later maps make it lethal.
- **Shop** — stock Shield, Freeze, Surge, Phase, Chrono, and extra lives with points from clears. Pulse and Magnet only drop in the arena; you cannot bank those.
- **Lives** — three to start, five max. Continue after a crash spends one. Three stars restore one.

The first time you meet an echo, a rock, a rift, freeze, phase, or a time collision, a short card explains it.

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
EchoTests/     recorder, spawn, collision, shop, lives, layout
```

`WorldSimulation` is independent of SpriteKit so the rules run in tests.

## License

MIT. © 2026 Sergii Ziborov.
