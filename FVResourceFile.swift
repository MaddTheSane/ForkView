//
//  FVResourceFile.swift
//  ForkView
//
//  Created by C.W. Betts on 5/12/15.
//

import Foundation

@objc(FVResourceErrors) public enum ResourceErrors: Int, Error {
    case invalidHeader
    case invalidMap
    case InvalidTypesList
    case noResources
    case badFile
}

final public class FVResourceFile: NSObject {
    @objc public private(set) var types: [FVResourceType] = []
    public private(set) var isResourceFork = false
    private var header = ResourceHeader()
    private var map = ResourceMap()
    private let dataReader: FVDataReader!
    
    struct ResourceAttributes: OptionSet {
        var rawValue: UInt16
        
        /// System or application heap?
        static var sysHeap: ResourceAttributes {
            return ResourceAttributes(rawValue: 64)
        }
        
        /// Purgeable resource?
        static var purgeable: ResourceAttributes {
            return ResourceAttributes(rawValue: 32)
        }

        /// Load it in locked?
        static var locked: ResourceAttributes {
            return ResourceAttributes(rawValue: 16)
        }

        /// Protected?
        static var protected: ResourceAttributes {
            return ResourceAttributes(rawValue: 8)
        }

        /// Load in on `OpenResFile`?
        static var preload: ResourceAttributes {
            return ResourceAttributes(rawValue: 4)
        }
        
        /// Resource changed?
        static var changed: ResourceAttributes {
            return ResourceAttributes(rawValue: 2)
        }
    }
    
    private struct ResourceHeader: Equatable {
        var dataOffset: UInt32 = 0
        var mapOffset: UInt32 = 0
        var dataLength: UInt32 = 0
        var mapLength: UInt32 = 0
        
        static func ==(lhs: FVResourceFile.ResourceHeader, rhs: FVResourceFile.ResourceHeader) -> Bool {
            if lhs.dataOffset != rhs.dataOffset {
                return false
            } else if lhs.mapOffset != rhs.mapOffset {
                return false
            } else if lhs.dataLength != rhs.dataLength {
                return false
            } else if lhs.mapLength != rhs.mapLength {
                return false
            }
            
            return true
        }
    }
    
    private struct ResourceMap {
        var headerCopy = ResourceHeader()
        var nextMap: UInt32 = 0
        var fileRef: UInt16 = 0
        var attributes: UInt16 = 0
        var typesOffset: UInt16 = 0
        var namesOffset: UInt16 = 0
    }

    private func readHeader(_ aHeader: inout ResourceHeader) -> Bool {
        // read the header values
        if (!dataReader.read(CUnsignedInt(MemoryLayout<UInt32>.size), into: &aHeader.dataOffset) ||
            !dataReader.read(CUnsignedInt(MemoryLayout<UInt32>.size), into: &aHeader.mapOffset) ||
            !dataReader.read(CUnsignedInt(MemoryLayout<UInt32>.size), into: &aHeader.dataLength) ||
            !dataReader.read(CUnsignedInt(MemoryLayout<UInt32>.size), into: &aHeader.mapLength)) {
                return false
        }
        
        // swap from big endian to host
        aHeader.dataOffset = aHeader.dataOffset.bigEndian;
        aHeader.mapOffset = aHeader.mapOffset.bigEndian;
        aHeader.dataLength = aHeader.dataLength.bigEndian;
        aHeader.mapLength = aHeader.mapLength.bigEndian;

        let fileLength = UInt32(dataReader.length)
        if ((aHeader.dataOffset + aHeader.dataLength > fileLength) || (aHeader.mapOffset + aHeader.mapLength > fileLength)) {
            return false
        }

        return true
    }

    private init(contentsOfURL fileURL: URL, resourceFork: Bool) throws {
        guard let dataReader = FVDataReader(URL: fileURL, resourceFork: resourceFork) else {
            throw ResourceErrors.badFile
        }
        self.dataReader = dataReader
        super.init()
        
        guard readHeader(&header) else {
            throw ResourceErrors.invalidHeader
        }
        
        //NSLog(@"HEADER (%u, %u), (%u, %u)", header->dataOffset, header->dataLength, header->mapOffset, header->mapLength);
        
        guard readMap() else {
            throw ResourceErrors.invalidMap
        }
        
        guard readTypes() else {
            throw ResourceErrors.InvalidTypesList
        }
        
        // Don't open empty (but valid) resource forks
        guard types.count != 0 else {
            throw ResourceErrors.noResources
        }
        return
    }
    
    private func readMap() -> Bool {
        // seek to the map offset
        guard dataReader.seekTo(Int(header.mapOffset)) else {
            return false;
        }
        
        // read the map values
        guard readHeader(&map.headerCopy) else {
            return false;
        }

        let zeros = [Int8](repeating: 0, count: 16)
        if (map.headerCopy != header) && (memcmp(&map.headerCopy, zeros, zeros.count) != 0) {
            print("Bad match!")
        }
        
        if (!dataReader.read(CUnsignedInt(MemoryLayout<UInt32>.size), into: &map.nextMap) ||
            !dataReader.read(CUnsignedInt(MemoryLayout<UInt16>.size), into: &map.fileRef) ||
            !dataReader.read(CUnsignedInt(MemoryLayout<UInt16>.size), into: &map.attributes) ||
            !dataReader.read(CUnsignedInt(MemoryLayout<UInt16>.size), into: &map.typesOffset) ||
            !dataReader.read(CUnsignedInt(MemoryLayout<UInt16>.size), into: &map.namesOffset)) {
                return false
        }
        
        map.nextMap = map.nextMap.bigEndian
        map.fileRef = map.fileRef.bigEndian
        map.attributes = map.attributes.bigEndian
        map.typesOffset = map.typesOffset.bigEndian
        map.namesOffset = map.namesOffset.bigEndian

        return true
    }
    
