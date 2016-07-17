//
//  FVDataReader.swift
//  ForkView
//
//  Created by Kevin Wojniak on 5/2/15.
//  Copyright (c) 2015 Kevin Wojniak. All rights reserved.
//

import Foundation
import Darwin.POSIX.sys.xattr

/// Apple's docs say "The maximum size of the resource fork in a file is 16 megabytes"
private let maxResourceSize = 16777216

public final class FVDataReader {
    private var data = Data()
    public private(set) var position = 0
    
    public var length: Int {
        return data.count
    }
    
    public init(_ data: Data) {
        self.data = data
    }
    
    public init?(URL: Foundation.URL, resourceFork: Bool) {
        if !resourceFork {
            var fileSize: AnyObject?
            do {
                try (URL as NSURL).getResourceValue(&fileSize, forKey: URLResourceKey.fileSizeKey)
            } catch _ {
            }
            let fileSizeNum = fileSize as? NSNumber
            if fileSizeNum == nil {
                return nil
            }
            if let fileSizeNum = fileSize as? NSNumber, data = try? Data(contentsOf: URL) where fileSizeNum.intValue == 0 || fileSizeNum.intValue >= maxResourceSize {
            self.data = data
            } else {
                return nil
            }
        } else {
            let rsrcSize = getxattr((URL as NSURL).fileSystemRepresentation, XATTR_RESOURCEFORK_NAME, nil, 0, 0, 0)
            if rsrcSize <= 0 || rsrcSize >= maxResourceSize {
                return nil
            }
            if let data = NSMutableData(length: rsrcSize) where getxattr((URL as NSURL).fileSystemRepresentation, XATTR_RESOURCEFORK_NAME, data.mutableBytes, rsrcSize, 0, 0) != rsrcSize {
                self.data = data as Data
            } else {
                return nil
            }
        }
    }
    
    public class func dataReader(_ URL: Foundation.URL, resourceFork: Bool) -> FVDataReader? {
        return FVDataReader(URL: URL, resourceFork: resourceFork)
    }
    
    public func read(_ size: Int) -> Data? {
        if (position + size > self.length) {
            return nil
        }
		let subdata = data.subdata(in: position..<(position+size))
        position += size
        return subdata
    }
    
    public func read(_ size: CUnsignedInt, into buf: UnsafeMutablePointer<Void>) -> Bool {
        let data = self.read(Int(size))
        if data == nil {
            return false
        }
        (data! as NSData).getBytes(buf)
        return true
    }
    
    public func seekTo(_ offset: Int) -> Bool {
        if (offset >= self.length) {
            return false
        }
        position = offset
        return true
    }
    
    public enum Endian {
        case little, big
    }
    
    public func readUInt16(endian: Endian = .big, _ val: inout UInt16) -> Bool {
        if let dat = read(sizeof(UInt16.self)) {
            (dat as NSData).getBytes(&val, length: sizeof(UInt16.self))
            val = endian == .big ? val.bigEndian : val.littleEndian
            return true
        }
        return false
    }

    public func readInt16(endian: Endian = .big, _ val: inout Int16) -> Bool {
        if let dat = read(sizeof(Int16.self)) {
            (dat as NSData).getBytes(&val, length: sizeof(Int16.self))
            val = endian == .big ? val.bigEndian : val.littleEndian
            return true
        }
        return false
    }

    public func readUInt32(endian: Endian = .big, _ val: inout UInt32) -> Bool {
        if let dat = read(sizeof(UInt32.self)) {
            (dat as NSData).getBytes(&val, length: sizeof(UInt32.self))
            val = endian == .big ? val.bigEndian : val.littleEndian
            return true
        }
        return false
    }
    
    public func readInt32(endian: Endian = .big, _ val: inout Int32) -> Bool {
        if let dat = read(sizeof(Int32.self)) {
            (dat as NSData).getBytes(&val, length: sizeof(Int32.self))
            val = endian == .big ? val.bigEndian : val.littleEndian
            return true
        }
        return false
    }
    
    public func readUInt8(_ val: inout UInt8) -> Bool {
        if let dat = read(sizeof(UInt8.self)) {
            (dat as NSData).getBytes(&val, length: sizeof(UInt8.self))
            return true
        }
        return false
    }

    public func readInt8(_ val: inout Int8) -> Bool {
        if let dat = read(sizeof(Int8.self)) {
            (dat as NSData).getBytes(&val, length: sizeof(Int8.self))
            return true
        }
        return false
    }
}
