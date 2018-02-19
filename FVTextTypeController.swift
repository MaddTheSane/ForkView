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
    
    func viewController(fromResourceData data: Data, type: String, errmsg: inout String) -> NSViewController? {
        guard let str = attributedStringFromResource(data, type: type) else {
            return nil
        }
        let viewController = NSViewController(nibName: NSNib.Name(rawValue: "TextView"), bundle: nil)
        let scrollView = viewController.view as! NSScrollView
        let textView = scrollView.documentView as! NSTextView
        textView.textStorage?.setAttributedString(str)
        return viewController
    }
    
    func attributedStringFromResource(_ rsrcData: Data, type: String) -> NSAttributedString? {
        switch type {
        case "RTF ":
            return NSAttributedString(rtf: rsrcData, documentAttributes: nil)
        case "rtfd":
            return NSAttributedString(rtfd: rsrcData, documentAttributes: nil)
        default:
            if let str = stringFromResource(rsrcData, type: type) {
                return NSAttributedString(string: str)
            }
            break;
        }
        return nil
    }
    
    func stringFromResource(_ rsrcData: Data, type: String) -> String? {
        switch type {
        case "plst", "weba":
            if let plist = try? PropertyListSerialization.propertyList(from: rsrcData, options: [], format: nil),
                let data = try? PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: PropertyListSerialization.WriteOptions(0)) {
                return String(data: data, encoding: .utf8)
                
            }
        case "TEXT":
            return String(data: rsrcData, encoding: .macOSRoman)
        case "utf8":
            return String(data: rsrcData, encoding: .utf8)
        case "utxt":
            return String(data: rsrcData, encoding: .utf16BigEndian)
        case "ut16":
            return String(data: rsrcData, encoding: .unicode)
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
        var dat2 = data
        let strLen = Int(dat2.popFirst()!)
        if data.count < (strLen + 1) {
            return nil
        }
        
        if strLen != dat2.count {
            let startIdx = dat2.startIndex.advanced(by: strLen)
            let endIdx = dat2.endIndex
            dat2.removeSubrange(startIdx ..< endIdx)
        }
        return String(data: dat2, encoding: .macOSRoman)
    }
}
