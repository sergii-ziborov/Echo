import SpriteKit
import XCTest
@testable import Echo

@MainActor
final class ArenaDebrisTests: XCTestCase {
    func testShatterReplacesTheRockWithPhysicalShards() throws {
        let level = try XCTUnwrap(LevelCatalog.level(number: 33))
        let session = GameSession(level: level, daily: false)
        let scene = GameScene(session: session, size: CoverageHost.size)
        CoverageHost.present(scene)
        XCTAssertEqual(scene.physicsWorld.gravity, .zero)
        XCTAssertEqual(scene.children.filter { $0.name == "debrisWall" }.count, level.walls.count)

        let rock = try XCTUnwrap(session.sim.movers.first { $0.material.isBreakable })
        scene.asteroidImpact(id: rock.id, material: rock.material, at: rock.position)
        scene.asteroidShatter(id: rock.id, material: rock.material, at: rock.position)
        XCTAssertNil(scene.moverNodes[rock.id])
        let shards = scene.children.filter { $0.name == "rockShard" }
        XCTAssertFalse(shards.isEmpty)
        XCTAssertTrue(shards.allSatisfy { $0.physicsBody?.isDynamic == true })
        CoverageHost.teardown()
    }

    func testFaultsOpenAsTheRockFractures() throws {
        let level = try XCTUnwrap(LevelCatalog.level(number: 33))
        let session = GameSession(level: level, daily: false)
        let scene = GameScene(session: session, size: CoverageHost.size)
        CoverageHost.present(scene)
        let rock = try XCTUnwrap(session.sim.movers.first { $0.material.isBreakable })
        let body = try XCTUnwrap(scene.moverNodes[rock.id]?.childNode(withName: "rock"))
        let faults = body.children.filter { $0.name == "fault" }
        XCTAssertFalse(faults.isEmpty)
        scene.syncFaults(body, progress: 0, frozen: false)
        XCTAssertTrue(faults.allSatisfy { $0.alpha == 0 })
        scene.syncFaults(body, progress: 1, frozen: false)
        XCTAssertTrue(faults.allSatisfy { $0.alpha == 1 })
        CoverageHost.teardown()
    }
}
