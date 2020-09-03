//
//  LineReader.swift
//  Flext
//
//  Created by Michael Camilleri on 4/8/20.
//  Copyright © 2020 Michael Camilleri. All rights reserved.
//

import Foundation

/**
 Reads lines from a text file.

 There are moments where Flext needs to be able to check relatively quickly
 whether a processor has options. The simplest solution is that whenever this
 need arises, Flext could evaluate the JavaScript file and extract the
 additional arguments. The problem is that this would involve loading the script
 into the JavaScript context, rendering the function to a string and parsing the
 rendered function definition.

 This might be an acceptable approach for one processor but is less than optimal
 for when we are iterating through a collection of processors. Having a line
 reader allows us to use a heuristic where we scan each line of a processor and
 check whether the line `var = process(text)` is present. If it is, then we know
 that there are no options.

 Swift does not provide a line reader for reading from text files one line at a
 time. This class provides an implementation.
 */
public class LineReader {

    // MARK: - Properties

    /// The path to the file to read.
    let path: String

    /// A pointer to the file to read.
    fileprivate let file: UnsafeMutablePointer<FILE>!

    /// The next line to be read.
    var nextLine: String? {
        var line: UnsafeMutablePointer<CChar>? = nil
        var linecap: Int = 0
        defer { free(line) }
        return getline(&line, &linecap, file) > 0 ? String(cString: line!) : nil
    }

    // MARK: - Initialisers

    /**
     Creates the line reader for a given URL.

     - Parameters:
        - url: The URL of the file to read.
     */
    init?(at url: URL) {
        self.path = url.path
        file = fopen(path, "r")
        guard file != nil else { return nil }
    }

    // MARK: - Deinitialisers

    /**
     Destroys the line reader.
     */
    deinit {
        fclose(file)
    }
}

extension LineReader: Sequence {
    public func makeIterator() -> AnyIterator<String> {
        return AnyIterator<String> { self.nextLine }
    }
}
