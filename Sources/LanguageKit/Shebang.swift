import Foundation

/// Shared parsing for the interpreter named on a script's `#!` shebang line.
///
/// This is the *mechanics* every consumer needs — recognizing the `#!` marker,
/// stripping the interpreter's directory path down to its base name, resolving
/// the `env` indirection (`#!/usr/bin/env python3`), and ignoring flags and
/// arguments (`#!/bin/bash -e`). It deliberately does **not** attempt any
/// product-specific content sniffing beyond the shebang line; those heuristics
/// stay in the consuming editors.
///
/// To turn a parsed interpreter into a language, use
/// ``LanguageRegistry/language(forShebangLine:)`` (which also applies the shared
/// version-suffix fallback), or look the base name up directly with
/// ``LanguageRegistry/language(forInterpreter:)``.
public enum Shebang {
    /// The interpreter base name named on a shebang line, lowercased, or `nil`
    /// if `line` is not a shebang or names no interpreter.
    ///
    /// The line must begin with `#!` at column 0. The interpreter is the base
    /// name (last path component) of the first token after `#!`, except when
    /// that base name is `env`: then it is the first following token that is
    /// neither an option flag (`-S`, `-i`, …) nor a `NAME=value` assignment.
    /// Trailing flags and arguments are ignored. Examples:
    ///
    /// - `#!/bin/bash` → `"bash"`
    /// - `#!/bin/bash -e` → `"bash"`
    /// - `#!/usr/bin/env python3` → `"python3"`
    /// - `#!/usr/bin/env -S ruby -w` → `"ruby"`
    ///
    /// - Parameter line: A single line (typically a file's first line); a
    ///   trailing newline is tolerated.
    /// - Returns: The lowercased interpreter base name, or `nil`.
    public static func interpreter(fromLine line: String) -> String? {
        guard line.hasPrefix("#!") else { return nil }

        // Everything after "#!", split on any whitespace (spaces, tabs, and
        // newlines — including a `\r\n` grapheme — so trailing line endings and
        // the space in `#! /bin/sh` are handled uniformly).
        let tokens = line
            .dropFirst(2)
            .split(whereSeparator: { $0.isWhitespace })
            .map(String.init)
        guard let first = tokens.first else { return nil }

        if baseName(of: first) == "env" {
            for token in tokens.dropFirst() {
                if token.hasPrefix("-") { continue }        // env option flag, e.g. -S
                if token.contains("=") { continue }         // env NAME=value assignment
                return baseName(of: token).lowercased()
            }
            return nil
        }

        return baseName(of: first).lowercased()
    }

    /// The base name (final `/`-separated component) of a path-like token.
    private static func baseName(of token: String) -> String {
        if let slash = token.lastIndex(of: "/") {
            return String(token[token.index(after: slash)...])
        }
        return token
    }

    /// Strips a trailing version suffix (a run of digits and dots) from an
    /// interpreter base name, returning the shortened name, or `nil` when there
    /// is no such suffix to strip.
    ///
    /// This backs ``LanguageRegistry/language(forShebangLine:)``'s fallback:
    /// `python3.12` → `python`, `php8` → `php`, `ruby2.7` → `ruby`. An
    /// interpreter with no trailing digits (`python`, `bash`) returns `nil`.
    static func strippingVersionSuffix(_ interpreter: String) -> String? {
        var index = interpreter.endIndex
        while index > interpreter.startIndex {
            let previous = interpreter.index(before: index)
            let character = interpreter[previous]
            guard character.isNumber || character == "." else { break }
            index = previous
        }
        guard index < interpreter.endIndex else { return nil } // nothing stripped
        let base = String(interpreter[..<index])
        return base.isEmpty ? nil : base
    }
}
