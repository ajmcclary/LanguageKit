import Testing
@testable import LanguageKit

/// Characterizes the LanguageKit union catalog itself against an inline literal
/// table, so any change to the registry is a reviewable diff. The two
/// source-catalog parity suites (`CodeEditorKitParityTests`,
/// `RepoPromptParityTests`) additionally pin that this union stays faithful to
/// each origin.
@Suite struct LanguageCatalogTests {
    /// One expected row per registered language. `fileExtensions`, `filenames`,
    /// and `interpreters` are written sorted for a stable comparison (the
    /// catalog stores them as `Set`s).
    struct Row: Equatable {
        let id: String
        let displayName: String
        let fileExtensions: [String]
        let filenames: [String]
        let interpreters: [String]
        let lspIdentifier: String?
        let grammar: String?
    }

    // swiftlint:disable line_length
    static let expected: [Row] = [
        Row(id: "swift", displayName: "Swift", fileExtensions: ["swift"], filenames: [], interpreters: [], lspIdentifier: "swift", grammar: "swift"),
        Row(id: "javascript", displayName: "JavaScript", fileExtensions: ["js", "jsx", "mjs"], filenames: [], interpreters: ["node"], lspIdentifier: "javascript", grammar: "javascript"),
        Row(id: "typescript", displayName: "TypeScript", fileExtensions: ["ts"], filenames: [], interpreters: [], lspIdentifier: "typescript", grammar: "typescript"),
        Row(id: "tsx", displayName: "TSX", fileExtensions: ["tsx"], filenames: [], interpreters: [], lspIdentifier: nil, grammar: "tsx"),
        Row(id: "python", displayName: "Python", fileExtensions: ["py", "pyw"], filenames: [], interpreters: ["python", "python3"], lspIdentifier: "python", grammar: "python"),
        Row(id: "go", displayName: "Go", fileExtensions: ["go"], filenames: [], interpreters: [], lspIdentifier: "go", grammar: "go"),
        Row(id: "rust", displayName: "Rust", fileExtensions: ["rs"], filenames: [], interpreters: [], lspIdentifier: "rust", grammar: "rust"),
        Row(id: "c", displayName: "C", fileExtensions: ["c", "h"], filenames: [], interpreters: [], lspIdentifier: "c", grammar: "c"),
        Row(id: "cpp", displayName: "C++", fileExtensions: ["cc", "cpp", "cxx", "hh", "hpp", "hxx"], filenames: [], interpreters: [], lspIdentifier: "cpp", grammar: "cpp"),
        Row(id: "java", displayName: "Java", fileExtensions: ["java"], filenames: [], interpreters: [], lspIdentifier: "java", grammar: "java"),
        Row(id: "html", displayName: "HTML", fileExtensions: ["htm", "html", "xhtml"], filenames: [], interpreters: [], lspIdentifier: "html", grammar: "html"),
        Row(id: "css", displayName: "CSS", fileExtensions: ["css", "less", "sass", "scss"], filenames: [], interpreters: [], lspIdentifier: "css", grammar: "css"),
        Row(id: "json", displayName: "JSON", fileExtensions: ["json", "jsonc"], filenames: ["package.json", "tsconfig.json"], interpreters: [], lspIdentifier: "json", grammar: "json"),
        Row(id: "markdown", displayName: "Markdown", fileExtensions: ["markdown", "md", "mdown", "mkd"], filenames: ["changelog", "license", "readme"], interpreters: [], lspIdentifier: "markdown", grammar: "markdown"),
        Row(id: "yaml", displayName: "YAML", fileExtensions: ["yaml", "yml"], filenames: [], interpreters: [], lspIdentifier: "yaml", grammar: "yaml"),
        Row(id: "xml", displayName: "XML", fileExtensions: ["svg", "xml", "xsl", "xslt"], filenames: [], interpreters: [], lspIdentifier: "xml", grammar: "xml"),
        Row(id: "sql", displayName: "SQL", fileExtensions: ["sql"], filenames: [], interpreters: [], lspIdentifier: "sql", grammar: "sql"),
        Row(id: "ruby", displayName: "Ruby", fileExtensions: ["rb", "rbw"], filenames: ["gemfile", "podfile", "rakefile"], interpreters: ["ruby"], lspIdentifier: "ruby", grammar: "ruby"),
        Row(id: "php", displayName: "PHP", fileExtensions: ["php", "php3", "php4", "php5", "phtml"], filenames: [], interpreters: ["php"], lspIdentifier: "php", grammar: "php"),
        Row(id: "shell", displayName: "Shell", fileExtensions: ["bash", "fish", "sh", "zsh"], filenames: ["gnumakefile", "makefile"], interpreters: ["bash", "fish", "sh", "zsh"], lspIdentifier: "shellscript", grammar: "bash"),
        Row(id: "dockerfile", displayName: "Dockerfile", fileExtensions: ["dockerfile"], filenames: ["dockerfile"], interpreters: [], lspIdentifier: "dockerfile", grammar: "dockerfile"),
        Row(id: "toml", displayName: "TOML", fileExtensions: ["toml"], filenames: [], interpreters: [], lspIdentifier: "toml", grammar: "toml"),
        Row(id: "lua", displayName: "Lua", fileExtensions: ["lua"], filenames: [], interpreters: ["lua"], lspIdentifier: "lua", grammar: "lua"),
        Row(id: "csharp", displayName: "C#", fileExtensions: ["cs"], filenames: [], interpreters: [], lspIdentifier: "csharp", grammar: "c_sharp"),
        Row(id: "kotlin", displayName: "Kotlin", fileExtensions: ["kt", "kts"], filenames: [], interpreters: [], lspIdentifier: "kotlin", grammar: "kotlin"),
        Row(id: "dart", displayName: "Dart", fileExtensions: ["dart"], filenames: [], interpreters: [], lspIdentifier: "dart", grammar: "dart"),
        Row(id: "mermaid", displayName: "Mermaid", fileExtensions: ["mermaid", "mmd"], filenames: [], interpreters: [], lspIdentifier: "mermaid", grammar: nil),
        Row(id: "d2", displayName: "D2", fileExtensions: ["d2"], filenames: [], interpreters: [], lspIdentifier: "d2", grammar: nil),
        Row(id: "dot", displayName: "Graphviz DOT", fileExtensions: ["dot", "gv"], filenames: [], interpreters: [], lspIdentifier: "dot", grammar: nil),
        Row(id: "structurizr", displayName: "Structurizr DSL", fileExtensions: ["dsl"], filenames: [], interpreters: [], lspIdentifier: "structurizr", grammar: nil),
        Row(id: "plantuml", displayName: "PlantUML", fileExtensions: ["plantuml", "pu", "puml"], filenames: [], interpreters: [], lspIdentifier: "plantuml", grammar: nil),
        Row(id: "plaintext", displayName: "Plain Text", fileExtensions: ["log", "text", "txt"], filenames: [".dockerignore", ".gitignore"], interpreters: [], lspIdentifier: "plaintext", grammar: nil),
    ]
    // swiftlint:enable line_length

