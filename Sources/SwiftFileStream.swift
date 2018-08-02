/**
 *  SwiftFileStream
 *
 *  Copyright (c) 2018 Angelo Di Crescenzo. Licensed under the MIT license, as follows:
 *
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included in all
 *  copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 *  SOFTWARE.
 */

import Foundation

// MARK: - Public API

/**
 * Class that represents a stream reader of a file
 *
 * You can open a file and read a chunk of data, each chunk is separated by a special character used as a delimiter
 *
 */

public class StreamReader  {
    
    let encoding : String.Encoding
    let chunkSize : Int
    var fileHandle : FileHandle!
    let delimData : Data
    var buffer : Data
    var atEof : Bool
    
    init?(path: String, delimiter: String = "\n", encoding: String.Encoding = .utf8,
          chunkSize: Int = 4096) {
        
        guard let fileHandle = FileHandle(forReadingAtPath: path),
            let delimData = delimiter.data(using: encoding) else {
                return nil
        }
        self.encoding = encoding
        self.chunkSize = chunkSize
        self.fileHandle = fileHandle
        self.delimData = delimData
        self.buffer = Data(capacity: chunkSize)
        self.atEof = false
    }
    
    deinit {
        self.close()
    }
    
    /// Return next line, or nil on EOF.
    func nextLine() -> String? {
        precondition(fileHandle != nil, "Attempt to read from closed file")
        
        // Read data chunks from file until a line delimiter is found:
        while !atEof {
            if let range = buffer.range(of: delimData) {
                // Convert complete line (excluding the delimiter) to a string:
                let line = String(data: buffer.subdata(in: 0..<range.lowerBound), encoding: encoding)
                // Remove line (and the delimiter) from the buffer:
                buffer.removeSubrange(0..<range.upperBound)
                return line
            }
            let tmpData = fileHandle.readData(ofLength: chunkSize)
            if tmpData.count > 0 {
                buffer.append(tmpData)
            } else {
                // EOF or read error.
                atEof = true
                if buffer.count > 0 {
                    // Buffer contains last line in file (not terminated by delimiter).
                    let line = String(data: buffer as Data, encoding: encoding)
                    buffer.count = 0
                    return line
                }
            }
        }
        return nil
    }
    
    /// Start reading from the beginning of file.
    func rewind() -> Void {
        fileHandle.seek(toFileOffset: 0)
        buffer.count = 0
        atEof = false
    }
    
    /// Close the underlying file. No reading must be done after calling this method.
    func close() -> Void {
        fileHandle?.closeFile()
        fileHandle = nil
    }
}

extension StreamReader : Sequence {
    func makeIterator() -> AnyIterator<String> {
        return AnyIterator {
            return self.nextLine()
        }
    }
}


/**
 * Class that represents a stream writer of a file
 *
 * You can open a file and write a chunk of data, each chunk is separated by a special character used as a delimiter
 *
 */

public final class StreamWriter  {
    
    let encoding : String.Encoding
    var fileHandle : FileHandle!
    let delimData : Data
    private(set) var writtenLines: Int
    
    /// Error type specific to stream writer operation
    public enum Error: Swift.Error {
        /// Thrown when a file couldn't be opened
        case fileOpeningFailed
        /// Thrown when a String couldn't be converted into Data using the given encoding during the write process
        case stringEncodingFailed
    }

    init(path: String, delimiter: String = "\n", encoding: String.Encoding = .utf8) throws {
        
        guard let fileHandle = FileHandle(forWritingAtPath: path),
            let delimData = delimiter.data(using: encoding) else {
                throw Error.fileOpeningFailed
        }
        
        self.encoding = encoding
        self.fileHandle = fileHandle
        self.delimData = delimData
        self.writtenLines = 0
    }
    
    deinit {
        self.close()
    }
    
    func write(string: String) throws {
        guard let data = string.data(using: self.encoding) else {
            throw Error.stringEncodingFailed
        }
        
        //Writing the converted string into file
        self.fileHandle.write(data);
        
        //Appending the delimiter
        self.fileHandle.write(self.delimData)
        
        self.writtenLines += 1
    }
    
    /// Close the underlying file. No reading must be done after calling this method.
    func close() -> Void {
        fileHandle?.closeFile()
        fileHandle = nil
    }
}
