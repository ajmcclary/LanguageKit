import Testing
@testable import LanguageKit

/// Mirrors RepoPrompt's Task-5 characterization table
/// (`SyntaxManagerLanguageCatalogCharacterizationTests`) and asserts the
/// LanguageKit union represents every one of its 14 languages faithfully,
/// including the grammar identifiers from RepoPrompt's `tree_sitter_<id>()`
/// switch (the authoritative source for these values).
@Suite struct RepoPromptParityTests {
    /// A RepoPrompt row: its 1:1 extension, the canonical LanguageKit id it
    /// maps onto, RepoPrompt's `displayName`, and the grammar identifier
    /// RepoPrompt's `languagePointerAndName(for:)` switch uses.
    struct RPRow {
        let ext: String
        let canonicalID: LanguageID
        let displayName: String
        let grammar: String
    }

    /// From RepoPrompt's `extensionToLanguage` (1:1) + grammar switch. The
    /// `canonicalID` column records how each RepoPrompt `LanguageType` maps to a
    /// LanguageKit ``LanguageID`` (js->javascript, cs->csharp, ts->typescript,
    /// rb->ruby, tsx->tsx as its own language).
    static let rp: [RPRow] = [
        RPRow(ext: "swift", canonicalID: .swift, displayName: "Swift", grammar: "swift"),
        RPRow(ext: "js", canonicalID: .javascript, displayName: "JavaScript", grammar: "javascript"),
        RPRow(ext: "cs", canonicalID: .csharp, displayName: "C#", grammar: "c_sharp"),
        RPRow(ext: "py", canonicalID: .python, displayName: "Python", grammar: "python"),
        RPRow(ext: "c", canonicalID: .c, displayName: "C", grammar: "c"),
        RPRow(ext: "rs", canonicalID: .rust, displayName: "Rust", grammar: "rust"),
        RPRow(ext: "cpp", canonicalID: .cpp, displayName: "C++", grammar: "cpp"),
        RPRow(ext: "go", canonicalID: .go, displayName: "Go", grammar: "go"),
        RPRow(ext: "java", canonicalID: .java, displayName: "Java", grammar: "java"),
        RPRow(ext: "dart", canonicalID: .dart, displayName: "Dart", grammar: "dart"),
        RPRow(ext: "ts", canonicalID: .typescript, displayName: "TypeScript", grammar: "typescript"),
        RPRow(ext: "tsx", canonicalID: .tsx, displayName: "TSX", grammar: "tsx"),
        RPRow(ext: "php", canonicalID: .php, displayName: "PHP", grammar: "php"),
        RPRow(ext: "rb", canonicalID: .ruby, displayName: "Ruby", grammar: "ruby"),
    ]

    @Test func repoPromptHasFourteenLanguages() {
        #expect(Self.rp.count == 14)
        #expect(Set(Self.rp.map(\.canonicalID)).count == 14)
    }

    /// Every RepoPrompt extension resolves through the catalog to the language
    /// RepoPrompt mapped it to (its 1:1 `extensionToLanguage` table).
    @Test func everyRepoPromptExtensionResolvesToItsLanguage() {
        for row in Self.rp {
            #expect(
                LanguageCatalog.language(forExtension: row.ext)?.id == row.canonicalID,
                "extension \(row.ext) -> \(row.canonicalID)"
            )
        }
    }

    @Test func displayNamesMatchRepoPrompt() {
        for row in Self.rp {
            #expect(
                LanguageCatalog.metadata(for: row.canonicalID)?.displayName == row.displayName,
                "displayName for \(row.canonicalID)"
            )
        }
    }

    /// The tree-sitter grammar identifiers come from RepoPrompt (the working
    /// implementation) verbatim -- including `c_sharp` for C# and `tsx` for TSX.
    @Test func grammarIdentifiersMatchRepoPrompt() {
        for row in Self.rp {
            #expect(
                LanguageCatalog.metadata(for: row.canonicalID)?.treeSitterGrammarIdentifier == row.grammar,
                "grammar for \(row.canonicalID)"
            )
        }
    }
}
