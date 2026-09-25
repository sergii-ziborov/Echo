import XCTest
@testable import Echo

@MainActor
final class WikiCoverageTests: XCTestCase {
    func testEveryArchiveSection() {
        let model = CoverageFixtures.model()
        for section in WikiSection.allCases {
            CoverageHost.render(WikiView(section: section).environment(model))
        }
        CoverageHost.render(CoverageFixtures.rooted(.wiki, model: CoverageFixtures.model(rich: false)))
        XCTAssertEqual(WikiSection.allCases.count, 6)
        XCTAssertEqual(WikiSection.launch, .basics)
    }
}
