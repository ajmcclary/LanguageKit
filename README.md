# LanguageKit

Language identity and metadata for Swift editor tooling.

LanguageKit is a small, Foundation-only package that answers one question well:
**"what language is this?"** It is the shared source of truth for the language
catalog used across CodeEditorPlugin and RepoPrompt.

It carries *identity and detection metadata only* — no highlight styles, no
completion, no snippets, no LSP client construction, no tree-sitter query
strings. Those stay in the editors that consume this package.

- `LanguageID` — a stable, `Codable` string identity for a language, with a
  static constant per known language (`.swift`, `.typescript`, `.tsx`, …).
- `LanguageMetadata` — display name, file extensions, whole file names,
  shebang interpreters, LSP `languageId`, and tree-sitter grammar id.
- `LanguageCatalog` — the static registry of all 32 languages plus lookups.

## Usage

```swift
import LanguageKit

// Look up by extension (case- and dot-insensitive)
LanguageCatalog.language(forExtension: "swift")?.id          // .swift
LanguageCatalog.language(forExtension: ".TSX")?.displayName  // "TSX"

// Look up by whole file name
LanguageCatalog.language(forFilename: "Dockerfile")?.id      // .dockerfile
LanguageCatalog.language(forFilename: "Makefile")?.id        // .shell

// Look up by shebang interpreter base name
LanguageCatalog.language(forInterpreter: "python3")?.id      // .python

// Look up by identity, or enumerate everything
LanguageCatalog.metadata(for: .rust)?.treeSitterGrammarIdentifier  // "rust"
for language in LanguageCatalog.all { … }
```

## The catalog

The catalog is the **union** of two pre-existing catalogs — CodeEditorPlugin's
`LanguageDescriptor` (31 languages) and RepoPrompt's `SyntaxManager` (14) —
reconciled into 32 languages. Where the two disagreed, **RepoPrompt's data
wins** (it is the proven, shipping tree-sitter implementation). The two
conflicts and their resolutions, plus the tree-sitter grammar-id judgments, are
documented in full in the `LanguageCatalog` doc comment.

## Requirements

- Swift 6.3+. Foundation only; no platform floor and no third-party
  dependencies.

## License

MIT — see [LICENSE](LICENSE).