    @Test func completeCatalogMatchesLiteralExpectedTable() {
        let actual = LanguageCatalog.all.map { language in
            Row(
                id: language.id.rawValue,
                displayName: language.displayName,
                fileExtensions: language.fileExtensions.sorted(),
                filenames: language.filenames.sorted(),
                interpreters: language.interpreters.sorted(),
                lspIdentifier: language.lspIdentifier,
                grammar: language.treeSitterGrammarIdentifier
            )
        }
        #expect(actual == Self.expected)
    }

    @Test func catalogHasThirtyTwoLanguages() {
        #expect(LanguageCatalog.all.count == 32)
        #expect(Self.expected.count == 32)
    }

    @Test func everyLanguageIDIsUnique() {
        let ids = LanguageCatalog.all.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test func rawValuesAreLowercase() {
        for language in LanguageCatalog.all {
            #expect(language.id.rawValue == language.id.rawValue.lowercased())
        }
    }

    /// No file extension is registered on more than one language (the catalog
    /// resolves extensions deterministically). Documents the single formerly
    /// ambiguous extension (`tsx`) as resolved to exactly one owner.
    @Test func noExtensionMapsToTwoLanguages() {
        var owner: [String: LanguageID] = [:]
        for language in LanguageCatalog.all {
            for ext in language.fileExtensions {
                if let existing = owner[ext] {
                    Issue.record("extension \"\(ext)\" maps to both \(existing) and \(language.id)")
                }
                owner[ext] = language.id
            }
        }
        // The one historically ambiguous extension resolves to `.tsx`
        // (RepoPrompt wins over CodeEditorKit's `.typescript`).
        #expect(owner["tsx"] == .tsx)
        #expect(owner["ts"] == .typescript)
    }

    @Test func noFilenameMapsToTwoLanguages() {
        var owner: [String: LanguageID] = [:]
        for language in LanguageCatalog.all {
            for name in language.filenames {
                if let existing = owner[name] {
                    Issue.record("filename \"\(name)\" maps to both \(existing) and \(language.id)")
                }
                owner[name] = language.id
            }
        }
    }

    @Test func noInterpreterMapsToTwoLanguages() {
        var owner: [String: LanguageID] = [:]
        for language in LanguageCatalog.all {
            for interpreter in language.interpreters {
                if let existing = owner[interpreter] {
                    Issue.record("interpreter \"\(interpreter)\" maps to both \(existing) and \(language.id)")
                }
                owner[interpreter] = language.id
            }
        }
    }

    // MARK: - Lookups

    @Test func metadataLookupByID() {
        #expect(LanguageCatalog.metadata(for: .swift)?.displayName == "Swift")
        #expect(LanguageCatalog.metadata(for: LanguageID("nope")) == nil)
    }

    @Test func extensionLookupIsCaseAndDotInsensitive() {
        #expect(LanguageCatalog.language(forExtension: "swift")?.id == .swift)
        #expect(LanguageCatalog.language(forExtension: ".SWIFT")?.id == .swift)
        #expect(LanguageCatalog.language(forExtension: "TSX")?.id == .tsx)
        #expect(LanguageCatalog.language(forExtension: "nope") == nil)
    }

    @Test func filenameLookupIsCaseInsensitive() {
        #expect(LanguageCatalog.language(forFilename: "Dockerfile")?.id == .dockerfile)
        #expect(LanguageCatalog.language(forFilename: "Makefile")?.id == .shell)
        #expect(LanguageCatalog.language(forFilename: "README")?.id == .markdown)
        #expect(LanguageCatalog.language(forFilename: "package.json")?.id == .json)
        #expect(LanguageCatalog.language(forFilename: "random.xyz") == nil)
    }

    @Test func interpreterLookupIsCaseInsensitive() {
        #expect(LanguageCatalog.language(forInterpreter: "python3")?.id == .python)
        #expect(LanguageCatalog.language(forInterpreter: "BASH")?.id == .shell)
        #expect(LanguageCatalog.language(forInterpreter: "node")?.id == .javascript)
        #expect(LanguageCatalog.language(forInterpreter: "nope") == nil)
    }
}
