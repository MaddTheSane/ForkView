//
//  FVTextTypeController.swift
//  ForkView
//
//  Created by Kevin Wojniak on 5/9/15.
//  Copyright (c) 2015 Kevin Wojniak. All rights reserved.
//

import Cocoa

final class FVTextTypeController: FVTypeController {
    let supportedTypes = ["plst", "TEXT", "utf8", "utxt", "ut16", "weba", "RTF ", "rtfd", "STR "]
    
    func viewControllerFromResourceData(data: NSData, type: String, inout errmsg: String) -> NSViewController? {
        let str = attributedStringFromResource(data, type: type)
        if str == nil {
            return nil
        }
        let viewController = NSViewController(nibName: "TextView", bundle: nil)
        if viewController == nil {
            return nil
        }
        let scrollView = viewController!.view as! NSScrollView
        let textView = scrollView.documentView as! NSTextView
        textView.textStorage?.setAttributedString(str)
        return viewController
    }
    
    func attributedStringFromResource(rsrcData: NSData, type: String) -> NSAttributedString? {
        switch type {
        case "RTF ":
            return NSAttributedString(RTF: rsrcData, documentAttributes: nil)
        case "rtfd":
            return NSAttributedString(RTFD: rsrcData, documentAttributes: nil)
        default:
            if let str = stringFromResource(rsrcData, type: type) {
                return NSAttributedString(string: str)
            }
            break;
        }
        return nil
    }
    
    func stringFromResource(rsrcData: NSData, type: String) -> String? {
        switch type {
        case "plst", "weba":
            let plist: AnyObject? = try? NSPropertyListSerialization.propertyListWithData(rsrcData, options: NSPropertyListReadOptions(rawValue: NSPropertyListMutabilityOptions.Immutable.rawValue), format: nil)
            if plist != nil {
                if let data = try? NSPropertyListSerialization.dataWithPropertyList(plist!, format: .XMLFormat_v1_0, options: NSPropertyListWriteOptions(0)) {
                    return NSString(data: data, encoding: NSUTF8StringEncoding) as? String
                }
            }
        case "TEXT":
            return NSString(data: rsrcData, encoding: NSMacOSRomanStringEncoding) as? String
        case "utf8":
            return NSString(data: rsrcData, encoding: NSUTF8StringEncoding) as? String
        case "utxt":
            return NSString(data: rsrcData, encoding: NSUTF16BigEndianStringEncoding) as? String
        case "ut16":
            return NSString(data: rsrcData, encoding: NSUnicodeStringEncoding) as? String
        case "STR ":
            return stringFromPascalStringData(rsrcData)
        default:
            break;
        }
        return nil
    }
    
    func stringFromPascalStringData(data: NSData) -> String? {
        if data.length < 2 {
            return nil
        }
        let ptr = UnsafePointer<UInt8>(data.bytes)
        let strLen = Int(ptr[0])
        if data.length < (strLen + 1) {
            return nil
        }
        return NSString(bytes: ptr + 1, length: strLen, encoding: NSMacOSRomanStringEncoding) as? String
    }
}
