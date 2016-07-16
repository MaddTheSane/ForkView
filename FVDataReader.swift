//
//  FVDataReader.swift
//  ForkView
//
//  Created by Kevin Wojniak on 5/2/15.
//  Copyright (c) 2015 Kevin Wojniak. All rights reserved.
//

import Foundation

/// Apple's docs say "The maximum size of the resource fork in a file is 16 megabytes"
private let maxResourceSize = 16777216

public final class FVDataReader {
    private var data = NSData()
    public private(set) var position = 0
    
    public var length: Int {
        return data.length
    }
    
    public init(_ data: NSData) {
        self.data = data
    }
    
    public init?(URL: NSURL, resourceFork: Bool) {
        if !resourceFork {
            var fileSize: AnyObject?
            do {
                try URL.getResourceValue(&fileSize, forKey: NSURLFileSizeKey)
            } catch _ {
            }
            let fileSizeNum = fileSize as? NSNumber
            if fileSizeNum == nil {
                return nil
            }
            if let fileSizeNum = fileSize as? NSNumber, data = NSData(contentsOfURL: URL) where fileSizeNum.integerValue == 0 || fileSizeNum.integerValue >= maxResourceSize {
            self.data = data
            } else {
                return nil
            }
        } else {
            let rsrcSize = getxattr(URL.path!, XATTR_RESOURCEFORK_NAME, nil, 0, 0, 0)
            if rsrcSize <= 0 || rsrcSize >= maxResourceSize {
                return nil
            }
            if let data = NSMutableData(length: rsrcSize) where getxattr(URL.path!, XATTR_RESOURCEFORK_NAME, data.mutableBytes, rsrcSize, 0, 0) != rsrcSize {
                self.data = data
            } else {
                return nil
            }
        }
    }
    
    public class func dataReader(URL: NSURL, resourceFork: Bool) -> FVDataReader? {
        return FVDataReader(URL: URL, resourceFork: resourceFork)
    }
    
    public func read(size: Int) -> NSData? {
        if (position + size > self.length) {
            return nil
        }
		let subdata = data.subdataWithRange(NSRange(location: position, length: size))
        position += size
        return subdata
    }
    
    public func read(size: CUnsignedInt, into buf: UnsafeMutablePointer<Void>) -> Bool {
        let data = self.read(Int(size))
        if data == nil {
            return false
        }
        data!.getBytes(buf)
        return true
    }
    
    public func seekTo(offset: Int) -> Bool {
        if (offset >= self.length) {
            return false
        }
        position = offset
        return true
    }
    
    public enum Endian {
        case Little, Big
    }
    
    public func readUInt16(endian: Endian = .Big, inout _ val: UInt16) -> Bool {
        if let dat = read(sizeof(UInt16)) {
            dat.getBytes(&val, length: sizeof(UInt16))
            val = endian == .Big ? val.bigEndian : val.littleEndian
            return true
        }
        return false
    }

    public func readInt16(endian: Endian = .Big, inout _ val: Int16) -> Bool {
        if let dat = read(sizeof(Int16)) {
            dat.getBytes(&val, length: sizeof(Int16))
            val = endian == .Big ? val.bigEndian : val.littleEndian
            return true
        }
        return false
    }

    public func readUInt32(endian: Endian = .Big, inout _ val: UInt32) -> Bool {
        if let dat = read(sizeof(UInt32)) {
            dat.getBytes(&val, length: sizeof(UInt32))
            val = endian == .Big ? val.bigEndian : val.littleEndian
            return true
        }
        return false
    }
    
    public func readInt32(endian: Endian = .Big, inout _ val: Int32) -> Bool {
        if let dat = read(sizeof(Int32)) {
            dat.getBytes(&val, length: sizeof(Int32))
            val = endian == .Big ? val.bigEndian : val.littleEndian
            return true
        }
        return false
    }
    
    public func readUInt8(inout val: UInt8) -> Bool {
        if let dat = read(sizeof(UInt8)) {
            dat.getBytes(&val, length: sizeof(UInt8))
            return true
        }
        return false
    }

    public func readInt8(inout val: Int8) -> Bool {
        if let dat = read(sizeof(Int8)) {
            dat.getBytes(&val, length: sizeof(Int8))
            return true
        }
        return false
    }
}
