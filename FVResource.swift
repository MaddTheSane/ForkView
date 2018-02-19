//
//  FVResource.swift
//  ForkView
//
//  Created by Kevin Wojniak on 8/3/14.
//  Copyright (c) 2014 Kevin Wojniak. All rights reserved.
//

import Foundation

@objc final public class FVResource: NSObject {
    @objc public var ident: UInt16 = 0
    @objc public var name: String = ""
    @objc public var dataSize: UInt32 = 0
    @objc public var dataOffset: UInt32 = 0
    @objc public var type: FVResourceType? = nil
    @objc public weak var file: FVResourceFile? = nil
    
    @objc public var data: Data? {
        return file?.dataForResource(self)
    }
	
	override public var description: String {
		let tmpType = type?.typeString ?? "(undefined)"
		return name + ": size: \(dataSize), offset: \(dataOffset), type: \(tmpType)"
	}
}
