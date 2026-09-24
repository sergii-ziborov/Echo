# ECHO environment asset integration

The seven supplied images are overlapping presentation sheets, not transparent sprite files. The game uses clean derived sprites and material textures, with repeated designs consolidated into playable families.

| Reference family | In-game use |
| --- | --- |
| Rocky small/medium/large, irregular, porous, spiky, volcanic, fragmented | Basalt: a lumpy, cratered silhouette, sometimes with glowing lava veins. Basalt fractures after wall impacts. |
| Frozen/icy and ice shards | Ice: a faceted pale-blue body with the faster brittle fracture rule. |
| Purple crystal/veins and crystal shards | Crystal: violet facets with a glowing cyan core and the chrono-crystal fracture rule. |
| Metallic, dark/obsidian, ancient tech, ringed | Alloy: a gunmetal hull with panel seams, rivets and a gold band. Alloy never shatters from wall impacts. |
| Stone, cracked, volcanic, overgrown, ancient-carved, rubble | Material finishes on solid wall shapes across the ember, moss and dust themes. |
| Metal, tech, smoked glass, energy/force, crystal, frozen glass | Material finishes on solid wall shapes across the void, ion and ice themes. |
| Straight, corner, T-junction and cross wall pieces | The arena's solid geometry is composed into connected shapes. Only exposed edges glow; bitmap joints are not drawn between touching pieces. |
| Closed/open timed gate, slow field, laser emitter | Dedicated red/cyan gate actuators, a translucent field membrane and a laser housing are bound to their existing simulation states. |
| Rift/teleport, gravity well, locked exit | Already have animated game effects and rules; the new obstacle textures do not replace those recognizable gameplay cues. |

The reference sheets also depict one-way walls, movable platforms, breakable **walls**, invisible walls and other states that are not present as level mechanics. Those are not shown as decorative stand-ins: they would communicate a rule the simulation does not implement. Breakable **asteroids** are implemented and remain distinct from breakable walls.

Asteroids are not sprites. `RockShape` and `RockPainter` generate every rock at runtime from a seed drawn when the arena is built, so no two rocks match and a restart brings new ones, while a rewind or replay shows the same rock again. The silhouette encloses the same area as the collision circle. The fault lines that open while a brittle rock fractures are the seams it splits along: each shard is cut from the painted rock and becomes a SpriteKit physics body that keeps the rock's momentum and bounces off the walls. The debris is visual only; the simulation never sees it. Moving rocks are at least radius 30 and 1.2× their authored size (`ArenaMetrics`), so they read next to the orb. Fixed cores keep their size.

Asset sources are in `Echo/Resources/Assets.xcassets/`: the original four-material atlases plus `AsteroidVariantAtlasA`, `AsteroidVariantAtlasB`, `WallVariantAtlasA`, `WallVariantAtlasB` and `ObstacleTileAtlas`. The asteroid atlases remain as reference art only. `VisualAssetTests` verifies that all twelve wall finishes are reachable in the playable level catalog.
