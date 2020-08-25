//
//  LineReader.swift
//  Flext
//
//  Created by Michael Camilleri on 4/8/20.
//  Copyright © 2020 Michael Camilleri. All rights reserved.
//

import Foundation

public class LineReader {
    public let path: String
    
    fileprivate let file: UnsafeMutablePointer<FILE>!

    init?(at url: URL) {
        self.path = url.path
        file = fopen(path, "r")
        guard file != nil else { return nil }
    }

    public var nextLine: String? {
        var line:UnsafeMutablePointer<CChar>? = nil
        var linecap:Int = 0
        defer { free(line) }
        return getline(&line, &linecap, file) > 0 ? String(cString: line!) : nil
    }

    deinit {
        fclose(file)
    }
}

extension LineReader: Sequence {
    public func makeIterator() -> AnyIterator<String> {
        return AnyIterator<String> { self.nextLine }
    }
}
