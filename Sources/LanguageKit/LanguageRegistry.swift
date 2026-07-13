import Foundation

/// A validation failure raised while constructing a ``LanguageRegistry``.
///
/// Each case carries the conflicting value and the language id(s) involved so a
/// consumer can produce an actionable diagnostic.
public enum LanguageRegistryError: Error, Equatable, Sendable {
    /// Two entries share the same ``LanguageID``.
    case duplicateLanguageID(LanguageID)

    /// A single file extension is claimed by two different languages.
    case duplicateFileExtension(fileExtension: String, existing: LanguageID, conflicting: LanguageID)

    /// A single whole-filename is claimed by two different languages.
    case duplicateFilename(filename: String, existing: LanguageID, conflicting: LanguageID)

    /// One language's ``LanguageMetadata/fileExtensions`` array lists the same
    /// extension more than once.
    case duplicateFileExtensionWithinLanguage(fileExtension: String, language: LanguageID)
}

/// An immutable, validated set of ``LanguageMetadata`` with precomputed,
/// case-insensitive lookups — the same surface ``LanguageCatalog`` exposes, but
/// as a value a consumer can build, extend, and restrict.
///
/// Construct one from a curated list (``init(languages:)``), or start from the
/// standard catalog (``standard``) and adapt it:
///
/// - ``merging(_:)`` layers custom or overriding metadata on top (this is how a
///   consumer feeds richer interpreter aliases without forking the catalog).
/// - ``restricted(to:)`` narrows the registry to an allowlist of languages
///   (this is how a consumer exposes only the languages it actually parses).
///
/// All lookups lowercase their query; ``language(forExtension:)`` also tolerates
/// a leading dot. The registry is fully `Sendable` and thread-safe (immutable).
public struct LanguageRegistry: Sendable {
    /// Every language in this registry, in the order supplied at construction.
    public let languages: [LanguageMetadata]

    private let byID: [LanguageID: LanguageMetadata]
    private let byExtension: [String: LanguageMetadata]
    private let byFilename: [String: LanguageMetadata]
    private let byInterpreter: [String: LanguageMetadata]

    // MARK: - Construction

    /// Creates a registry from `languages`, validating that it is internally
    /// consistent.
    ///
    /// Validation, in declaration order, throws the first violation it finds:
    ///
    /// - no two entries share a ``LanguageID``
    ///   (``LanguageRegistryError/duplicateLanguageID(_:)``);
    /// - no entry lists the same extension twice
    ///   (``LanguageRegistryError/duplicateFileExtensionWithinLanguage(fileExtension:language:)``);
    /// - no extension is claimed by two languages
    ///   (``LanguageRegistryError/duplicateFileExtension(fileExtension:existing:conflicting:)``);
    /// - no whole-filename is claimed by two languages
    ///   (``LanguageRegistryError/duplicateFilename(filename:existing:conflicting:)``).
    ///
    /// Interpreters are intentionally **not** required to be unique across
    /// languages: an override may deliberately reassign one, and later entries
    /// win in the interpreter index.
    ///
    /// - Parameter languages: The metadata to register.
    /// - Throws: ``LanguageRegistryError`` on the first inconsistency.
    public init(languages: [LanguageMetadata]) throws {
        var byID: [LanguageID: LanguageMetadata] = [:]
        var byExtension: [String: LanguageMetadata] = [:]
        var byFilename: [String: LanguageMetadata] = [:]
        var byInterpreter: [String: LanguageMetadata] = [:]

        for language in languages {
            guard byID[language.id] == nil else {
                throw LanguageRegistryError.duplicateLanguageID(language.id)
            }
            byID[language.id] = language

            var seenLocal: Set<String> = []
            for ext in language.fileExtensions {
                guard seenLocal.insert(ext).inserted else {
                    throw LanguageRegistryError.duplicateFileExtensionWithinLanguage(
                        fileExtension: ext, language: language.id
                    )
                }
                if let existing = byExtension[ext] {
                    throw LanguageRegistryError.duplicateFileExtension(
                        fileExtension: ext, existing: existing.id, conflicting: language.id
                    )
                }
                byExtension[ext] = language
            }

            for name in language.filenames {
                if let existing = byFilename[name] {
                    throw LanguageRegistryError.duplicateFilename(
                        filename: name, existing: existing.id, conflicting: language.id
                    )
                }
                byFilename[name] = language
            }

            for interpreter in language.interpreters {
                byInterpreter[interpreter] = language
            }
        }

        self.languages = languages
        self.byID = byID
        self.byExtension = byExtension
        self.byFilename = byFilename
        self.byInterpreter = byInterpreter
    }

