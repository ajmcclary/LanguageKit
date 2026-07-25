# LanguageKit

Language identity and metadata for Swift editor tooling.

LanguageKit is a small, Foundation-only package that answers one question well:
**"what language is this?"** It is the shared source of truth for the language
catalog used across CodeEditorKit and RepoPrompt.

It carries *identity and detection metadata only* — no highlight styles, no
completion, no snippets, no LSP client construction, no tree-sitter query
strings. Those stay in the editors that consume this package.

- `LanguageID` — a stable, `Codable` string identity for a language, with a
  static constant per known language (`.swift`, `.typescript`, `.tsx`, …).
- `LanguageMetadata` — display name, **ordered** file extensions (first is the
  `primaryFileExtension`), whole file names, shebang interpreters, LSP
  `languageId`, and tree-sitter grammar id.
- `LanguageCatalog` — the static registry of all 32 languages plus lookups.
- `LanguageRegistry` — an immutable, validated registry value you can build,
  extend (`merging`), and restrict (`restricted(to:)`); `LanguageRegistry.standard`
  is the whole catalog.
- `Shebang` — shared parsing of a `#!` line down to its interpreter base name.

## Usage

```swift
import LanguageKit

// Look up by extension (case- and dot-insensitive)
LanguageCatalog.language(forExtension: "swift")?.id          // .swift
LanguageCatalog.language(forExtension: ".TSX")?.displayName  // "TSX"

// The canonical extension to write a new file with
LanguageCatalog.metadata(for: .ruby)?.primaryFileExtension   // "rb"

// Look up by whole file name
LanguageCatalog.language(forFilename: "Dockerfile")?.id      // .dockerfile
LanguageCatalog.language(forFilename: "Makefile")?.id        // .shell

// Look up by shebang interpreter base name
LanguageCatalog.language(forInterpreter: "python3")?.id      // .python

// Look up by identity, or enumerate everything
LanguageCatalog.metadata(for: .rust)?.treeSitterGrammarIdentifier  // "rust"
for language in LanguageCatalog.all { … }
```

### Registries, custom metadata, and allowlists

```swift
// The standard registry is the full catalog.
let registry = LanguageRegistry.standard

// Resolve a whole shebang line (with a shared version-suffix fallback:
// `python3.12` → `python`).
registry.language(forShebangLine: "#!/usr/bin/env python3.12")?.id  // .python

// Layer in custom / overriding metadata without forking the catalog.
let custom = try registry.merging([
    LanguageMetadata(id: .python, displayName: "Python",
                     fileExtensions: ["py", "pyw", "pyi"],
                     interpreters: ["python", "python3", "pypy"],
                     lspIdentifier: "python", treeSitterGrammarIdentifier: "python")
])

// Expose only the languages a tool actually supports.
let parserLanguages = registry.restricted(to: [.swift, .python, .typescript, .tsx])

// Build a registry from scratch; construction validates it.
let mine = try LanguageRegistry(languages: [
    LanguageMetadata(id: LanguageID("nim"), displayName: "Nim", fileExtensions: ["nim"])
])
```

## The catalog

The catalog is the **union** of two pre-existing catalogs — CodeEditorKit's
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
