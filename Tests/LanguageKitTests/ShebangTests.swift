import Testing
@testable import LanguageKit

/// Pins the shared shebang-line parsing mechanics in ``Shebang``.
@Suite struct ShebangTests {
    @Test func returnsNilForNonShebangLines() {
        #expect(Shebang.interpreter(fromLine: "") == nil)
        #expect(Shebang.interpreter(fromLine: "print('hi')") == nil)
        #expect(Shebang.interpreter(fromLine: "# not a shebang") == nil)
        #expect(Shebang.interpreter(fromLine: "!/bin/sh") == nil)
        #expect(Shebang.interpreter(fromLine: "  #!/bin/sh") == nil) // must be at column 0
    }

    @Test func stripsPathAndTakesBasename() {
        #expect(Shebang.interpreter(fromLine: "#!/bin/bash") == "bash")
        #expect(Shebang.interpreter(fromLine: "#!/usr/bin/python") == "python")
        #expect(Shebang.interpreter(fromLine: "#!/usr/local/bin/ruby") == "ruby")
    }

    @Test func ignoresFlagsAndArguments() {
        #expect(Shebang.interpreter(fromLine: "#!/bin/bash -e") == "bash")
        #expect(Shebang.interpreter(fromLine: "#!/bin/sh -eu -o pipefail") == "sh")
    }

    @Test func handlesEnvIndirection() {
        #expect(Shebang.interpreter(fromLine: "#!/usr/bin/env python3") == "python3")
        #expect(Shebang.interpreter(fromLine: "#!/usr/bin/env node") == "node")
    }

    @Test func skipsEnvOptionFlags() {
        #expect(Shebang.interpreter(fromLine: "#!/usr/bin/env -S python3") == "python3")
        #expect(Shebang.interpreter(fromLine: "#!/usr/bin/env -S ruby -w") == "ruby")
    }

    @Test func lowercasesResult() {
        #expect(Shebang.interpreter(fromLine: "#!/bin/BASH") == "bash")
        #expect(Shebang.interpreter(fromLine: "#!/usr/bin/env PYTHON3") == "python3")
    }

    @Test func toleratesSpaceAfterBang() {
        #expect(Shebang.interpreter(fromLine: "#! /bin/sh") == "sh")
        #expect(Shebang.interpreter(fromLine: "#! /usr/bin/env python") == "python")
    }

    @Test func toleratesTrailingNewline() {
        #expect(Shebang.interpreter(fromLine: "#!/bin/bash\n") == "bash")
        #expect(Shebang.interpreter(fromLine: "#!/usr/bin/env python3\r\n") == "python3")
    }
}
