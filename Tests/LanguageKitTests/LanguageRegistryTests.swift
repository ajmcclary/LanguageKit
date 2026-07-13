import Testing
@testable import LanguageKit

/// Pins ``LanguageRegistry``: construction/validation, lookups mirroring
/// ``LanguageCatalog``, custom-metadata merging, the allowlist, and shebang-line
/// resolution with the shared version-suffix fallback.
@Suite struct LanguageRegistryTests {
    // MARK: - standard

    @Test func standardIsBuiltFromCatalogWithoutTrapping() {
        // Force evaluation of the static; a validation failure would trap here.
        #expect(LanguageRegistry.standard.languages.count == LanguageCatalog.all.count)
        #expect(LanguageRegistry.standard.metadata(for: .swift)?.displayName == "Swift")
    }

    // MARK: - lookups mirror the catalog

    @Test func lookupsMirrorLanguageCatalog() {
        let registry = LanguageRegistry.standard
        #expect(registry.language(forExtension: ".SWIFT")?.id == .swift)
        #expect(registry.language(forExtension: "tsx")?.id == .tsx)
        #expect(registry.language(forFilename: "Dockerfile")?.id == .dockerfile)
        #expect(registry.language(forFilename: "Makefile")?.id == .shell)
        #expect(registry.language(forInterpreter: "python3")?.id == .python)
        #expect(registry.language(forInterpreter: "BASH")?.id == .shell)
        #expect(registry.metadata(for: LanguageID("nope")) == nil)
    }

    // MARK: - validation

    @Test func acceptsAValidCustomRegistry() throws {
        let registry = try LanguageRegistry(languages: [
            LanguageMetadata(id: LanguageID("a"), displayName: "A", fileExtensions: ["a"]),
            LanguageMetadata(id: LanguageID("b"), displayName: "B", fileExtensions: ["b"]),
        ])
        #expect(registry.language(forExtension: "a")?.id == LanguageID("a"))
    }

