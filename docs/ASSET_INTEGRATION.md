# ECHO environment asset integration

The seven supplied images are overlapping presentation sheets, not transparent sprite files. The game uses clean derived sprites and material textures, with repeated designs consolidated into playable families.

| Reference family | In-game use |
| --- | --- |
| Rocky small/medium/large, irregular, porous, spiky, volcanic, fragmented | Five basalt appearances; actual size comes from the level's asteroid radius. Basalt fractures after wall impacts. |
| Frozen/icy and ice shards | Two ice appearances with the faster brittle fracture rule. |
| Purple crystal/veins and crystal shards | Two crystal appearances with the chrono-crystal fracture rule. |
| Metallic, dark/obsidian, ancient tech, ringed | Three alloy appearances. An obsidian appearance gains a thin orbital ring. Alloy never shatters from wall impacts. |
| Stone, cracked, volcanic, overgrown, ancient-carved, rubble | Material finishes on solid wall shapes across the ember, moss and dust themes. |
| Metal, tech, smoked glass, energy/force, crystal, frozen glass | Material finishes on solid wall shapes across the void, ion and ice themes. |
| Straight, corner, T-junction and cross wall pieces | The arena's solid geometry is composed into connected shapes. Only exposed edges glow; bitmap joints are not drawn between touching pieces. |
| Closed/open timed gate, slow field, laser emitter | Dedicated red/cyan gate actuators, a translucent field membrane and a laser housing are bound to their existing simulation states. |
| Rift/teleport, gravity well, locked exit | Already have animated game effects and rules; the new obstacle textures do not replace those recognizable gameplay cues. |

The reference sheets also depict one-way walls, movable platforms, breakable **walls**, invisible walls and other states that are not present as level mechanics. Those are not shown as decorative stand-ins: they would communicate a rule the simulation does not implement. Breakable **asteroids** are implemented and remain distinct from breakable walls.

Asset sources are in `Echo/Resources/Assets.xcassets/`: the original four-material atlases plus `AsteroidVariantAtlasA`, `AsteroidVariantAtlasB`, `WallVariantAtlasA`, `WallVariantAtlasB` and `ObstacleTileAtlas`. `VisualAssetTests` verifies that every generated rock appearance and all twelve wall finishes are reachable in the playable level catalog.
