/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See http://swift.org/LICENSE.txt for license information
 See http://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

//Prefixes "spm_" were swapped for "cli"

extension String {
    /**
     Remove trailing newline characters. By default chomp removes
     all trailing \n (UNIX) or all trailing \r\n (Windows) (it will
     not remove mixed occurrences of both separators.
    */
    public func cli_chomp(separator: String? = nil) -> String {
        func scrub(_ separator: String) -> String {
            var E = endIndex
            while String(self[startIndex..<E]).hasSuffix(separator) && E > startIndex {
                E = index(before: E)
            }
            return String(self[startIndex..<E])
        }

        if let separator = separator {
            return scrub(separator)
        } else if hasSuffix("\r\n") {
            return scrub("\r\n")
        } else if hasSuffix("\n") {
            return scrub("\n")
        } else {
            return self
        }
    }

    /**
     Trims whitespace from both ends of a string, if the resulting
     string is empty, returns `nil`.String
     
     Useful because you can short-circuit off the result and thus
     handle “falsy” strings in an elegant way:
     
         return userInput.chuzzle() ?? "default value"
    */
    public func cli_chuzzle() -> String? {
        var cc = self

        loop: while true {
            switch cc.first {
            case nil:
                return nil
            case "\n"?, "\r"?, " "?, "\t"?, "\r\n"?:
                cc = String(cc.dropFirst())
            default:
                break loop
            }
        }

        loop: while true {
            switch cc.last {
            case nil:
                return nil
            case "\n"?, "\r"?, " "?, "\t"?, "\r\n"?:
                cc = String(cc.dropLast())
            default:
                break loop
            }
        }

        return String(cc)
    }

    /// Splits string around a delimiter string into up to two substrings
    /// If delimiter is not found, the second returned substring is nil
    public func cli_split(around delimiter: String) -> (String, String?) {
        let comps = self.cli_split(around: Array(delimiter))
        let head = String(comps.0)
        if let tail = comps.1 {
            return (head, String(tail))
        } else {
            return (head, nil)
        }
    }

    /// Drops the given suffix from the string, if present.
    public func cli_dropSuffix(_ suffix: String) -> String {
        if hasSuffix(suffix) {
           return String(dropLast(suffix.count))
        }
        return self
    }

    public func cli_dropGitSuffix() -> String {
        return cli_dropSuffix(".git")
    }

    public func cli_multilineIndent(count: Int) -> String {
        return self
            .split(separator: "\n")
            .map{ String(repeating: " ", count: count) + $0 }
            .joined(separator: "\n")
    }
}

extension String {
    /// Computes the number of edits needed to transform first string to second.
    ///
    /// - Complexity: O(_n*m_), where *n* is the length of the first String and
    ///   *m* is the length of the second one.
    public func editDistance(from second: String) -> Int {
        // FIXME: We should use the new `CollectionDifference` API once the
        // deployment target is bumped.
        let a = Array(self.utf16)
        let b = Array(second.utf16)
        var distance = [[Int]](repeating: [Int](repeating: 0, count: b.count + 1), count: a.count + 1)
        for i in 0...a.count {
            for j in 0...b.count {
                if i == 0 {
                    distance[i][j] = j
                } else if j == 0 {
                    distance[i][j] = i
                } else if a[i - 1] == b[j - 1] {
                    distance[i][j] = distance[i - 1][j - 1]
                } else {
                    let insertion = distance[i][ j - 1]
                    let deletion = distance[i - 1][j]
                    let replacement = distance[i - 1][j - 1]
                    distance[i][j] = 1 + Swift.min(insertion, deletion, replacement)
                }
            }
        }
        return distance[a.count][b.count]
    }
    
    /// Finds the "best" match for a `String` from an array of possible options.
    ///
    /// - Parameters:
    ///     - input: The input `String` to match.
    ///     - options: The available options for `input`.
    ///
    /// - Returns: The best match from the given `options`, or `nil` if none were sufficiently close.
    public func bestMatch(from options: [String]) -> String? {
        let input = self
        return options
            .map { ($0, input.editDistance(from: $0)) }
            // Filter out unreasonable edit distances. Based on:
            // https://github.com/apple/swift/blob/37daa03b7dc8fb3c4d91dc560a9e0e631c980326/lib/Sema/TypeCheckNameLookup.cpp#L606
            .filter { $0.1 <= ($0.0.count + 2) / 3 }
            // Sort by edit distance
            .sorted { $0.1 < $1.1 }
            .first?.0
    }
}
