import Foundation

/// A stable, opaque identifier for a programming (or markup / config / diagram)
/// language known to ``LanguageCatalog``.
///
/// `LanguageID` wraps a single lowercase string ``rawValue`` that is treated as
/// the language's permanent identity. The raw value is stable API: it is what a
/// `Codable` document round-trips through, what a settings file persists, and
/// what two independently built tools use to agree on "the same language". Do
/// not rename an existing raw value; add a new constant instead.
///
/// ### Choosing the raw values
///
/// The catalog is the union of two pre-existing catalogs (CodeEditorKit's
/// `LanguageDescriptor` and RepoPrompt's `SyntaxManager`). Those two catalogs
/// key some shared languages differently -- e.g. JavaScript is `"javascript"`
/// in CodeEditorKit but `"js"` in RepoPrompt; TypeScript is `"typescript"`
/// vs `"ts"`; C# is `"csharp"` vs `"c_sharp"`. `LanguageID` is a *new* identity
/// that neither catalog owned, so its raw values are chosen once here:
///
/// - The descriptive, LSP-aligned form (`"javascript"`, `"typescript"`,
///   `"csharp"`) is used, matching CodeEditorKit's `Language.rawValue` and
///   its `lspIdentifier`. CodeEditorKit is the larger catalog (31 languages
///   vs 14) and its identifiers double as the language-server ids consumers
///   already speak.
/// - RepoPrompt's shorter enum-case names (`js` / `ts` / `c_sharp`) are *not*
///   used as the identity, but they are recorded here so the mapping is
///   auditable. This is the one place LanguageKit does not literally adopt a
///   RepoPrompt string; the "RepoPrompt wins" conflict policy is applied to
///   genuine *metadata* disagreements (see ``LanguageCatalog`` doc comment),
///   not to the choice of a brand-new identity key.
///
/// See ``LanguageCatalog`` for the full list of conflicts and how each was
/// resolved.
public struct LanguageID: Hashable, Sendable, Codable, RawRepresentable, CustomStringConvertible {
    /// The stable, lowercase identity string for this language.
    public let rawValue: String

    /// Creates a language id from a raw identity string.
    ///
    /// This is deliberately non-failable: a `LanguageID` can name a language
    /// the local ``LanguageCatalog`` does not (yet) know about, so that
    /// persisted documents from a newer catalog still decode. Use
    /// ``LanguageCatalog/metadata(for:)`` to test whether an id is registered.
    ///
    /// - Parameter rawValue: The identity string, e.g. `"swift"`.
    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// Creates a language id from a raw identity string.
    ///
    /// Convenience spelling of ``init(rawValue:)``.
    ///
    /// - Parameter rawValue: The identity string, e.g. `"swift"`.
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    // MARK: Codable

    /// Decodes a language id from its bare string representation.
    ///
    /// `LanguageID` encodes as a single string (not a keyed container), so a
    /// value round-trips as `"swift"` rather than `{"rawValue":"swift"}`.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.rawValue = try container.decode(String.self)
    }

    /// Encodes this language id as its bare string ``rawValue``.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    /// The ``rawValue``, for `CustomStringConvertible`.
    public var description: String { rawValue }
}

public extension LanguageID {
    // MARK: - Shared languages (present in both source catalogs)

    /// Swift. Present in both source catalogs.
    static let swift = LanguageID("swift")
    /// JavaScript. RepoPrompt keys this `"js"`; the descriptive form is used.
    static let javascript = LanguageID("javascript")
    /// TypeScript. RepoPrompt keys this `"ts"`; the descriptive form is used.
    static let typescript = LanguageID("typescript")
    /// Python. Present in both source catalogs.
    static let python = LanguageID("python")
    /// Go. Present in both source catalogs.
    static let go = LanguageID("go")
    /// Rust. Present in both source catalogs.
    static let rust = LanguageID("rust")
    /// C. Present in both source catalogs.
    static let c = LanguageID("c")
    /// C++. Present in both source catalogs.
    static let cpp = LanguageID("cpp")
    /// Java. Present in both source catalogs.
    static let java = LanguageID("java")
    /// Ruby. Present in both source catalogs.
    static let ruby = LanguageID("ruby")
    /// PHP. Present in both source catalogs.
    static let php = LanguageID("php")
    /// C#. RepoPrompt keys this `"c_sharp"`; the descriptive form is used.
    static let csharp = LanguageID("csharp")
    /// Dart. Present in both source catalogs.
    static let dart = LanguageID("dart")

    // MARK: - RepoPrompt-only

    /// TSX (TypeScript + JSX). RepoPrompt models this as a *distinct* language
    /// (`LanguageType.tsx`) with its own tree-sitter grammar. CodeEditorKit
    /// instead folds the `tsx` extension into ``typescript``. Per the
    /// "RepoPrompt wins" conflict policy, `.tsx` is a first-class language here
    /// and the `tsx` extension resolves to it (see ``LanguageCatalog``).
    static let tsx = LanguageID("tsx")

    // MARK: - CodeEditorKit-only

    /// HTML. CodeEditorKit only.
    static let html = LanguageID("html")
    /// CSS (and SCSS / Sass / Less). CodeEditorKit only.
    static let css = LanguageID("css")
    /// JSON. CodeEditorKit only.
    static let json = LanguageID("json")
    /// Markdown. CodeEditorKit only.
    static let markdown = LanguageID("markdown")
    /// YAML. CodeEditorKit only.
    static let yaml = LanguageID("yaml")
    /// XML. CodeEditorKit only.
    static let xml = LanguageID("xml")
    /// SQL. CodeEditorKit only.
    static let sql = LanguageID("sql")
    /// Shell. CodeEditorKit only. Note its tree-sitter grammar id is
    /// `"bash"`, not `"shell"` (see ``LanguageCatalog``).
    static let shell = LanguageID("shell")
    /// Dockerfile. CodeEditorKit only.
    static let dockerfile = LanguageID("dockerfile")
    /// TOML. CodeEditorKit only.
    static let toml = LanguageID("toml")
    /// Lua. CodeEditorKit only.
    static let lua = LanguageID("lua")
    /// Kotlin. CodeEditorKit only.
    static let kotlin = LanguageID("kotlin")
    /// Mermaid diagram DSL. CodeEditorKit only. No tree-sitter grammar.
    static let mermaid = LanguageID("mermaid")
    /// D2 diagram DSL. CodeEditorKit only. No tree-sitter grammar.
    static let d2 = LanguageID("d2")
    /// Graphviz DOT. CodeEditorKit only. No tree-sitter grammar.
    static let dot = LanguageID("dot")
    /// Structurizr DSL. CodeEditorKit only. No tree-sitter grammar.
    static let structurizr = LanguageID("structurizr")
    /// PlantUML. CodeEditorKit only. No tree-sitter grammar.
    static let plantuml = LanguageID("plantuml")
    /// Plain text (the fallback "language"). CodeEditorKit only.
    static let plainText = LanguageID("plaintext")
}
