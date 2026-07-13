import Foundation

/// The static registry of every language LanguageKit knows about, built as the
/// **union** of two pre-existing catalogs, plus the lookups editor tooling
/// needs: by ``LanguageID``, by file extension, by whole file name, and by
/// shebang interpreter.
///
/// ## Sources
///
/// - **CodeEditorPlugin** `LanguageDescriptor` catalog (31 languages: 30
///   concrete + plain text), including the separate special-filename registry
///   in `LanguageDetectionService`.
/// - **RepoPrompt** `SyntaxManager` catalog (14 languages), including its
///   tree-sitter grammar switch.
///
/// The union is **32 languages**: CodeEditorPlugin's 31 plus RepoPrompt's
/// ``LanguageID/tsx``, which CodeEditorPlugin did not model as a distinct
/// language.
///
/// ## Conflict resolution
///
/// Where the two catalogs disagreed, **RepoPrompt's data wins** (it is the
/// proven, shipping tree-sitter implementation). Every conflict found and how
/// it was resolved:
///
/// 1. **`tsx` extension owner.** CodeEditorPlugin maps the `tsx` extension to
///    ``LanguageID/typescript`` (its TypeScript descriptor lists
///    `["ts", "tsx"]`). RepoPrompt maps `tsx` to a *separate* `LanguageType.tsx`
///    with its own `tree_sitter_tsx()` grammar. **Resolution:** RepoPrompt
///    wins -- ``LanguageID/tsx`` is a first-class language, it owns the `tsx`
///    extension, and ``LanguageID/typescript`` here lists only `["ts"]`. This
///    keeps every extension mapping to exactly one language.
///
/// 2. **Identity-key spelling.** The two catalogs key three shared languages
///    with different strings: JavaScript is `"javascript"` (CodeEditorPlugin)
///    vs `"js"` (RepoPrompt); TypeScript `"typescript"` vs `"ts"`; C#
///    `"csharp"` vs `"c_sharp"`. ``LanguageID`` is a brand-new identity that
///    neither catalog previously owned, so this is not a *metadata* conflict;
///    the descriptive, LSP-aligned spellings are chosen (see ``LanguageID``).
///    RepoPrompt's spellings are preserved as the tree-sitter grammar ids where
///    they legitimately differ (C# grammar is `"c_sharp"`).
///
/// Display names did **not** conflict: both catalogs spell the shared names
/// identically ("JavaScript", "TypeScript", "C#", "C++", ...).
///
/// ## Grammar-identifier judgments
///
/// - The 14 RepoPrompt languages use exactly the identifier RepoPrompt's
///   `tree_sitter_<id>()` switch uses. Two of these differ from the language's
///   own id: **shell**'s grammar is `"bash"` and **C#**'s is `"c_sharp"`.
/// - CodeEditorPlugin-only languages take their descriptor's `parserName` as
///   the grammar id **only when it names a real published tree-sitter grammar**
///   -- true for html, css, json, markdown, yaml, xml, sql, dockerfile, toml,
///   lua, kotlin (and shell's `"bash"`). The five diagram DSLs (mermaid, d2,
///   dot, structurizr, plantuml) and plain text carry `parserName == nil` and
///   so have **no** grammar id here.
///
/// ## Not included
///
/// Editor behavior (highlight styles, completion, snippets, LSP client
/// construction, tree-sitter query strings) is intentionally out of scope --
/// this is identity and detection metadata only.
///
/// ## Detection quirks deliberately *not* reproduced
///
/// - CodeEditorPlugin's `LanguageDetectionService` matched Dockerfiles with a
///   `hasPrefix("dockerfile.")` rule (so `foo.dockerfile.dev` matched). Here,
///   `dockerfile` is a whole-filename match and a file extension; the prefix
///   quirk is not carried over.
/// - `readme` / `license` / `changelog` mapping to Markdown and
///   `makefile` / `gnumakefile` mapping to Shell are RepoPrompt-independent
///   CodeEditorPlugin conventions; they are preserved as-is in ``filenames``.
public enum LanguageCatalog {
    /// Every registered language, in a stable declaration order (CodeEditorPlugin's
    /// original order, with ``LanguageID/tsx`` inserted next to TypeScript).
    ///
    /// Each language's ``LanguageMetadata/fileExtensions`` is ordered: the first
    /// element is the canonical / primary extension (matching CodeEditorPlugin's
    /// deliberate ordering and RepoPrompt's `canonicalFileExtension` for its 14
    /// languages), the rest are recognized aliases.
    public static let all: [LanguageMetadata] = [
        LanguageMetadata(
            id: .swift, displayName: "Swift",
            fileExtensions: ["swift"],
            lspIdentifier: "swift", treeSitterGrammarIdentifier: "swift"
        ),
        LanguageMetadata(
            id: .javascript, displayName: "JavaScript",
            fileExtensions: ["js", "jsx", "mjs"],
            interpreters: ["node"],
            lspIdentifier: "javascript", treeSitterGrammarIdentifier: "javascript"
        ),
        // Conflict #1: `tsx` moved to `.tsx` (RepoPrompt wins), so TypeScript
        // owns only `ts` here -- CodeEditorPlugin's descriptor had `["ts", "tsx"]`.
        LanguageMetadata(
            id: .typescript, displayName: "TypeScript",
            fileExtensions: ["ts"],
            lspIdentifier: "typescript", treeSitterGrammarIdentifier: "typescript"
        ),
        // RepoPrompt-only language. lspIdentifier is nil: no source catalog
        // documented one (the conventional value would be "typescriptreact",
        // but that is not carried from either source).
        LanguageMetadata(
            id: .tsx, displayName: "TSX",
            fileExtensions: ["tsx"],
            lspIdentifier: nil, treeSitterGrammarIdentifier: "tsx"
        ),
        LanguageMetadata(
            id: .python, displayName: "Python",
            fileExtensions: ["py", "pyw"],
            interpreters: ["python", "python3"],
            lspIdentifier: "python", treeSitterGrammarIdentifier: "python"
        ),
        LanguageMetadata(
            id: .go, displayName: "Go",
            fileExtensions: ["go"],
            lspIdentifier: "go", treeSitterGrammarIdentifier: "go"
        ),
        LanguageMetadata(
            id: .rust, displayName: "Rust",
            fileExtensions: ["rs"],
            lspIdentifier: "rust", treeSitterGrammarIdentifier: "rust"
        ),
        LanguageMetadata(
            id: .c, displayName: "C",
            fileExtensions: ["c", "h"],
            lspIdentifier: "c", treeSitterGrammarIdentifier: "c"
        ),
        LanguageMetadata(
            id: .cpp, displayName: "C++",
            fileExtensions: ["cpp", "cc", "cxx", "hpp", "hh", "hxx"],
            lspIdentifier: "cpp", treeSitterGrammarIdentifier: "cpp"
        ),
        LanguageMetadata(
            id: .java, displayName: "Java",
            fileExtensions: ["java"],
            lspIdentifier: "java", treeSitterGrammarIdentifier: "java"
        ),
        LanguageMetadata(
            id: .html, displayName: "HTML",
            fileExtensions: ["html", "htm", "xhtml"],
            lspIdentifier: "html", treeSitterGrammarIdentifier: "html"
        ),
        LanguageMetadata(
            id: .css, displayName: "CSS",
            fileExtensions: ["css", "scss", "sass", "less"],
            lspIdentifier: "css", treeSitterGrammarIdentifier: "css"
        ),
        LanguageMetadata(
            id: .json, displayName: "JSON",
            fileExtensions: ["json", "jsonc"],
            filenames: ["package.json", "tsconfig.json"],
            lspIdentifier: "json", treeSitterGrammarIdentifier: "json"
        ),
        LanguageMetadata(
            id: .markdown, displayName: "Markdown",
            fileExtensions: ["md", "markdown", "mdown", "mkd"],
            filenames: ["readme", "license", "changelog"],
            lspIdentifier: "markdown", treeSitterGrammarIdentifier: "markdown"
        ),
        LanguageMetadata(
            id: .yaml, displayName: "YAML",
            fileExtensions: ["yaml", "yml"],
            lspIdentifier: "yaml", treeSitterGrammarIdentifier: "yaml"
        ),
        LanguageMetadata(
            id: .xml, displayName: "XML",
            fileExtensions: ["xml", "xsl", "xslt", "svg"],
            lspIdentifier: "xml", treeSitterGrammarIdentifier: "xml"
        ),
        LanguageMetadata(
            id: .sql, displayName: "SQL",
            fileExtensions: ["sql"],
            lspIdentifier: "sql", treeSitterGrammarIdentifier: "sql"
        ),
        LanguageMetadata(
            id: .ruby, displayName: "Ruby",
            fileExtensions: ["rb", "rbw"],
            filenames: ["rakefile", "gemfile", "podfile"],
            interpreters: ["ruby"],
            lspIdentifier: "ruby", treeSitterGrammarIdentifier: "ruby"
        ),
        LanguageMetadata(
            id: .php, displayName: "PHP",
            fileExtensions: ["php", "phtml", "php3", "php4", "php5"],
            interpreters: ["php"],
            lspIdentifier: "php", treeSitterGrammarIdentifier: "php"
        ),
        // Oddity carried from CodeEditorPlugin: grammar id is "bash", lsp id is
        // "shellscript"; neither equals the language id "shell".
        LanguageMetadata(
            id: .shell, displayName: "Shell",
            fileExtensions: ["sh", "bash", "zsh", "fish"],
            filenames: ["makefile", "gnumakefile"],
            interpreters: ["sh", "bash", "zsh", "fish"],
            lspIdentifier: "shellscript", treeSitterGrammarIdentifier: "bash"
        ),
        LanguageMetadata(
            id: .dockerfile, displayName: "Dockerfile",
            fileExtensions: ["dockerfile"],
            filenames: ["dockerfile"],
            lspIdentifier: "dockerfile", treeSitterGrammarIdentifier: "dockerfile"
        ),
        LanguageMetadata(
            id: .toml, displayName: "TOML",
            fileExtensions: ["toml"],
            lspIdentifier: "toml", treeSitterGrammarIdentifier: "toml"
        ),
        LanguageMetadata(
            id: .lua, displayName: "Lua",
            fileExtensions: ["lua"],
            interpreters: ["lua"],
            lspIdentifier: "lua", treeSitterGrammarIdentifier: "lua"
        ),
        // Oddity carried from CodeEditorPlugin: grammar id is "c_sharp"
        // (matches RepoPrompt's `tree_sitter_c_sharp()`), lsp id is "csharp".
        LanguageMetadata(
            id: .csharp, displayName: "C#",
            fileExtensions: ["cs"],
            lspIdentifier: "csharp", treeSitterGrammarIdentifier: "c_sharp"
        ),
        LanguageMetadata(
            id: .kotlin, displayName: "Kotlin",
            fileExtensions: ["kt", "kts"],
            lspIdentifier: "kotlin", treeSitterGrammarIdentifier: "kotlin"
        ),
        LanguageMetadata(
            id: .dart, displayName: "Dart",
            fileExtensions: ["dart"],
            lspIdentifier: "dart", treeSitterGrammarIdentifier: "dart"
        ),
        LanguageMetadata(
            id: .mermaid, displayName: "Mermaid",
            fileExtensions: ["mmd", "mermaid"],
            lspIdentifier: "mermaid", treeSitterGrammarIdentifier: nil
        ),
        LanguageMetadata(
            id: .d2, displayName: "D2",
            fileExtensions: ["d2"],
            lspIdentifier: "d2", treeSitterGrammarIdentifier: nil
        ),
        LanguageMetadata(
            id: .dot, displayName: "Graphviz DOT",
            fileExtensions: ["dot", "gv"],
            lspIdentifier: "dot", treeSitterGrammarIdentifier: nil
        ),
        LanguageMetadata(
            id: .structurizr, displayName: "Structurizr DSL",
            fileExtensions: ["dsl"],
            lspIdentifier: "structurizr", treeSitterGrammarIdentifier: nil
        ),
        LanguageMetadata(
            id: .plantuml, displayName: "PlantUML",
            fileExtensions: ["puml", "plantuml", "pu"],
            lspIdentifier: "plantuml", treeSitterGrammarIdentifier: nil
        ),
        LanguageMetadata(
            id: .plainText, displayName: "Plain Text",
            fileExtensions: ["txt", "text", "log"],
            filenames: [".gitignore", ".dockerignore"],
            lspIdentifier: "plaintext", treeSitterGrammarIdentifier: nil
        ),
    ]

