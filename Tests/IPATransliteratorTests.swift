import XCTest
@testable import PhoneticIM

final class IPATransliteratorTests: XCTestCase {
    private let t = IPATransliterator.shared

    func testGivenSamples() {
        XCTAssertEqual(t.convertAll(code: "thin"), "θɪn")
        XCTAssertEqual(t.convertAll(code: "dhis"), "ðɪs")
        XCTAssertEqual(t.convertAll(code: "xii"), "ʃiː")
        XCTAssertEqual(t.convertAll(code: "shii"), "ʃiː")
        XCTAssertEqual(t.convertAll(code: "faadhq"), "fɑːðə")
        XCTAssertEqual(t.convertAll(code: "qbaut"), "əbaʊt")
    }

    func testLongestMatchPriority() {
        XCTAssertEqual(t.convertAll(code: "th"), "θ")
        XCTAssertEqual(t.convertAll(code: "sh"), "ʃ")
        XCTAssertEqual(t.convertAll(code: "ch"), "tʃ")
        XCTAssertEqual(t.convertAll(code: "ng"), "ŋ")
        XCTAssertEqual(t.convertAll(code: "ii"), "iː")
        XCTAssertEqual(t.convertAll(code: "aa"), "ɑː")
        XCTAssertEqual(t.convertAll(code: "uu"), "uː")
        XCTAssertEqual(t.convertAll(code: "aw"), "ɔː")
        XCTAssertEqual(t.convertAll(code: "ei"), "eɪ")
    }

    func testUnknownCharactersPreserved() {
        XCTAssertEqual(t.convertAll(code: "abc-123"), "æbtʃ-123")
    }

    func testIncrementalLeavesPendingForOneChar() {
        let result = t.convertIncremental(buffer: "th")
        XCTAssertEqual(result.committed, "θ")
        XCTAssertEqual(result.pending, "")

        let result2 = t.convertIncremental(buffer: "t")
        XCTAssertEqual(result2.committed, "")
        XCTAssertEqual(result2.pending, "t")
    }
}
