import Foundation
import Testing
@testable import LanguageKit

/// Pins ``LanguageID``'s value semantics and its bare-string `Codable` shape.
@Suite struct LanguageIDTests {
    @Test func rawValueAndConvenienceInitAgree() {
        #expect(LanguageID("swift") == LanguageID(rawValue: "swift"))
        #expect(LanguageID("swift").rawValue == "swift")
        #expect(LanguageID.swift == LanguageID("swift"))
    }

    @Test func descriptionIsRawValue() {
        #expect(LanguageID.csharp.description == "csharp")
        #expect("\(LanguageID.plainText)" == "plaintext")
    }

    @Test func encodesAsBareString() throws {
        let data = try JSONEncoder().encode(LanguageID.typescript)
        let json = String(decoding: data, as: UTF8.self)
        #expect(json == "\"typescript\"")
    }

    @Test func roundTripsThroughJSON() throws {
        for language in LanguageCatalog.all {
            let data = try JSONEncoder().encode(language.id)
            let decoded = try JSONDecoder().decode(LanguageID.self, from: data)
            #expect(decoded == language.id, "round-trip for \(language.id)")
        }
    }

    /// A bare string decodes into a `LanguageID` (the persisted form).
    @Test func decodesFromBareString() throws {
        let decoded = try JSONDecoder().decode(LanguageID.self, from: Data("\"rust\"".utf8))
        #expect(decoded == .rust)
    }

    /// Round-trips as a dictionary value too (keyed-container context), and an
    /// unknown id survives the round trip so newer documents still decode.
    @Test func roundTripsInsideAContainerIncludingUnknownIDs() throws {
        struct Wrapper: Codable, Equatable { let language: LanguageID }
        let original = Wrapper(language: LanguageID("some-future-language"))
        let data = try JSONEncoder().encode(original)
        #expect(String(decoding: data, as: UTF8.self) == "{\"language\":\"some-future-language\"}")
        let decoded = try JSONDecoder().decode(Wrapper.self, from: data)
        #expect(decoded == original)
        // Unknown to the catalog, but still a valid identity.
        #expect(LanguageCatalog.metadata(for: decoded.language) == nil)
    }

    @Test func isUsableAsDictionaryKeyAndSetMember() {
        let set: Set<LanguageID> = [.swift, .swift, .go]
        #expect(set == [.swift, .go])
        let map: [LanguageID: Int] = [.swift: 1, .go: 2]
        #expect(map[.swift] == 1)
    }
}