    @Test func rejectsDuplicateLanguageID() {
        #expect(throws: LanguageRegistryError.duplicateLanguageID(LanguageID("a"))) {
            _ = try LanguageRegistry(languages: [
                LanguageMetadata(id: LanguageID("a"), displayName: "A", fileExtensions: ["a"]),
                LanguageMetadata(id: LanguageID("a"), displayName: "A2", fileExtensions: ["a2"]),
            ])
        }
    }

    @Test func rejectsExtensionOwnedByTwoLanguages() {
        #expect(throws: LanguageRegistryError.duplicateFileExtension(fileExtension: "x", existing: LanguageID("a"), conflicting: LanguageID("b"))) {
            _ = try LanguageRegistry(languages: [
                LanguageMetadata(id: LanguageID("a"), displayName: "A", fileExtensions: ["x"]),
                LanguageMetadata(id: LanguageID("b"), displayName: "B", fileExtensions: ["x"]),
            ])
        }
    }

    @Test func rejectsFilenameOwnedByTwoLanguages() {
        #expect(throws: LanguageRegistryError.duplicateFilename(filename: "makefile", existing: LanguageID("a"), conflicting: LanguageID("b"))) {
            _ = try LanguageRegistry(languages: [
                LanguageMetadata(id: LanguageID("a"), displayName: "A", filenames: ["makefile"]),
                LanguageMetadata(id: LanguageID("b"), displayName: "B", filenames: ["makefile"]),
            ])
        }
    }

    @Test func rejectsDuplicateExtensionWithinOneLanguage() {
        #expect(throws: LanguageRegistryError.duplicateFileExtensionWithinLanguage(fileExtension: "x", language: LanguageID("a"))) {
            _ = try LanguageRegistry(languages: [
                LanguageMetadata(id: LanguageID("a"), displayName: "A", fileExtensions: ["x", "y", "x"]),
            ])
        }
    }

    // MARK: - merging (custom metadata)

    @Test func mergingReplacesExistingIDAndAppendsNewID() throws {
        let base = LanguageRegistry.standard
        let merged = try base.merging([
            // Override Python with a richer interpreter set.
            LanguageMetadata(
                id: .python, displayName: "Python",
                fileExtensions: ["py", "pyw", "pyi"],
                interpreters: ["python", "python3", "python2", "pypy"],
                lspIdentifier: "python", treeSitterGrammarIdentifier: "python"
            ),
            // Add a brand-new language.
            LanguageMetadata(
                id: LanguageID("nim"), displayName: "Nim",
                fileExtensions: ["nim"], interpreters: ["nim"]
            ),
        ])
        // Same number of languages plus one new.
        #expect(merged.languages.count == base.languages.count + 1)
        // Override took effect.
        #expect(merged.metadata(for: .python)?.fileExtensions == ["py", "pyw", "pyi"])
        #expect(merged.language(forInterpreter: "pypy")?.id == .python)
        // New language present.
        #expect(merged.language(forExtension: "nim")?.id == LanguageID("nim"))
        // Base registry is unchanged (immutability).
        #expect(base.metadata(for: .python)?.fileExtensions == ["py", "pyw"])
        #expect(base.metadata(for: LanguageID("nim")) == nil)
    }

    @Test func mergingRejectsAnExtensionThatWouldCollideWithAnotherLanguage() {
        // Adding a new language that claims Swift's extension must throw.
        #expect(throws: LanguageRegistryError.self) {
            _ = try LanguageRegistry.standard.merging([
                LanguageMetadata(id: LanguageID("swiftish"), displayName: "Swiftish", fileExtensions: ["swift"]),
            ])
        }
    }

    // MARK: - restricted (allowlist)

    @Test func restrictedKeepsOnlyRequestedLanguages() {
        // RepoPrompt's 14 parser languages.
        let ids: Set<LanguageID> = [
            .swift, .javascript, .csharp, .python, .c, .rust, .cpp, .go,
            .java, .dart, .typescript, .tsx, .php, .ruby,
        ]
        let restricted = LanguageRegistry.standard.restricted(to: ids)
        #expect(restricted.languages.count == 14)
        #expect(Set(restricted.languages.map(\.id)) == ids)
        // In-set language still resolves.
        #expect(restricted.language(forExtension: "swift")?.id == .swift)
        // Out-of-set language no longer resolves by any index.
        #expect(restricted.metadata(for: .kotlin) == nil)
        #expect(restricted.language(forExtension: "kt") == nil)
        #expect(restricted.language(forFilename: "dockerfile") == nil)
    }

    @Test func restrictedToUnknownIDsYieldsEmptyRegistry() {
        let restricted = LanguageRegistry.standard.restricted(to: [LanguageID("nope")])
        #expect(restricted.languages.isEmpty)
        #expect(restricted.language(forExtension: "swift") == nil)
    }

    // MARK: - shebang-line resolution

    @Test func resolvesLanguageFromShebangLine() {
        let registry = LanguageRegistry.standard
        #expect(registry.language(forShebangLine: "#!/usr/bin/env node")?.id == .javascript)
        #expect(registry.language(forShebangLine: "#!/bin/bash -e")?.id == .shell)
        #expect(registry.language(forShebangLine: "#!/usr/bin/env python3")?.id == .python)
        #expect(registry.language(forShebangLine: "not a shebang") == nil)
    }

    /// The shared fallback: an interpreter with a trailing version suffix
    /// (`python3.12`, `php8`) that has no exact match retries against the
    /// version-stripped base name.
    @Test func resolvesVersionedInterpreterViaFallback() {
        let registry = LanguageRegistry.standard
        #expect(registry.language(forShebangLine: "#!/usr/bin/env python3.12")?.id == .python)
        #expect(registry.language(forShebangLine: "#!/usr/bin/env ruby2.7")?.id == .ruby)
        // php8 is not an exact interpreter, but strips to "php".
        #expect(registry.language(forShebangLine: "#!/usr/bin/php8")?.id == .php)
    }

    @Test func unknownInterpreterStillReturnsNilAfterFallback() {
        #expect(LanguageRegistry.standard.language(forShebangLine: "#!/usr/bin/env perl6") == nil)
    }
}