    private func readTypes() -> Bool {
        let typesOffset = dataReader.position
        
        var numberOfTypes: UInt16 = 0
        if !dataReader.read(CUnsignedInt(MemoryLayout<UInt16>.size), into: &numberOfTypes) {
            return false
        }
        numberOfTypes = numberOfTypes.bigEndian + 1
        
        var typesTemp = [FVResourceType]()
        for _ in 0..<numberOfTypes {
            var type: OSType = 0
            var numberOfResources: UInt16 = 0
            var referenceListOffset: UInt16 = 0
            if !dataReader.read(CUnsignedInt(MemoryLayout<OSType>.size), into: &type) ||
                !dataReader.read(CUnsignedInt(MemoryLayout<UInt16>.size), into: &numberOfResources) ||
                !dataReader.read(CUnsignedInt(MemoryLayout<UInt16>.size), into: &referenceListOffset) {
                    return false;
            }
            type = type.bigEndian
            numberOfResources = numberOfResources.bigEndian + 1
            referenceListOffset = referenceListOffset.bigEndian
            
            let obj = FVResourceType()
            obj.type = type;
            obj.count = UInt32(numberOfResources)
            obj.offset = UInt32(referenceListOffset)
            typesTemp.append(obj)
        }
        
        for obj in typesTemp {
            var tmpResources = [FVResource]()
            
            for resIndex in 0..<obj.count {
                if !dataReader.seekTo(typesOffset + Int(obj.offset) + Int(resIndex * 12)) {
                    return false
                }
                
                var resourceID: UInt16 = 0
                var nameOffset: Int16 = 0
                var attributes: UInt8 = 0
                var dataOffsetBytes: (UInt8, UInt8, UInt8) = (0, 0, 0)
                var resHandle: UInt32 = 0
                
                if !dataReader.read(UInt32(MemoryLayout<UInt16>.size), into: &resourceID) ||
                    !dataReader.read(UInt32(MemoryLayout<Int16>.size), into: &nameOffset) ||
                    !dataReader.read(UInt32(MemoryLayout<UInt8>.size), into: &attributes) ||
                    !dataReader.read(UInt32(MemoryLayout<(UInt8, UInt8, UInt8)>.size), into: &dataOffsetBytes) ||
                    !dataReader.read(UInt32(MemoryLayout<UInt32>.size), into: &resHandle) {
                        return false;
                }
                
                resourceID = resourceID.bigEndian
                nameOffset = nameOffset.bigEndian
                resHandle = resHandle.bigEndian
                
                let dataOffset: UInt32 = {
                    var toRet = UInt32(dataOffsetBytes.2)
                    toRet |= UInt32(dataOffsetBytes.0) << 16
                    toRet |= UInt32(dataOffsetBytes.1) << 8

                    return toRet
                }()
                
                var name = Array<Int8>(repeating: 0, count: 256)
                var nameLength: UInt8 = 0
                
                if (nameOffset != -1) && (dataReader.seekTo(Int(header.mapOffset) + Int(map.namesOffset) + Int(nameOffset))) {
                    if !dataReader.read(UInt32(MemoryLayout<UInt8>.size), into: &nameLength) || !dataReader.read(UInt32(nameLength), into: &name) {
                        nameLength = 0
                    }
                }
                name[Int(nameLength)] = 0
                
                var dataLength: UInt32 = 0
                if dataReader.seekTo(Int(header.dataOffset + dataOffset)) && dataReader.read(UInt32(MemoryLayout<UInt32>.size), into: &dataLength) {
                    dataLength = dataLength.bigEndian
                }

                //NSLog(@"%@[%u] %u %s", obj.typeString, resourceID, dataLength, name);
                let resource = FVResource()
                resource.ident = resourceID
                resource.dataSize = dataLength
                resource.dataOffset = dataOffset + UInt32(MemoryLayout<UInt32>.size)
                if strlen(name) != 0 {
                    resource.name = String(cString: name, encoding: String.Encoding.macOSRoman)!
                }
                resource.file = self
                resource.type = obj
                tmpResources.append(resource)
            }
            tmpResources.sort(by: { (lhs, rhs) -> Bool in
                return lhs.ident > rhs.ident
            })
            obj.resources = tmpResources
        }
        
        typesTemp.sort { (lhs, rhs) -> Bool in
            let compVal = lhs.typeString.caseInsensitiveCompare(rhs.typeString)
            return compVal == .orderedAscending
        }
        
        types = typesTemp
        return true
    }

    internal func dataForResource(_ resource: FVResource) -> Data? {
        if !dataReader.seekTo(Int(header.dataOffset + resource.dataOffset)) {
            return nil
        }
        
        return dataReader.read(Int(resource.dataSize))
    }
    
    // TODO: implement, but how?
    //convenience init(contentsOfURL fileURL: NSURL) throws {
    //
    //}
    
    public class func resourceFileWithContents(of fileURL: URL) throws -> FVResourceFile {
        var tmpError: Error?
        
        do {
            let file = try FVResourceFile(contentsOfURL: fileURL, resourceFork: true)
            file.isResourceFork = true
            return file
        } catch let error1 {
            tmpError = error1
            do {
                let file = try FVResourceFile(contentsOfURL: fileURL, resourceFork: false)
                return file
            } catch let error {
                tmpError = error
            }
            throw tmpError!
        }
    }
}
