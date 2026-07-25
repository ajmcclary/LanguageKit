import Testing
@testable import LanguageKit

/// Pins ``LanguageMetadata``'s ordered-extension contract: `fileExtensions` is an
/// ordered `[String]` whose first element is the canonical/primary extension,
/// surfaced by ``LanguageMetadata/primaryFileExtension``.
@Suite struct LanguageMetadataTests {
    @Test func primaryFileExtensionIsTheFirstElement() {
        let swift = LanguageCatalog.metadata(for: .swift)
        #expect(swift?.fileExtensions == ["swift"])
        #expect(swift?.primaryFileExtension == "swift")

        let cpp = LanguageCatalog.metadata(for: .cpp)
        #expect(cpp?.fileExtensions.first == "cpp")
        #expect(cpp?.primaryFileExtension == "cpp")
    }

    @Test func primaryFileExtensionIsNilWhenNoExtensions() {
        let metadata = LanguageMetadata(id: LanguageID("none"), displayName: "None")
        #expect(metadata.fileExtensions.isEmpty)
        #expect(metadata.primaryFileExtension == nil)
    }

    /// Ordering is CodeEditorKit's deliberate declaration order (ground truth).
    @Test func extensionsPreserveDeclarationOrder() {
        #expect(LanguageCatalog.metadata(for: .javascript)?.fileExtensions == ["js", "jsx", "mjs"])
        #expect(LanguageCatalog.metadata(for: .cpp)?.fileExtensions == ["cpp", "cc", "cxx", "hpp", "hh", "hxx"])
        #expect(LanguageCatalog.metadata(for: .markdown)?.fileExtensions == ["md", "markdown", "mdown", "mkd"])
        #expect(LanguageCatalog.metadata(for: .php)?.fileExtensions == ["php", "phtml", "php3", "php4", "php5"])
    }

    /// Every primary extension in the standard catalog resolves back to its own
    /// language (the primary is never shadowed by another language's extension).
    @Test func everyPrimaryResolvesToItsOwnLanguage() {
        for language in LanguageCatalog.all {
            guard let primary = language.primaryFileExtension else { continue }
            #expect(
                LanguageCatalog.language(forExtension: primary)?.id == language.id,
                "primary \(primary) should resolve to \(language.id)"
            )
        }
    }

    /// For the 14 languages RepoPrompt parses, the primary extension equals
    /// RepoPrompt's `canonicalFileExtension` (they agree with CEP's first entry).
    @Test func primaryMatchesRepoPromptCanonicalExtension() {
        let canonical: [(LanguageID, String)] = [
            (.swift, "swift"), (.javascript, "js"), (.csharp, "cs"), (.python, "py"),
            (.c, "c"), (.rust, "rs"), (.cpp, "cpp"), (.go, "go"), (.java, "java"),
            (.dart, "dart"), (.typescript, "ts"), (.tsx, "tsx"), (.php, "php"), (.ruby, "rb"),
        ]
        for (id, ext) in canonical {
            #expect(LanguageCatalog.metadata(for: id)?.primaryFileExtension == ext, "primary for \(id)")
        }
    }
}