    // MARK: - Lookups
    //
    // The static lookups below delegate to ``LanguageRegistry/standard`` (which
    // is itself built from ``all``) so there is a single lookup implementation.
    // The behavior is identical to the previous hand-rolled indexes.

    /// The metadata for a language id, or `nil` if the id is not registered.
    ///
    /// - Parameter id: The language identity to look up.
    public static func metadata(for id: LanguageID) -> LanguageMetadata? {
        LanguageRegistry.standard.metadata(for: id)
    }

    /// The language whose ``LanguageMetadata/fileExtensions`` contains the given
    /// extension, or `nil`.
    ///
    /// Matching is case-insensitive and tolerant of a leading dot, so
    /// `"SWIFT"`, `".swift"`, and `"swift"` all resolve identically.
    ///
    /// - Parameter fileExtension: An extension, with or without leading dot.
    public static func language(forExtension fileExtension: String) -> LanguageMetadata? {
        LanguageRegistry.standard.language(forExtension: fileExtension)
    }

    /// The language indicated by a whole file name (e.g. `"Dockerfile"`,
    /// `"package.json"`, `"Makefile"`), or `nil`.
    ///
    /// Matching is case-insensitive against the exact file name. This checks
    /// only the ``LanguageMetadata/filenames`` registry; it does **not** fall
    /// back to extension detection -- call ``language(forExtension:)`` for that.
    ///
    /// - Parameter filename: The file's name (not a full path).
    public static func language(forFilename filename: String) -> LanguageMetadata? {
        LanguageRegistry.standard.language(forFilename: filename)
    }

    /// The language indicated by a shebang interpreter base name (e.g.
    /// `"python3"`, `"bash"`), or `nil`.
    ///
    /// Pass the interpreter's base name, not the full shebang line; a caller
    /// parsing `#!/usr/bin/env python3` should pass `"python3"`. Matching is
    /// case-insensitive.
    ///
    /// - Parameter interpreter: The interpreter executable's base name.
    public static func language(forInterpreter interpreter: String) -> LanguageMetadata? {
        LanguageRegistry.standard.language(forInterpreter: interpreter)
    }
}
