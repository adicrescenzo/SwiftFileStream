import Foundation

class StreamWriter  {
    
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
