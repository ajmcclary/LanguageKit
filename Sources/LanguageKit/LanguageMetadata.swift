import Foundation

/// Everything ``LanguageCatalog`` knows about one language: its identity, its
/// human-facing name, and the file-system / interpreter signals used to detect
/// it, plus the identifiers of the language-server and tree-sitter grammar it
/// maps to (when any).
///
/// This type is deliberately *identity and detection metadata only*. It carries
/// no editor behavior -- no highlight styles, no completion providers, no
/// snippets, no LSP client construction. Those stay in the consuming editors.
///
/// All string collections are compared case-insensitively by ``LanguageCatalog``
/// and ``LanguageRegistry`` (both lowercase lookups); the values stored here are
/// already lowercase.
public struct LanguageMetadata: Hashable, Sendable {
    /// The language's stable identity. Unique within a ``LanguageCatalog``.
    public let id: LanguageID

    /// The human-facing name, e.g. `"C++"`, `"Plain Text"`, `"Graphviz DOT"`.
    public let displayName: String

    /// File extensions (without the leading dot, lowercase) that indicate this
    /// language, e.g. `["c", "h"]`, in **priority order**. The first element is
    /// the canonical / primary extension (see ``primaryFileExtension``); the
    /// rest are recognized aliases in descending preference.
    ///
    /// Within a ``LanguageRegistry`` no extension appears more than once in a
    /// single language's array, and no extension appears on more than one
    /// language (both are validated at registry construction).
    public let fileExtensions: [String]

    /// The canonical / primary extension for this language — the first element
    /// of ``fileExtensions`` — or `nil` if the language declares none.
    ///
    /// This is the extension a tool should prefer when *writing* a new file for
    /// the language (e.g. `"rb"` for Ruby, not `"rbw"`).
    public var primaryFileExtension: String? {
        fileExtensions.first
    }

    /// Whole file names (lowercase) that indicate this language regardless of
    /// extension, e.g. `["dockerfile"]`, `["makefile", "gnumakefile"]`,
    /// `["package.json", "tsconfig.json"]`. Empty for most languages.
    public let filenames: Set<String>

    /// Shebang interpreter names (lowercase, the executable's base name) that
    /// indicate this language, e.g. `["python", "python3"]`, `["bash", "sh"]`.
    ///
    /// - Important: Neither source catalog carried shebang data; this is a
    ///   LanguageKit-added convenience so ``LanguageCatalog/language(forInterpreter:)``
    ///   is useful. It is intentionally minimal (only the unambiguous scripting
    ///   languages) rather than exhaustive.
    public let interpreters: Set<String>

    /// The Language Server Protocol `languageId` for this language, if one is
    /// documented (e.g. `"swift"`, `"shellscript"`). `nil` for languages with
    /// no conventional language server (the diagram DSLs, plain text) or where
    /// the source catalog documented none (``LanguageID/tsx``).
    ///
    /// Sourced from CodeEditorKit's `LanguageDescriptor.lspIdentifier`.
    public let lspIdentifier: String?

    /// The tree-sitter grammar identifier for this language, if one exists.
    ///
    /// For the 14 languages RepoPrompt parses, this is exactly the identifier
    /// RepoPrompt's grammar switch uses (the `tree_sitter_<id>()` suffix). For
    /// CodeEditorKit-only languages, this is the descriptor's `parserName`
    /// *when* that names a real published tree-sitter grammar; otherwise `nil`
    /// (the five diagram DSLs and plain text have no grammar).
    ///
    /// Note this can differ from ``id`` and ``lspIdentifier``: shell's grammar
    /// is `"bash"`, C#'s grammar is `"c_sharp"`.
    public let treeSitterGrammarIdentifier: String?

    /// Creates language metadata.
    ///
    /// - Parameters:
    ///   - id: The stable identity.
    ///   - displayName: The human-facing name.
    ///   - fileExtensions: Lowercase, dotless extensions in priority order; the
    ///     first is the canonical / primary extension.
    ///   - filenames: Lowercase whole file names.
    ///   - interpreters: Lowercase shebang interpreter base names.
    ///   - lspIdentifier: LSP `languageId`, or `nil`.
    ///   - treeSitterGrammarIdentifier: tree-sitter grammar id, or `nil`.
    public init(
        id: LanguageID,
        displayName: String,
        fileExtensions: [String] = [],
        filenames: Set<String> = [],
        interpreters: Set<String> = [],
        lspIdentifier: String? = nil,
        treeSitterGrammarIdentifier: String? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.fileExtensions = fileExtensions
        self.filenames = filenames
        self.interpreters = interpreters
        self.lspIdentifier = lspIdentifier
        self.treeSitterGrammarIdentifier = treeSitterGrammarIdentifier
    }
}
