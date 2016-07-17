//
//  AttributesFormatter.swift
//  Classic Suitcase Viewer
//
//  Created by C.W. Betts on 4/21/15.
//  Copyright (c) 2015 C.W. Betts. All rights reserved.
//

import Cocoa

private typealias FVResAttributes = FVResourceFile.ResourceAttributes

public final class AttributesFormatter: Formatter {
	override public func string(for obj: AnyObject?) -> String? {
		if let aNum = obj as? Int {
			var addComma = false
			var string = ""
			var attributeCount = 0
			let attributes = FVResAttributes(rawValue: UInt16(aNum))
			
			func countAttribute(_ anAttrib: FVResAttributes) {
				if attributes.contains(anAttrib) {
					attributeCount += 1
				}
			}
			
			countAttribute(.Preload)
			countAttribute(.Protected)
			countAttribute(.Locked)
			countAttribute(.Purgeable)
			countAttribute(.SysHeap)
			
			func addToString(_ anAttrib: FVResAttributes, longString: String, shortString: String? = nil) {
				if addComma {
					string += ", "
				}
				if attributeCount > 2 {
					if let shortString = shortString {
						string += shortString
					} else {
                        let subStrIdx = longString.index(longString.startIndex, offsetBy: 3)
                        string += longString.substring(to: subStrIdx)
					}
				} else {
					string += longString
				}
				
				addComma = true
			}
			
			addToString(.Preload, longString: "Preload")
			addToString(.Protected, longString: "Protected")
			addToString(.Locked, longString: "Locked", shortString: "L")
			addToString(.Purgeable, longString: "Purgeable")
			addToString(.SysHeap, longString: "SysHeap")
			
			return string
		}
		return nil
	}
	
	override public func attributedString(for obj: AnyObject?, withDefaultAttributes attrs: [String : AnyObject]?) -> AttributedString? {
		if let aStr = string(for: obj) {
			return AttributedString(string: aStr, attributes: attrs)
		} else {
			return nil
		}
	}
	
	override public func editingString(for obj: AnyObject) -> String? {
		return nil
	}
	
	override public func getObjectValue(_ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?, for string: String, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
		return false
	}
	
	override public func isPartialStringValid(_ partialString: String, newEditingString newString: AutoreleasingUnsafeMutablePointer<NSString?>?, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
		return false
	}
}
