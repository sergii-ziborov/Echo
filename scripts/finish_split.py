#!/usr/bin/env python3
from pathlib import Path

ROOT = Path("/Users/serhiirihgt/dev/Echo")


def read_lines(path: Path) -> list[str]:
    return path.read_text().splitlines(keepends=True)


def write_text(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if not text.endswith("\n"):
        text += "\n"
    path.write_text(text)


def join(lines: list[str]) -> str:
    return "".join(lines)


def slice_lines(lines: list[str], start: int, end: int) -> list[str]:
    return lines[start - 1 : end]


def demote_private(text: str) -> str:
    replacements = [
        ("    private(set) var ", "    var "),
        ("    private let ", "    let "),
        ("    private var ", "    var "),
        ("    private func ", "    func "),
        ("    private static func ", "    static func "),
        ("    private static let ", "    static let "),
        ("    private static var ", "    static var "),
        ("private struct ", "struct "),
        ("private enum ", "enum "),
        ("private func ", "func "),
    ]
    for old, new in replacements:
        text = text.replace(old, new)
    return text


def extension_file(imports: str, type_name: str, body: str) -> str:
    body = demote_private(body)
    if not body.endswith("\n"):
        body += "\n"
    return f"{imports}\n\nextension {type_name} {{\n{body}}}\n"


def split_catalog_array(src: Path, first_name: str, second_path: Path, second_name: str, split_number: int) -> None:
    lines = read_lines(src)
    split_at = None
    for index, line in enumerate(lines):
        if line.strip() == f"number: {split_number},":
            # walk back to the `make(` that opens this map
            cursor = index
            while cursor > 0 and lines[cursor].strip() != "make(":
                cursor -= 1
            split_at = cursor
            break
    if split_at is None:
        raise SystemExit(f"Could not find map {split_number} in {src}")

    header = [
        "import Foundation\n",
        "\n",
        "extension LevelCatalog {\n",
        f"    static let {second_name}: [LevelDefinition] = [\n",
    ]
    first = join(lines[:split_at]).rstrip() + "\n    ]\n}\n"
    # first currently still has the old static name and an unclosed array; the last
    # map before split_at already ends with `),`
    write_text(src, first)
    write_text(second_path, join(header + lines[split_at:]))


def main() -> None:
    # --- WorldSimulation types ---
    sim = ROOT / "Echo/Simulation/World/WorldSimulation.swift"
    sim_lines = read_lines(sim)
    write_text(
        ROOT / "Echo/Simulation/Core/SimulationTypes.swift",
        "import Foundation\n\n" + join(slice_lines(sim_lines, 3, 65)),
    )
    write_text(sim, join(sim_lines[:2] + sim_lines[66:462] + ["}\n"]))

    # --- Bonuses / Movers ---
    bonuses = read_lines(ROOT / "Echo/Simulation/Rules/Bonuses.swift")
    write_text(ROOT / "Echo/Simulation/Rules/BonusKind.swift", join(slice_lines(bonuses, 1, 214)))
    write_text(
        ROOT / "Echo/Simulation/Rules/UpgradeTree.swift",
        "import Foundation\n\n" + join(slice_lines(bonuses, 216, 505)),
    )
    write_text(
        ROOT / "Echo/Simulation/Rules/SimulationEffects.swift",
        "import Foundation\n\n" + join(slice_lines(bonuses, 507, len(bonuses))),
    )
    (ROOT / "Echo/Simulation/Rules/Bonuses.swift").unlink()

    movers = read_lines(ROOT / "Echo/Simulation/Rules/Movers.swift")
    write_text(ROOT / "Echo/Simulation/Rules/ArenaTheme.swift", join(slice_lines(movers, 1, 114)))
    write_text(
        ROOT / "Echo/Simulation/Rules/MoverTypes.swift",
        "import Foundation\n\n" + join(slice_lines(movers, 116, 294)),
    )
    write_text(
        ROOT / "Echo/Simulation/Rules/LaserTypes.swift",
        "import Foundation\n\n" + join(slice_lines(movers, 296, len(movers))),
    )
    (ROOT / "Echo/Simulation/Rules/Movers.swift").unlink()

    # --- ProgressStore ---
    progress = read_lines(ROOT / "Echo/Simulation/Progress/ProgressStore.swift")
    write_text(
        ROOT / "Echo/Simulation/Progress/ProgressModels.swift",
        "import Foundation\n\n" + join(slice_lines(progress, 3, 7)),
    )
    store = (
        "import Foundation\n\n"
        + demote_private(join(slice_lines(progress, 9, 103)))
        + "\n"
        + demote_private(join(slice_lines(progress, 412, 479)))
        + "}\n"
    )
    write_text(ROOT / "Echo/Simulation/Progress/ProgressStore.swift", store)
    write_text(
        ROOT / "Echo/Simulation/Progress/ProgressCampaign.swift",
        extension_file("import Foundation", "ProgressStore", join(slice_lines(progress, 104, 197))),
    )
    write_text(
        ROOT / "Echo/Simulation/Progress/ProgressEconomy.swift",
        extension_file("import Foundation", "ProgressStore", join(slice_lines(progress, 198, 411))),
    )

    # --- GlowTextures ---
    glow = read_lines(ROOT / "Echo/Arena/Textures/GlowTextures.swift")
    write_text(
        ROOT / "Echo/Arena/Textures/GlowTextures.swift",
        join(slice_lines(glow, 1, 126)) + "}\n",
    )
    write_text(
        ROOT / "Echo/Arena/Textures/GlowTextureDrawing.swift",
        extension_file("import SpriteKit\nimport UIKit", "GlowTextures", join(slice_lines(glow, 128, len(glow) - 1))),
    )

    # --- ArenaActorSync ---
    actor = read_lines(ROOT / "Echo/Arena/Sync/ArenaActorSync.swift")
    write_text(
        ROOT / "Echo/Arena/Sync/ArenaActorSync.swift",
        join(slice_lines(actor, 1, 165)) + "}\n",
    )
    write_text(
        ROOT / "Echo/Arena/Sync/ArenaMoverSync.swift",
        extension_file(
            "import QuartzCore\nimport SpriteKit\nimport UIKit",
            "GameScene",
            join(slice_lines(actor, 167, len(actor) - 1)),
        ),
    )

    # --- Handmade maps ---
    split_catalog_array(
        ROOT / "Echo/Simulation/Catalog/Handmade/HandcraftedMidMaps.swift",
        "handcraftedMid",
        ROOT / "Echo/Simulation/Catalog/Handmade/HandcraftedPressureMaps.swift",
        "handcraftedPressure",
        19,
    )
    split_catalog_array(
        ROOT / "Echo/Simulation/Catalog/Handmade/HandcraftedLateMaps.swift",
        "handcraftedLate",
        ROOT / "Echo/Simulation/Catalog/Handmade/HandcraftedCoreMaps.swift",
        "handcraftedCore",
        31,
    )
    write_text(
        ROOT / "Echo/Simulation/Catalog/Handmade/HandcraftedMaps.swift",
        """import Foundation

extension LevelCatalog {
    static var handcrafted: [LevelDefinition] {
        [prototype] + handcraftedEarly + handcraftedMid + handcraftedPressure + handcraftedLate + handcraftedCore
    }
}
""",
    )

    # --- GameView ---
    game = read_lines(ROOT / "Echo/Play/GameView.swift")
    write_text(ROOT / "Echo/Play/GameView.swift", join(slice_lines(game, 1, 234)) + "}\n")
    write_text(
        ROOT / "Echo/Play/GameViewActions.swift",
        extension_file(
            "import SpriteKit\nimport SwiftUI\nimport UIKit",
            "GameView",
            join(slice_lines(game, 236, 431)),
        ),
    )
    write_text(
        ROOT / "Echo/Play/EncounterCard.swift",
        "import SwiftUI\n\n" + demote_private(join(slice_lines(game, 433, 483))),
    )
    write_text(ROOT / "Echo/Play/HUDBar.swift", "import SwiftUI\n\n" + join(slice_lines(game, 485, 639)))
    write_text(ROOT / "Echo/Play/HUDChrome.swift", "import SwiftUI\n\n" + join(slice_lines(game, 641, len(game))))

    # --- Components ---
    chrome = read_lines(ROOT / "Echo/Shell/Chrome/Components.swift")
    write_text(
        ROOT / "Echo/Shell/Chrome/ChromePrimitives.swift",
        join(slice_lines(chrome, 1, 296)),
    )
    write_text(
        ROOT / "Echo/Shell/Chrome/Demos/MechanicDemoScenario.swift",
        "import SwiftUI\n\n" + join(slice_lines(chrome, 297, 398)),
    )
    write_text(
        ROOT / "Echo/Shell/Chrome/Demos/MechanicDemoView.swift",
        "import SwiftUI\n\n" + join(slice_lines(chrome, 400, 464)) + "}\n",
    )
    write_text(
        ROOT / "Echo/Shell/Chrome/Demos/MechanicDemoCanvas.swift",
        extension_file("import SwiftUI", "MechanicDemoView", join(slice_lines(chrome, 465, 674))),
    )
    write_text(
        ROOT / "Echo/Shell/Chrome/Demos/MechanicDemoBrushes.swift",
        extension_file("import SwiftUI", "MechanicDemoView", join(slice_lines(chrome, 675, 842))),
    )
    write_text(
        ROOT / "Echo/Shell/Chrome/Preview/TechnologyPreviewView.swift",
        "import SwiftUI\n\n" + join(slice_lines(chrome, 846, 1064)) + "}\n",
    )
    write_text(
        ROOT / "Echo/Shell/Chrome/Preview/TechnologyPreviewCanvas.swift",
        extension_file("import SwiftUI", "TechnologyPreviewView", join(slice_lines(chrome, 1066, 1327))),
    )
    write_text(
        ROOT / "Echo/Shell/Chrome/Preview/TechnologyPreviewBrushes.swift",
        extension_file("import SwiftUI", "TechnologyPreviewView", join(slice_lines(chrome, 1328, len(chrome) - 1))),
    )
    (ROOT / "Echo/Shell/Chrome/Components.swift").unlink()

    # --- Shop ---
    shop = read_lines(ROOT / "Echo/Shell/Lab/ShopView.swift")
    write_text(
        ROOT / "Echo/Shell/Lab/ShopView.swift",
        demote_private(join(slice_lines(shop, 1, 351))) + "}\n\n" + demote_private(join(slice_lines(shop, 1146, 1156))),
    )
    write_text(
        ROOT / "Echo/Shell/Lab/ShopResearch.swift",
        extension_file("import SwiftUI\nimport UIKit", "ShopView", join(slice_lines(shop, 352, 638))),
    )
    write_text(
        ROOT / "Echo/Shell/Lab/ShopNodes.swift",
        extension_file("import SwiftUI\nimport UIKit", "ShopView", join(slice_lines(shop, 640, 898))),
    )
    write_text(
        ROOT / "Echo/Shell/Lab/ShopInspectors.swift",
        extension_file("import SwiftUI\nimport UIKit", "ShopView", join(slice_lines(shop, 899, 1144))),
    )
    write_text(
        ROOT / "Echo/Shell/Lab/ResearchIconView.swift",
        "import SwiftUI\n\n" + demote_private(join(slice_lines(shop, 1158, len(shop)))),
    )

    # --- Home / Atlas / Wiki ---
    home = read_lines(ROOT / "Echo/Shell/Home/HomeView.swift")
    write_text(ROOT / "Echo/Shell/Home/HomeView.swift", join(slice_lines(home, 1, 210)))
    write_text(
        ROOT / "Echo/Shell/Home/HomeHero.swift",
        "import SwiftUI\n\n" + demote_private(join(slice_lines(home, 212, 304))),
    )
    write_text(
        ROOT / "Echo/Shell/Home/HomeControls.swift",
        "import SwiftUI\n\n" + demote_private(join(slice_lines(home, 306, 446))),
    )
    write_text(
        ROOT / "Echo/Shell/Home/HomeDecor.swift",
        "import SwiftUI\n\n" + demote_private(join(slice_lines(home, 447, len(home)))),
    )

    worlds = read_lines(ROOT / "Echo/Shell/Atlas/WorldsView.swift")
    write_text(ROOT / "Echo/Shell/Atlas/WorldsView.swift", join(slice_lines(worlds, 1, 241)))
    write_text(
        ROOT / "Echo/Shell/Atlas/AtlasCards.swift",
        "import SwiftUI\n\n" + demote_private(join(slice_lines(worlds, 243, 436))),
    )
    write_text(
        ROOT / "Echo/Shell/Atlas/AtlasNodes.swift",
        "import SwiftUI\n\n" + demote_private(join(slice_lines(worlds, 437, 639))),
    )
    write_text(
        ROOT / "Echo/Shell/Atlas/AtlasChrome.swift",
        "import SwiftUI\n\n" + demote_private(join(slice_lines(worlds, 640, len(worlds)))),
    )

    wiki = read_lines(ROOT / "Echo/Shell/Archive/WikiView.swift")
    write_text(ROOT / "Echo/Shell/Archive/WikiView.swift", join(slice_lines(wiki, 1, 376)))
    write_text(
        ROOT / "Echo/Shell/Archive/WikiPages.swift",
        "import SwiftUI\n\n" + demote_private(join(slice_lines(wiki, 378, len(wiki)))),
    )

    # --- Tests ---
    tests = read_lines(ROOT / "EchoTests/WorldSimulationTests.swift")
    write_text(
        ROOT / "EchoTests/Simulation/Core/PathRecorderTests.swift",
        "import XCTest\n@testable import Echo\n\n" + join(slice_lines(tests, 4, 21)),
    )
    write_text(
        ROOT / "EchoTests/Simulation/Core/StarRatingTests.swift",
        "import XCTest\n@testable import Echo\n\n" + join(slice_lines(tests, 23, 44)),
    )
    write_text(
        ROOT / "EchoTests/Simulation/Core/SimulationTestSupport.swift",
        "import XCTest\n@testable import Echo\n\n" + demote_private(join(slice_lines(tests, 1240, 1246))),
    )
    write_text(
        ROOT / "EchoTests/Simulation/Play/WorldSimulationTests.swift",
        "import XCTest\n@testable import Echo\n\n" + join(slice_lines(tests, 46, 237)) + "}\n",
    )
    write_text(
        ROOT / "EchoTests/Simulation/Hazards/AsteroidSimulationTests.swift",
        extension_file("import XCTest\n@testable import Echo", "WorldSimulationTests", join(slice_lines(tests, 239, 520))),
    )
    write_text(
        ROOT / "EchoTests/Simulation/Hazards/LaserAbilityTests.swift",
        extension_file("import XCTest\n@testable import Echo", "WorldSimulationTests", join(slice_lines(tests, 521, 733))),
    )
    write_text(
        ROOT / "EchoTests/Simulation/Play/RunSystemsTests.swift",
        extension_file("import XCTest\n@testable import Echo", "WorldSimulationTests", join(slice_lines(tests, 734, 989))),
    )
    write_text(
        ROOT / "EchoTests/Simulation/Catalog/LevelGeometryAuditTests.swift",
        "import XCTest\n@testable import Echo\n\n" + demote_private(join(slice_lines(tests, 992, 1238))),
    )
    (ROOT / "EchoTests/WorldSimulationTests.swift").unlink()

    graphics = ROOT / "EchoTests/GraphicsTests.swift"
    visual = ROOT / "EchoTests/VisualAssetTests.swift"
    progress_tests = ROOT / "EchoTests/ProgressStoreTests.swift"
    write_text(ROOT / "EchoTests/Graphics/GraphicsTests.swift", graphics.read_text())
    write_text(ROOT / "EchoTests/Graphics/VisualAssetTests.swift", visual.read_text())
    write_text(ROOT / "EchoTests/Progress/ProgressStoreTests.swift", progress_tests.read_text())
    graphics.unlink()
    visual.unlink()
    progress_tests.unlink()

    print("split complete")


if __name__ == "__main__":
    main()
