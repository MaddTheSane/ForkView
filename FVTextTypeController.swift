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
    
    func viewControllerFromResourceData(_ data: Data, type: String, errmsg: inout String) -> NSViewController? {
        guard let str = attributedStringFromResource(data, type: type) else {
            return nil
        }
        guard let viewController = NSViewController(nibName: "TextView", bundle: nil) else {
            return nil
        }
        let scrollView = viewController.view as! NSScrollView
        let textView = scrollView.documentView as! NSTextView
        textView.textStorage?.setAttributedString(str)
        return viewController
    }
    
    func attributedStringFromResource(_ rsrcData: Data, type: String) -> AttributedString? {
        switch type {
        case "RTF ":
            return AttributedString(rtf: rsrcData, documentAttributes: nil)
        case "rtfd":
            return AttributedString(rtfd: rsrcData, documentAttributes: nil)
        default:
            if let str = stringFromResource(rsrcData, type: type) {
                return AttributedString(string: str)
            }
            break;
        }
        return nil
    }
    
    func stringFromResource(_ rsrcData: Data, type: String) -> String? {
        switch type {
        case "plst", "weba":
            let plist: AnyObject? = try? PropertyListSerialization.propertyList(from: rsrcData, options: PropertyListSerialization.ReadOptions(rawValue: PropertyListSerialization.MutabilityOptions().rawValue), format: nil)
            if plist != nil {
                if let data = try? PropertyListSerialization.data(fromPropertyList: plist!, format: .xml, options: PropertyListSerialization.WriteOptions(0)) {
                    return NSString(data: data, encoding: String.Encoding.utf8.rawValue) as? String
                }
            }
        case "TEXT":
            return NSString(data: rsrcData, encoding: String.Encoding.macOSRoman.rawValue) as? String
        case "utf8":
            return NSString(data: rsrcData, encoding: String.Encoding.utf8.rawValue) as? String
        case "utxt":
            return NSString(data: rsrcData, encoding: String.Encoding.utf16BigEndian.rawValue) as? String
        case "ut16":
            return NSString(data: rsrcData, encoding: String.Encoding.unicode.rawValue) as? String
        case "STR ":
            return stringFromPascalStringData(rsrcData)
        default:
            break;
        }
        return nil
    }
    
    func stringFromPascalStringData(_ data: Data) -> String? {
        if data.count < 2 {
            return nil
        }
        let ptr = UnsafePointer<UInt8>((data as NSData).bytes)
        let strLen = Int(ptr[0])
        if data.count < (strLen + 1) {
            return nil
        }
        return NSString(bytes: ptr + 1, length: strLen, encoding: String.Encoding.macOSRoman.rawValue) as? String
    }
}
