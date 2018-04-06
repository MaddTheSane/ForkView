//
//  FVResourceType.swift
//  ForkView
//
//  Created by Kevin Wojniak on 8/3/14.
//  Copyright (c) 2014 Kevin Wojniak. All rights reserved.
//

import Foundation

final public class FVResourceType: NSObject {
    @objc public var type: OSType = 0
    @objc public var count: UInt32 = 0
    @objc public var offset: UInt32 = 0
    @objc public var resources = [FVResource]()

    @objc public var typeString: String {
        return UTCreateStringForOSType(type).takeRetainedValue() as String
    }
	
	override public var description: String {
		return typeString
	}
}
