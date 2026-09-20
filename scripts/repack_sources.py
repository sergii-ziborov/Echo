#!/usr/bin/env python3
"""Split oversized Swift sources into focused files and a folder tree."""

from __future__ import annotations

import re
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: Path) -> list[str]:
    return path.read_text().splitlines(keepends=True)


def write(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if not text.endswith("\n"):
        text += "\n"
    path.write_text(text)


def strip_member_private(lines: list[str]) -> list[str]:
    out: list[str] = []
    for line in lines:
        out.append(re.sub(r"^    private ", "    ", line))
    return out


def slice_lines(lines: list[str], start: int, end: int) -> str:
    return "".join(lines[start - 1 : end])


def wrap_extension(imports: str, type_name: str, body: str, extra: str = "") -> str:
    body = body.rstrip() + "\n"
    return f"{imports}\n{extra}extension {type_name} {{\n{body}}}\n"


def split_gamescene() -> None:
    src = ROOT / "Echo/Game/GameScene.swift"
    lines = strip_member_private(read(src))
    imports = "import QuartzCore\nimport SpriteKit\nimport UIKit\n"

    core = "".join(lines[:317]).rstrip()
    if not core.endswith("}"):
        core += "\n}\n"
    else:
        # The class is still open after rebuild(); close it.
        if core.count("{") > core.count("}"):
            core += "\n}\n"
    write(ROOT / "Echo/Arena/Scene/GameScene.swift", core + "\n")

    chunks = [
        ("Echo/Arena/FX/ArenaCombatFX.swift", 319, 516),
        ("Echo/Arena/Build/ArenaFloorBuild.swift", 518, 886),
        ("Echo/Arena/Build/ArenaPickupBuild.swift", 887, 1169),
        ("Echo/Arena/Build/ArenaRockBuild.swift", 1170, 1366),
        ("Echo/Arena/Build/ArenaHazardBuild.swift", 1367, 1631),
        ("Echo/Arena/Sync/ArenaHazardSync.swift", 1632, 1880),
        ("Echo/Arena/Sync/ArenaActorSync.swift", 1881, 2278),
        ("Echo/Arena/Sync/ArenaHudSync.swift", 2279, 2600),
        ("Echo/Arena/FX/ArenaVFXLibrary.swift", 2601, 3310),
        ("Echo/Arena/Geometry/ArenaProjection.swift", 3311, 3514),
    ]
    for rel, start, end in chunks:
        body = slice_lines(lines, start, end)
        # Drop a trailing class-closing brace if present in the last slice.
        if rel.endswith("ArenaProjection.swift"):
            body = re.sub(r"\n\}\s*$", "\n", body)
            extra = "private extension RGB {\n    var uiColor: UIColor { UIColor(red: r, green: g, blue: b, alpha: 1) }\n}\n\n"
            # RGB extension is at the end of the original file; keep it outside GameScene.
            rgb = ""
            if "private extension RGB" in body or "extension RGB" in body:
                parts = re.split(r"\n(?:private )?extension RGB", body, maxsplit=1)
                body = parts[0]
                if len(parts) > 1:
                    rgb = "extension RGB" + parts[1]
                    if not rgb.endswith("\n"):
                        rgb += "\n"
            write(ROOT / rel, wrap_extension(imports, "GameScene", body) + (("\n" + rgb) if rgb else ""))
        else:
            write(ROOT / rel, wrap_extension(imports, "GameScene", body))
    src.unlink()


def split_world_simulation() -> None:
    src = ROOT / "Echo/Model/WorldSimulation.swift"
    lines = strip_member_private(read(src))
    imports = "import Foundation\n"

    # Keep types + class stored state + public API through predictedPath.
    core = "".join(lines[:464])
    if core.count("{") > core.count("}"):
        core = core.rstrip() + "\n}\n"
    write(ROOT / "Echo/Simulation/World/WorldSimulation.swift", core)

    chunks = [
        ("Echo/Simulation/World/SimulationClock.swift", 465, 575),
        ("Echo/Simulation/World/SimulationFields.swift", 576, 744),
        ("Echo/Simulation/World/SimulationCollect.swift", 745, 921),
        ("Echo/Simulation/World/SimulationMovers.swift", 922, 1085),
        ("Echo/Simulation/World/SimulationHistory.swift", 1086, 1182),
    ]
    for rel, start, end in chunks:
        body = slice_lines(lines, start, end)
        if rel.endswith("SimulationHistory.swift"):
            body = re.sub(r"\n\}\s*$", "\n", body)
        write(ROOT / rel, wrap_extension(imports, "WorldSimulation", body))
    src.unlink()


def split_level_definition() -> None:
    src = ROOT / "Echo/Model/LevelDefinition.swift"
    lines = read(src)
    write(ROOT / "Echo/Simulation/Catalog/LevelBlueprint.swift", "".join(lines[:278]))

    catalog_head = """import Foundation

enum LevelCatalog {
    static let worldName = "Awakening"
    static let worldTagline = "You don't cooperate with your past. You survive it."

    static let all: [LevelDefinition] = playable

    static func level(id: String) -> LevelDefinition? {
        all.first { $0.id == id }
    }

    static func level(number: Int) -> LevelDefinition? {
        all.first { $0.number == number }
    }

    static let playable: [LevelDefinition] = (handcrafted + (37...77).map(expandedLevel))
        .map { $0.assigningAsteroidMaterials() }

    static let prototype: LevelDefinition = handcrafted[0]
}
"""
    write(ROOT / "Echo/Simulation/Catalog/LevelCatalog.swift", catalog_head)

    seals = "import Foundation\n\nextension LevelCatalog {\n" + "".join(lines[282:327]) + "}\n"
    write(ROOT / "Echo/Simulation/Catalog/LevelSeals.swift", seals)

    early = "import Foundation\n\nextension LevelCatalog {\n    static let handcraftedEarly: [LevelDefinition] = [\n" + "".join(lines[365:701]) + "    ]\n}\n"
    write(ROOT / "Echo/Simulation/Catalog/HandcraftedEarlyMaps.swift", early)

    mid = "import Foundation\n\nextension LevelCatalog {\n    static let handcraftedMid: [LevelDefinition] = [\n" + "".join(lines[702:1102]) + "    ]\n}\n"
    write(ROOT / "Echo/Simulation/Catalog/HandcraftedMidMaps.swift", mid)

    late = "import Foundation\n\nextension LevelCatalog {\n    static let handcraftedLate: [LevelDefinition] = [\n" + "".join(lines[1103:1608]) + "    ]\n}\n"
    write(ROOT / "Echo/Simulation/Catalog/HandcraftedLateMaps.swift", late)

    # stitch handcrafted
    stitch = """import Foundation

extension LevelCatalog {
    static var handcrafted: [LevelDefinition] {
        handcraftedEarly + handcraftedMid + handcraftedLate
    }
}
"""
    write(ROOT / "Echo/Simulation/Catalog/HandcraftedMaps.swift", stitch)

    expanded = "import Foundation\n\nextension LevelCatalog {\n" + "".join(lines[1613:1891]) + "}\n"
    write(ROOT / "Echo/Simulation/Catalog/ExpandedMaps.swift", expanded)

    factory = "import Foundation\n\nextension LevelCatalog {\n" + "".join(lines[1892:])
    if not factory.rstrip().endswith("}"):
        factory = factory.rstrip() + "\n}\n"
    write(ROOT / "Echo/Simulation/Catalog/LevelFactory.swift", factory)
    src.unlink()


def move(src: str, dst: str) -> None:
    source = ROOT / src
    dest = ROOT / dst
    dest.parent.mkdir(parents=True, exist_ok=True)
    if source.exists():
        shutil.move(str(source), str(dest))


def relocate_small_files() -> None:
    mapping = {
        "Echo/Model/Vec2.swift": "Echo/Simulation/Core/Vec2.swift",
        "Echo/Model/PathRecorder.swift": "Echo/Simulation/Core/PathRecorder.swift",
        "Echo/Model/StarRating.swift": "Echo/Simulation/Core/StarRating.swift",
        "Echo/Model/RenderFrame.swift": "Echo/Simulation/Core/RenderFrame.swift",
        "Echo/Model/Bonuses.swift": "Echo/Simulation/Rules/Bonuses.swift",
        "Echo/Model/Movers.swift": "Echo/Simulation/Rules/Movers.swift",
        "Echo/Model/ProgressStore.swift": "Echo/Simulation/Progress/ProgressStore.swift",
        "Echo/Game/GameSession.swift": "Echo/Play/GameSession.swift",
        "Echo/Game/GameView.swift": "Echo/Play/GameView.swift",
        "Echo/Game/GlowTextures.swift": "Echo/Arena/Textures/GlowTextures.swift",
        "Echo/Graphics/VisualStyle.swift": "Echo/Arena/Graphics/VisualStyle.swift",
        "Echo/Graphics/TrailRenderer.swift": "Echo/Arena/Graphics/TrailRenderer.swift",
        "Echo/Graphics/ActorFactory.swift": "Echo/Arena/Graphics/ActorFactory.swift",
        "Echo/Graphics/AbilityGlyph.swift": "Echo/Arena/Graphics/AbilityGlyph.swift",
        "Echo/Screens/RootView.swift": "Echo/Shell/Home/RootView.swift",
        "Echo/Screens/HomeView.swift": "Echo/Shell/Home/HomeView.swift",
        "Echo/Screens/SplashView.swift": "Echo/Shell/Home/SplashView.swift",
        "Echo/Screens/WorldsView.swift": "Echo/Shell/Atlas/WorldsView.swift",
        "Echo/Screens/ShopView.swift": "Echo/Shell/Lab/ShopView.swift",
        "Echo/Screens/WikiView.swift": "Echo/Shell/Archive/WikiView.swift",
        "Echo/Screens/SettingsView.swift": "Echo/Shell/Session/SettingsView.swift",
        "Echo/Screens/TutorialView.swift": "Echo/Shell/Session/TutorialView.swift",
        "Echo/Screens/DailyChallengeView.swift": "Echo/Shell/Session/DailyChallengeView.swift",
        "Echo/Screens/PauseView.swift": "Echo/Shell/Session/PauseView.swift",
        "Echo/Screens/DeathView.swift": "Echo/Shell/Session/DeathView.swift",
        "Echo/Screens/ResultsView.swift": "Echo/Shell/Session/ResultsView.swift",
        "Echo/Screens/Components.swift": "Echo/Shell/Chrome/Components.swift",
    }
    for src, dst in mapping.items():
        move(src, dst)


def main() -> None:
    split_gamescene()
    split_world_simulation()
    split_level_definition()
    relocate_small_files()
    print("repack complete")


if __name__ == "__main__":
    main()
