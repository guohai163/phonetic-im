import XCTest
@testable import PhoneticIM

final class DictionaryVariantTests: XCTestCase {
    override func tearDown() {
        super.tearDown()
        UserDefaults.standard.removeObject(forKey: "ipa.dictionary.variant")
    }

    func testDictionaryVariantDefaultsToEnUK() {
        UserDefaults.standard.removeObject(forKey: "ipa.dictionary.variant")

        XCTAssertEqual(KeyboardSettings.loadDictionaryVariant(), .enUK)
    }

    func testDictionaryVariantPersistsSelection() {
        KeyboardSettings.saveDictionaryVariant(.enUS)

        XCTAssertEqual(KeyboardSettings.loadDictionaryVariant(), .enUS)
    }

    func testDictionaryServiceUsesCurrentVariantLookup() async {
        let service = DictionaryService(initialVariant: .enUK) { variant in
            switch variant {
            case .enUK:
                return ["tomato": ["təˈmɑːtəʊ"]]
            case .enUS:
                return ["tomato": ["təˈmeɪɾoʊ"]]
            }
        }

        let uk = await service.lookup(word: "tomato")
        XCTAssertEqual(uk.first?.ipa, "təˈmɑːtəʊ")

        service.switchVariant(.enUS)

        let us = await service.lookup(word: "tomato")
        XCTAssertEqual(us.first?.ipa, "təˈmeɪɾoʊ")
    }
}
