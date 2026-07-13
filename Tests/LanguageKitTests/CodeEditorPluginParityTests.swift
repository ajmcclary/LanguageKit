import Testing
@testable import LanguageKit

/// Mirrors CodeEditorPlugin's Task-5 characterization table
/// (`LanguageCatalogCharacterizationTests`) and asserts the LanguageKit union
/// still represents every one of its 31 languages faithfully -- with exactly
/// two documented, RepoPrompt-wins deviations flagged inline.
@Suite struct CodeEditorPluginParityTests {
    /// A row from CodeEditorPlugin's `LanguageDescriptor` characterization
    /// table: `id` == `Language.rawValue`, `parserName` == tree-sitter grammar.
    struct CEPRow {
        let id: String
        let displayName: String
        let fileExtensions: [String]
        let lspIdentifier: String
        let parserName: String?
    }

    // swiftlint:disable line_length
    /// Copied verbatim from CodeEditorPlugin's characterization test (declaration order).
    static let cep: [CEPRow] = [
        CEPRow(id: "swift", displayName: "Swift", fileExtensions: ["swift"], lspIdentifier: "swift", parserName: nil),
        CEPRow(id: "javascript", displayName: "JavaScript", fileExtensions: ["js", "jsx", "mjs"], lspIdentifier: "javascript", parserName: "javascript"),
        CEPRow(id: "typescript", displayName: "TypeScript", fileExtensions: ["ts", "tsx"], lspIdentifier: "typescript", parserName: "typescript"),
        CEPRow(id: "python", displayName: "Python", fileExtensions: ["py", "pyw"], lspIdentifier: "python", parserName: "python"),
        CEPRow(id: "go", displayName: "Go", fileExtensions: ["go"], lspIdentifier: "go", parserName: "go"),
        CEPRow(id: "rust", displayName: "Rust", fileExtensions: ["rs"], lspIdentifier: "rust", parserName: "rust"),
        CEPRow(id: "c", displayName: "C", fileExtensions: ["c", "h"], lspIdentifier: "c", parserName: "c"),
        CEPRow(id: "cpp", displayName: "C++", fileExtensions: ["cpp", "cc", "cxx", "hpp", "hh", "hxx"], lspIdentifier: "cpp", parserName: "cpp"),
        CEPRow(id: "java", displayName: "Java", fileExtensions: ["java"], lspIdentifier: "java", parserName: "java"),
        CEPRow(id: "html", displayName: "HTML", fileExtensions: ["html", "htm", "xhtml"], lspIdentifier: "html", parserName: "html"),
        CEPRow(id: "css", displayName: "CSS", fileExtensions: ["css", "scss", "sass", "less"], lspIdentifier: "css", parserName: "css"),
        CEPRow(id: "json", displayName: "JSON", fileExtensions: ["json", "jsonc"], lspIdentifier: "json", parserName: "json"),
        CEPRow(id: "markdown", displayName: "Markdown", fileExtensions: ["md", "markdown", "mdown", "mkd"], lspIdentifier: "markdown", parserName: "markdown"),
        CEPRow(id: "yaml", displayName: "YAML", fileExtensions: ["yaml", "yml"], lspIdentifier: "yaml", parserName: "yaml"),
        CEPRow(id: "xml", displayName: "XML", fileExtensions: ["xml", "xsl", "xslt", "svg"], lspIdentifier: "xml", parserName: "xml"),
        CEPRow(id: "sql", displayName: "SQL", fileExtensions: ["sql"], lspIdentifier: "sql", parserName: "sql"),
        CEPRow(id: "ruby", displayName: "Ruby", fileExtensions: ["rb", "rbw"], lspIdentifier: "ruby", parserName: "ruby"),
        CEPRow(id: "php", displayName: "PHP", fileExtensions: ["php", "phtml", "php3", "php4", "php5"], lspIdentifier: "php", parserName: "php"),
        CEPRow(id: "shell", displayName: "Shell", fileExtensions: ["sh", "bash", "zsh", "fish"], lspIdentifier: "shellscript", parserName: "bash"),
        CEPRow(id: "dockerfile", displayName: "Dockerfile", fileExtensions: ["dockerfile"], lspIdentifier: "dockerfile", parserName: "dockerfile"),
        CEPRow(id: "toml", displayName: "TOML", fileExtensions: ["toml"], lspIdentifier: "toml", parserName: "toml"),
        CEPRow(id: "lua", displayName: "Lua", fileExtensions: ["lua"], lspIdentifier: "lua", parserName: "lua"),
        CEPRow(id: "csharp", displayName: "C#", fileExtensions: ["cs"], lspIdentifier: "csharp", parserName: "c_sharp"),
        CEPRow(id: "kotlin", displayName: "Kotlin", fileExtensions: ["kt", "kts"], lspIdentifier: "kotlin", parserName: "kotlin"),
        CEPRow(id: "dart", displayName: "Dart", fileExtensions: ["dart"], lspIdentifier: "dart", parserName: "dart"),
        CEPRow(id: "mermaid", displayName: "Mermaid", fileExtensions: ["mmd", "mermaid"], lspIdentifier: "mermaid", parserName: nil),
        CEPRow(id: "d2", displayName: "D2", fileExtensions: ["d2"], lspIdentifier: "d2", parserName: nil),
        CEPRow(id: "dot", displayName: "Graphviz DOT", fileExtensions: ["dot", "gv"], lspIdentifier: "dot", parserName: nil),
        CEPRow(id: "structurizr", displayName: "Structurizr DSL", fileExtensions: ["dsl"], lspIdentifier: "structurizr", parserName: nil),
        CEPRow(id: "plantuml", displayName: "PlantUML", fileExtensions: ["puml", "plantuml", "pu"], lspIdentifier: "plantuml", parserName: nil),
        CEPRow(id: "plaintext", displayName: "Plain Text", fileExtensions: ["txt", "text", "log"], lspIdentifier: "plaintext", parserName: nil),
    ]
    // swiftlint:enable line_length

