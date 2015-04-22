//
//  AttributesFormatter.swift
//  Classic Suitcase Viewer
//
//  Created by C.W. Betts on 4/21/15.
//  Copyright (c) 2015 C.W. Betts. All rights reserved.
//

import Cocoa

final class AttributesFormatter: NSFormatter {
	override func stringForObjectValue(obj: AnyObject) -> String? {
		if let aNum = obj as? Int {
			var addComma = false
			var string = ""
			var attributeCount = 0
			let attributes = FVResAttributes(rawValue: Int16(aNum))
			
			func countAttribute(anAttrib: FVResAttributes) {
				if (attributes & anAttrib) == anAttrib {
					attributeCount++
				}
			}
			
			countAttribute(.Preload)
			countAttribute(.Protected)
			countAttribute(.Locked)
			countAttribute(.Purgeable)
			countAttribute(.SysHeap)
			
			func addToString(anAttrib: FVResAttributes, #longString: String, shortString: String? = nil) {
				if addComma {
					string += ", "
				}
				if attributeCount > 2 {
					if let shortString = shortString {
						string += shortString
					} else {
						let endIdx = advance(longString.startIndex, 3)
						let aShortStr = longString[longString.startIndex..<endIdx]
						string += aShortStr
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
	
	override func attributedStringForObjectValue(obj: AnyObject, withDefaultAttributes attrs: [NSObject : AnyObject]?) -> NSAttributedString? {
		if let aStr = stringForObjectValue(obj) {
			return NSAttributedString(string: aStr, attributes: attrs)
		} else {
			return nil
		}
	}
	
	override func editingStringForObjectValue(obj: AnyObject) -> String {
		//Can't return nil :(
		return ""
	}
	
	override func getObjectValue(obj: AutoreleasingUnsafeMutablePointer<AnyObject?>, forString string: String, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>) -> Bool {
		return false
	}
	
	override func isPartialStringValid(partialString: String, newEditingString newString: AutoreleasingUnsafeMutablePointer<NSString?>, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>) -> Bool {
		return false
	}
}