    /// The registry of every language ``LanguageCatalog`` knows about.
    ///
    /// Built once from ``LanguageCatalog/all``. That data is a curated constant
    /// and is covered by tests asserting it forms a valid registry, so the
    /// force-try here cannot trap in practice.
    public static let standard: LanguageRegistry = {
        do {
            return try LanguageRegistry(languages: LanguageCatalog.all)
        } catch {
            preconditionFailure("LanguageCatalog.all is not a valid LanguageRegistry: \(error)")
        }
    }()

    // MARK: - Lookups

    /// The metadata for a language id, or `nil` if the id is not registered.
    ///
    /// - Parameter id: The language identity to look up.
    public func metadata(for id: LanguageID) -> LanguageMetadata? {
        byID[id]
    }

    /// The language owning `fileExtension`, or `nil`.
    ///
    /// Matching is case-insensitive and tolerant of a leading dot, so
    /// `"SWIFT"`, `".swift"`, and `"swift"` resolve identically.
    ///
    /// - Parameter fileExtension: An extension, with or without leading dot.
    public func language(forExtension fileExtension: String) -> LanguageMetadata? {
        var normalized = fileExtension.lowercased()
        if normalized.hasPrefix(".") {
            normalized.removeFirst()
        }
        return byExtension[normalized]
    }

    /// The language indicated by a whole file name (e.g. `"Dockerfile"`,
    /// `"package.json"`, `"Makefile"`), or `nil`.
    ///
    /// Matching is case-insensitive against the exact file name; it does not
    /// fall back to extension detection.
    ///
    /// - Parameter filename: The file's name (not a full path).
    public func language(forFilename filename: String) -> LanguageMetadata? {
        byFilename[filename.lowercased()]
    }

    /// The language indicated by a shebang interpreter base name (e.g.
    /// `"python3"`, `"bash"`), or `nil`.
    ///
    /// Pass the interpreter's base name, not the whole shebang line; use
    /// ``language(forShebangLine:)`` to parse a raw `#!` line. Matching is
    /// case-insensitive.
    ///
    /// - Parameter interpreter: The interpreter executable's base name.
    public func language(forInterpreter interpreter: String) -> LanguageMetadata? {
        byInterpreter[interpreter.lowercased()]
    }

    /// The language indicated by a raw shebang line (e.g.
    /// `"#!/usr/bin/env python3"`), or `nil`.
    ///
    /// Parses the interpreter with ``Shebang/interpreter(fromLine:)`` and looks
    /// it up. If the exact interpreter has no match, it retries once against the
    /// version-stripped base name (`python3.12` → `python`, `php8` → `php`), so
    /// versioned interpreters still resolve.
    ///
    /// - Parameter line: A shebang line (a file's first line).
    public func language(forShebangLine line: String) -> LanguageMetadata? {
        guard let interpreter = Shebang.interpreter(fromLine: line) else { return nil }
        if let match = language(forInterpreter: interpreter) {
            return match
        }
        if let base = Shebang.strippingVersionSuffix(interpreter) {
            return language(forInterpreter: base)
        }
        return nil
    }

    // MARK: - Derivation

    /// A new registry that layers `overrides` on top of this one.
    ///
    /// An override whose ``LanguageMetadata/id`` already exists **replaces** that
    /// language's metadata in place (preserving position); an override with a
    /// new id is **appended**. If `overrides` itself repeats an id, the last one
    /// wins. This is how a consumer supplies richer metadata (e.g. additional
    /// interpreter aliases) without forking ``LanguageCatalog``.
    ///
    /// The result is re-validated, so an override that would make two languages
    /// share an extension or filename throws.
    ///
    /// - Parameter overrides: Replacement or additional metadata.
    /// - Returns: A new validated registry.
    /// - Throws: ``LanguageRegistryError`` if the merged set is inconsistent.
    public func merging(_ overrides: [LanguageMetadata]) throws -> LanguageRegistry {
        var result = languages
        for override in overrides {
            if let index = result.firstIndex(where: { $0.id == override.id }) {
                result[index] = override
            } else {
                result.append(override)
            }
        }
        return try LanguageRegistry(languages: result)
    }

    /// A new registry containing only the languages whose id is in `ids`.
    ///
    /// This cannot fail: a subset of a valid registry is always valid (removing
    /// languages cannot introduce a duplicate id, extension, or filename). This
    /// is how a consumer exposes only the languages it actually supports.
    ///
    /// - Parameter ids: The languages to keep. Ids not present in this registry
    ///   are ignored.
    /// - Returns: A new registry restricted to `ids`, preserving order.
    public func restricted(to ids: Set<LanguageID>) -> LanguageRegistry {
        let subset = languages.filter { ids.contains($0.id) }
        // A subset of a valid registry is always valid; the throwing path here
        // is unreachable.
        do {
            return try LanguageRegistry(languages: subset)
        } catch {
            preconditionFailure("Restricting a valid registry produced an invalid one: \(error)")
        }
    }
}