    @Test func everyCodeEditorPluginLanguageIsPresent() {
        for row in Self.cep {
            #expect(LanguageCatalog.metadata(for: LanguageID(row.id)) != nil, "missing \(row.id)")
        }
        // CodeEditorPlugin has 31 languages; the union adds only RepoPrompt's tsx.
        #expect(Self.cep.count == 31)
        #expect(LanguageCatalog.all.count == Self.cep.count + 1)
    }

    @Test func displayNamesAndLSPIdentifiersMatchExactly() {
        for row in Self.cep {
            let metadata = LanguageCatalog.metadata(for: LanguageID(row.id))
            #expect(metadata?.displayName == row.displayName, "displayName for \(row.id)")
            #expect(metadata?.lspIdentifier == row.lspIdentifier, "lspIdentifier for \(row.id)")
        }
    }

    /// Extensions match CodeEditorPlugin exactly, except TypeScript: RepoPrompt
    /// wins the `tsx` extension (it becomes `.tsx`), so LanguageKit's TypeScript
    /// lists only `["ts"]`.
    @Test func fileExtensionsMatchExceptTypeScriptTSXSplit() {
        for row in Self.cep {
            let metadata = LanguageCatalog.metadata(for: LanguageID(row.id))
            let expected: Set<String>
            if row.id == "typescript" {
                expected = Set(row.fileExtensions).subtracting(["tsx"])
                #expect(metadata?.fileExtensions == ["ts"], "TypeScript should drop tsx")
            } else {
                expected = Set(row.fileExtensions)
            }
            #expect(metadata?.fileExtensions == expected, "fileExtensions for \(row.id)")
        }
    }

    /// Grammar ids match CodeEditorPlugin's `parserName` exactly, except Swift:
    /// CodeEditorPlugin uses SwiftSyntax (`parserName == nil`) but RepoPrompt
    /// parses Swift with `tree_sitter_swift()`, so RepoPrompt wins -> `"swift"`.
    @Test func grammarIdentifiersMatchExceptSwift() {
        for row in Self.cep {
            let metadata = LanguageCatalog.metadata(for: LanguageID(row.id))
            if row.id == "swift" {
                #expect(metadata?.treeSitterGrammarIdentifier == "swift", "Swift grammar from RepoPrompt")
            } else {
                #expect(
                    metadata?.treeSitterGrammarIdentifier == row.parserName,
                    "grammar for \(row.id)"
                )
            }
        }
    }

    /// Every CodeEditorPlugin extension still resolves through the catalog to
    /// the same language -- except `tsx`, which now resolves to `.tsx`.
    @Test func everyExtensionResolvesToItsLanguage() {
        for row in Self.cep {
            for ext in row.fileExtensions {
                let resolved = LanguageCatalog.language(forExtension: ext)?.id
                if ext == "tsx" {
                    #expect(resolved == .tsx, "tsx resolves to RepoPrompt's tsx")
                } else {
                    #expect(resolved == LanguageID(row.id), "extension \(ext) -> \(row.id)")
                }
            }
        }
    }

    /// Mirrors CodeEditorPlugin's `LanguageDetectionService` special-filename
    /// table (the ones with no, or a non-language, extension). The prefix-match
    /// quirk (`dockerfile.<x>`) is intentionally not reproduced -- see the
    /// `LanguageCatalog` doc comment.
    @Test func specialFilenamesResolve() {
        let expected: [(String, LanguageID)] = [
            ("dockerfile", .dockerfile),
            ("makefile", .shell),
            ("gnumakefile", .shell),
            ("rakefile", .ruby),
            ("gemfile", .ruby),
            ("podfile", .ruby),
            ("package.json", .json),
            ("tsconfig.json", .json),
            (".gitignore", .plainText),
            (".dockerignore", .plainText),
            ("readme", .markdown),
            ("license", .markdown),
            ("changelog", .markdown),
        ]
        for (filename, id) in expected {
            #expect(LanguageCatalog.language(forFilename: filename)?.id == id, "filename \(filename)")
        }
    }
}
