//
//  FVDataReader.swift
//  ForkView
//
//  Created by Kevin Wojniak on 5/2/15.
//  Copyright (c) 2015 Kevin Wojniak. All rights reserved.
//

import Foundation
import Darwin.POSIX.sys.xattr

public final class FVDataReader {
    private var data = Data()
    public private(set) var position = 0

    public var length: Int {
        return data.count
    }

    public init(_ data: Data) {
        self.data = data
    }

    public init?(url: URL, resourceFork: Bool) {
        // Apple's docs say "The maximum size of the resource fork in a file is 16 megabytes"
        let maxResourceSize = 16777216
        if !resourceFork {
            var fileSize: AnyObject?
            do {
                let num = try url.resourceValues(forKeys: [.fileSizeKey])
                fileSize = num.fileSize as AnyObject?
            } catch _ {
            }
            guard let fileSizeNum = fileSize as? NSNumber else {
                return nil
            }
            if fileSizeNum.intValue == 0 || fileSizeNum.intValue >= maxResourceSize {
                return nil
            }
            guard let data = try? Data(contentsOf: url) else {
                return nil
            }
            self.data = data
        } else {
            let rsrcSize = url.withUnsafeFileSystemRepresentation({ (namePtr) -> Int in
                return getxattr(namePtr, XATTR_RESOURCEFORK_NAME, nil, 0, 0, 0)
            })
            if rsrcSize <= 0 || rsrcSize >= maxResourceSize {
                return nil
            }
            var data = Data(count: rsrcSize)

            if data.withUnsafeMutableBytes({ (val: UnsafeMutableRawBufferPointer) -> Int in
                url.withUnsafeFileSystemRepresentation({ (namePtr) -> Int in
                    let retval = getxattr(namePtr, XATTR_RESOURCEFORK_NAME, val.baseAddress!, rsrcSize, 0, 0)
                    return retval
                }) }) == rsrcSize {
                self.data = data
            } else {
                return nil
            }
        }
    }

    public class func dataReader(URL: URL, resourceFork: Bool) -> FVDataReader? {
        return FVDataReader(url: URL, resourceFork: resourceFork)
    }

    public func read(_ size: Int) -> Data? {
        if position + size > self.length {
            return nil
        }
        let subdata = data[(data.startIndex+position)..<(data.startIndex+position+size)]
        position += size
        return subdata
    }

    public func read(_ size: CUnsignedInt, into buf: UnsafeMutableRawPointer) -> Bool {
        guard let data = self.read(Int(size)) else {
            return false
        }
        data.copyBytes(to: buf.assumingMemoryBound(to: UInt8.self), count: Int(size))
        return true
    }

    public func seekTo(_ offset: Int) -> Bool {
        if offset >= self.length {
            return false
        }
        position = offset
        return true
    }

    public enum Endian {
        case little, big
    }

    public func readUInt16<B>(_ endian: Endian = .big, _ val: inout B) -> Bool where B: RawRepresentable, B.RawValue == UInt16 {
        var preVal: B.RawValue = 0
        if let dat = read(MemoryLayout<UInt16>.size) {
            (dat as NSData).getBytes(&preVal, length: MemoryLayout<UInt16>.size)
            preVal = endian == .big ? preVal.bigEndian : preVal.littleEndian
            val = B(rawValue: preVal)!
            return true
        }
        return false
    }

    public func readUInt16(_ endian: Endian, _ val: inout UInt16) -> Bool {
        if let dat = read(MemoryLayout<UInt16>.size) {
            (dat as NSData).getBytes(&val, length: MemoryLayout<UInt16>.size)
            val = endian == .big ? UInt16(bigEndian: val) : UInt16(littleEndian: val)
            return true
        }
        return false
    }

    public func readInt16<B>(_ endian: Endian = .big, _ val: inout B) -> Bool where B: RawRepresentable, B.RawValue == Int16 {
        var preVal: B.RawValue = 0
        if let dat = read(MemoryLayout<Int16>.size) {
            (dat as NSData).getBytes(&preVal, length: MemoryLayout<Int16>.size)
            preVal = endian == .big ? preVal.bigEndian : preVal.littleEndian
            val = B(rawValue: preVal)!
            return true
        }
        return false
    }

    public func readInt16(_ endian: Endian = .big, _ val: inout Int16) -> Bool {
        if let dat = read(MemoryLayout<Int16>.size) {
            (dat as NSData).getBytes(&val, length: MemoryLayout<Int16>.size)
            val = endian == .big ? Int16(bigEndian: val) : Int16(littleEndian: val)
            return true
        }
        return false
    }

    public func readUInt32<B>(_ endian: Endian = .big, _ val: inout B) -> Bool where B: RawRepresentable, B.RawValue == UInt32 {
        var preVal: B.RawValue = 0
        if let dat = read(MemoryLayout<UInt32>.size) {
            (dat as NSData).getBytes(&preVal, length: MemoryLayout<UInt32>.size)
            preVal = endian == .big ? preVal.bigEndian : preVal.littleEndian
            val = B(rawValue: preVal)!
            return true
        }
        return false
    }
    
    public func readUInt32(_ endian: Endian, _ val: inout UInt32) -> Bool {
        if let dat = read(MemoryLayout<UInt32>.size) {
            (dat as NSData).getBytes(&val, length: MemoryLayout<UInt32>.size)
            val = endian == .big ? UInt32(bigEndian: val) : UInt32(littleEndian: val)
            return true
        }
        return false
    }
    
    public func readInt32<B>(_ endian: Endian = .big, _ val: inout B) -> Bool where B: RawRepresentable, B.RawValue == Int32 {
        var preVal: B.RawValue = 0
        if let dat = read(MemoryLayout<Int32>.size) {
            (dat as NSData).getBytes(&preVal, length: MemoryLayout<Int32>.size)
            preVal = endian == .big ? preVal.bigEndian : preVal.littleEndian
            val = B(rawValue: preVal)!
            return true
        }
        return false
    }
    
    public func readInt32(_ endian: Endian, _ val: inout Int32) -> Bool {
        if let dat = read(MemoryLayout<Int32>.size) {
            (dat as NSData).getBytes(&val, length: MemoryLayout<Int32>.size)
            val = endian == .big ? Int32(bigEndian: val) : Int32(littleEndian: val)
            return true
        }
        return false
    }

    public func readUInt8<B>(_ val: inout B) -> Bool where B: RawRepresentable, B.RawValue == UInt8 {
        if let dat = read(MemoryLayout<UInt8>.size) {
            (dat as NSData).getBytes(&val, length: MemoryLayout<UInt8>.size)
            return true
        }
        return false
    }
    
    public func readInt8<B>(_ val: inout B) -> Bool where B: RawRepresentable, B.RawValue == Int8 {
        if let dat = read(MemoryLayout<Int8>.size) {
            (dat as NSData).getBytes(&val, length: MemoryLayout<Int8>.size)
            return true
        }
        return false
    }

    public func readUInt8(_ val: inout UInt8) -> Bool {
        if let dat = read(MemoryLayout<UInt8>.size) {
            (dat as NSData).getBytes(&val, length: MemoryLayout<UInt8>.size)
            return true
        }
        return false
    }

    public func readInt8(_ val: inout Int8) -> Bool {
        if let dat = read(MemoryLayout<Int8>.size) {
            (dat as NSData).getBytes(&val, length: MemoryLayout<Int8>.size)
            return true
        }
        return false
    }
}
