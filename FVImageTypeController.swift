//
//  FVImageTemplate.swift
//  ForkView
//
//  Created by Kevin Wojniak on 5/2/15.
//  Copyright (c) 2015 Kevin Wojniak. All rights reserved.
//

import Cocoa

// swiftlint:disable type_body_length
final class FVImageTypeController: FVTypeController {
    let supportedTypes: [String] = ["icns", "PICT", "PNG ", "ICON", "ICN#", "ics#",
                                    "CURS", "PAT ", "icl4", "icl8", "kcns", "ics4", "ics8",
		"GIFF"
	]

    func viewController(fromResourceData data: Data, type: String, errmsg: inout String) -> NSViewController? {
        guard let img = imageFromResource(data, type: type) else {
            return nil
        }
        let rect = NSRect(origin: .zero, size: img.size)
        let imgView = FVImageView(frame: rect)
        imgView.image = img
        imgView.autoresizingMask = [.width, .height]
        let viewController = NSViewController()
        viewController.view = imgView
        return viewController
    }

    private struct FVRGBAColor {
        // swiftlint:disable identifier_name
        var r: UInt8
        var g: UInt8
        var b: UInt8
        var a: UInt8
        // swiftlint:enable identifier_name
    }

    private struct FVRGBColor {
        // swiftlint:disable identifier_name
        var r: UInt8
        var g: UInt8
        var b: UInt8
        // swiftlint:enable identifier_name
    }

    func makeBitmap(_ size: Int) -> NSBitmapImageRep? {
        return NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: size,
            pixelsHigh: size,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: NSColorSpaceName.calibratedRGB,
            bytesPerRow: size * 4,
            bitsPerPixel: 32
        )
    }

    func imageFromBitmapData(_ data: Data, maskData: Data? = nil, size: Int) -> NSImage? {
        let ptr = (data as NSData).bytes.assumingMemoryBound(to: UInt8.self)
        //let ptr: UnsafePointer<UInt8> = UnsafePointer(data.bytes)
        guard let bitVector = CFBitVectorCreate(kCFAllocatorDefault, ptr, data.count * 8) else {
            return nil
        }

        let haveAlpha: Bool
        let maskBitVector: CFBitVector
        if let maskData = maskData {
            if data.count != maskData.count {
                print("Data and mask lengths mismatch!")
                return nil
            }
            let maskPtr = (maskData as NSData).bytes.assumingMemoryBound(to: UInt8.self)
            maskBitVector = CFBitVectorCreate(kCFAllocatorDefault, maskPtr, maskData.count * 8)
            haveAlpha = true
        } else {
            // create a dummy value since CFBitVector can't be nil
            maskBitVector = CFBitVectorCreate(kCFAllocatorDefault, ptr, data.count * 8)
            haveAlpha = false
        }

        guard let bitmap = makeBitmap(size) else {
            return nil
        }
        let numPixels = size * size
        var color: UnsafeMutablePointer<FVRGBAColor>?
        bitmap.bitmapData?.withMemoryRebound(to: FVRGBAColor.self, capacity: numPixels, { (colorPtr) in
            color = colorPtr
        })
        guard let colorPtr = color else {
            print("Failed to get rgb colors")
            return nil
        }
        for idx in 0 ..< numPixels {
            let value: UInt8 = CFBitVectorGetBitAtIndex(bitVector, idx) == 1 ? 0 : 255
            colorPtr[idx].r = value
            colorPtr[idx].g = value
            colorPtr[idx].b = value
            colorPtr[idx].a = !haveAlpha ? 255 : (CFBitVectorGetBitAtIndex(maskBitVector, idx) == 1 ? 255 : 0)
        }

        let img = NSImage()
        img.addRepresentation(bitmap)
        return img
    }

    func imageFrom4BitColorData(_ data: NSData, size: Int) -> NSImage? {
        let ptr = data.bytes.assumingMemoryBound(to: UInt8.self)

        let palette: [FVRGBColor] = [
            FVRGBColor(r: 255, g: 255, b: 255),
            FVRGBColor(r: 251, g: 242, b: 5),
            FVRGBColor(r: 255, g: 100, b: 2),
            FVRGBColor(r: 220, g: 8, b: 6),
            FVRGBColor(r: 241, g: 8, b: 132),
            FVRGBColor(r: 70, g: 0, b: 164),
            FVRGBColor(r: 0, g: 0, b: 211),
            FVRGBColor(r: 2, g: 170, b: 234),
            FVRGBColor(r: 31, g: 182, b: 20),
            FVRGBColor(r: 0, g: 100, b: 17),
            FVRGBColor(r: 85, g: 44, b: 5),
            FVRGBColor(r: 144, g: 112, b: 57),
            FVRGBColor(r: 191, g: 191, b: 191),
            FVRGBColor(r: 127, g: 127, b: 127),
            FVRGBColor(r: 63, g: 63, b: 63),
            FVRGBColor(r: 0, g: 0, b: 0)
        ]

        guard let bitmap = makeBitmap(size) else {
            return nil
        }
        let numPixels = size * size
        var color: UnsafeMutablePointer<FVRGBAColor>?
        bitmap.bitmapData?.withMemoryRebound(to: FVRGBAColor.self, capacity: numPixels, { (colorPtr) in
            color = colorPtr
        })
        guard let colorPtr = color else {
            print("Failed to get rgb colors")
            return nil
        }
        var ptrIndex = 0
        for idx in 0 ..< numPixels {
            let index: UInt8
            if idx & 1 == 0 {
                index = (ptr[ptrIndex] & 0xF0) >> 4
            } else {
                index = (ptr[ptrIndex] & 0x0F)
            }
            if idx > 0 && (idx & 1) == 1 {
                ptrIndex += 1
            }
            let rgb = palette[Int(index)]
            colorPtr[idx].r = rgb.r
            colorPtr[idx].g = rgb.g
            colorPtr[idx].b = rgb.b
            colorPtr[idx].a = 255
        }

        let img = NSImage()
        img.addRepresentation(bitmap)
        return img
    }

    // swiftlint:disable function_body_length
    func imageFrom8BitColorData(data: NSData, size: Int) -> NSImage? {
        let palette: [FVRGBColor] = [
            FVRGBColor(r: 255, g: 255, b: 255),
            FVRGBColor(r: 255, g: 255, b: 204),
            FVRGBColor(r: 255, g: 255, b: 153),
            FVRGBColor(r: 255, g: 255, b: 102),
            FVRGBColor(r: 255, g: 255, b: 51),
            FVRGBColor(r: 255, g: 255, b: 0),
            FVRGBColor(r: 255, g: 204, b: 255),
            FVRGBColor(r: 255, g: 204, b: 204),
            FVRGBColor(r: 255, g: 204, b: 153),
            FVRGBColor(r: 255, g: 204, b: 102),
            FVRGBColor(r: 255, g: 204, b: 51),
            FVRGBColor(r: 255, g: 204, b: 0),
            FVRGBColor(r: 255, g: 153, b: 255),
            FVRGBColor(r: 255, g: 153, b: 204),
            FVRGBColor(r: 255, g: 153, b: 153),
            FVRGBColor(r: 255, g: 153, b: 102),
            FVRGBColor(r: 255, g: 153, b: 51),
            FVRGBColor(r: 255, g: 153, b: 0),
            FVRGBColor(r: 255, g: 102, b: 255),
            FVRGBColor(r: 255, g: 102, b: 204),
            FVRGBColor(r: 255, g: 102, b: 153),
            FVRGBColor(r: 255, g: 102, b: 102),
            FVRGBColor(r: 255, g: 102, b: 51),
            FVRGBColor(r: 255, g: 102, b: 0),
            FVRGBColor(r: 255, g: 51, b: 255),
            FVRGBColor(r: 255, g: 51, b: 204),
            FVRGBColor(r: 255, g: 51, b: 153),
            FVRGBColor(r: 255, g: 51, b: 102),
            FVRGBColor(r: 255, g: 51, b: 51),
            FVRGBColor(r: 255, g: 51, b: 0),
            FVRGBColor(r: 255, g: 0, b: 255),
            FVRGBColor(r: 255, g: 0, b: 204),
            FVRGBColor(r: 255, g: 0, b: 153),
            FVRGBColor(r: 255, g: 0, b: 102),
            FVRGBColor(r: 255, g: 0, b: 51),
            FVRGBColor(r: 255, g: 0, b: 0),
            FVRGBColor(r: 204, g: 255, b: 255),
            FVRGBColor(r: 204, g: 255, b: 204),
            FVRGBColor(r: 204, g: 255, b: 153),
            FVRGBColor(r: 204, g: 255, b: 102),
            FVRGBColor(r: 204, g: 255, b: 51),
            FVRGBColor(r: 204, g: 255, b: 0),
            FVRGBColor(r: 204, g: 204, b: 255),
            FVRGBColor(r: 204, g: 204, b: 204),
            FVRGBColor(r: 204, g: 204, b: 153),
            FVRGBColor(r: 204, g: 204, b: 102),
            FVRGBColor(r: 204, g: 204, b: 51),
            FVRGBColor(r: 204, g: 204, b: 0),
            FVRGBColor(r: 204, g: 153, b: 255),
            FVRGBColor(r: 204, g: 153, b: 204),
            FVRGBColor(r: 204, g: 153, b: 153),
            FVRGBColor(r: 204, g: 153, b: 102),
            FVRGBColor(r: 204, g: 153, b: 51),
            FVRGBColor(r: 204, g: 153, b: 0),
            FVRGBColor(r: 204, g: 102, b: 255),
            FVRGBColor(r: 204, g: 102, b: 204),
            FVRGBColor(r: 204, g: 102, b: 153),
            FVRGBColor(r: 204, g: 102, b: 102),
            FVRGBColor(r: 204, g: 102, b: 51),
            FVRGBColor(r: 204, g: 102, b: 0),
            FVRGBColor(r: 204, g: 51, b: 255),
            FVRGBColor(r: 204, g: 51, b: 204),
            FVRGBColor(r: 204, g: 51, b: 153),
            FVRGBColor(r: 204, g: 51, b: 102),
            FVRGBColor(r: 204, g: 51, b: 51),
            FVRGBColor(r: 204, g: 51, b: 0),
            FVRGBColor(r: 204, g: 0, b: 255),
            FVRGBColor(r: 204, g: 0, b: 204),
            FVRGBColor(r: 204, g: 0, b: 153),
            FVRGBColor(r: 204, g: 0, b: 102),
            FVRGBColor(r: 204, g: 0, b: 51),
            FVRGBColor(r: 204, g: 0, b: 0),
            FVRGBColor(r: 153, g: 255, b: 255),
            FVRGBColor(r: 153, g: 255, b: 204),
            FVRGBColor(r: 153, g: 255, b: 153),
            FVRGBColor(r: 153, g: 255, b: 102),
            FVRGBColor(r: 153, g: 255, b: 51),
            FVRGBColor(r: 153, g: 255, b: 0),
            FVRGBColor(r: 153, g: 204, b: 255),
            FVRGBColor(r: 153, g: 204, b: 204),
            FVRGBColor(r: 153, g: 204, b: 153),
            FVRGBColor(r: 153, g: 204, b: 102),
            FVRGBColor(r: 153, g: 204, b: 51),
            FVRGBColor(r: 153, g: 204, b: 0),
            FVRGBColor(r: 153, g: 153, b: 255),
            FVRGBColor(r: 153, g: 153, b: 204),
            FVRGBColor(r: 153, g: 153, b: 153),
            FVRGBColor(r: 153, g: 153, b: 102),
            FVRGBColor(r: 153, g: 153, b: 51),
            FVRGBColor(r: 153, g: 153, b: 0),
            FVRGBColor(r: 153, g: 102, b: 255),
            FVRGBColor(r: 153, g: 102, b: 204),
            FVRGBColor(r: 153, g: 102, b: 153),
            FVRGBColor(r: 153, g: 102, b: 102),
            FVRGBColor(r: 153, g: 102, b: 51),
            FVRGBColor(r: 153, g: 102, b: 0),
            FVRGBColor(r: 153, g: 51, b: 255),
            FVRGBColor(r: 153, g: 51, b: 204),
            FVRGBColor(r: 153, g: 51, b: 153),
            FVRGBColor(r: 153, g: 51, b: 102),
            FVRGBColor(r: 153, g: 51, b: 51),
            FVRGBColor(r: 153, g: 51, b: 0),
            FVRGBColor(r: 153, g: 0, b: 255),
            FVRGBColor(r: 153, g: 0, b: 204),
            FVRGBColor(r: 153, g: 0, b: 153),
            FVRGBColor(r: 153, g: 0, b: 102),
            FVRGBColor(r: 153, g: 0, b: 51),
            FVRGBColor(r: 153, g: 0, b: 0),
            FVRGBColor(r: 102, g: 255, b: 255),
            FVRGBColor(r: 102, g: 255, b: 204),
            FVRGBColor(r: 102, g: 255, b: 153),
            FVRGBColor(r: 102, g: 255, b: 102),
            FVRGBColor(r: 102, g: 255, b: 51),
            FVRGBColor(r: 102, g: 255, b: 0),
            FVRGBColor(r: 102, g: 204, b: 255),
            FVRGBColor(r: 102, g: 204, b: 204),
            FVRGBColor(r: 102, g: 204, b: 153),
            FVRGBColor(r: 102, g: 204, b: 102),
            FVRGBColor(r: 102, g: 204, b: 51),
            FVRGBColor(r: 102, g: 204, b: 0),
            FVRGBColor(r: 102, g: 153, b: 255),
            FVRGBColor(r: 102, g: 153, b: 204),
            FVRGBColor(r: 102, g: 153, b: 153),
            FVRGBColor(r: 102, g: 153, b: 102),
            FVRGBColor(r: 102, g: 153, b: 51),
            FVRGBColor(r: 102, g: 153, b: 0),
            FVRGBColor(r: 102, g: 102, b: 255),
            FVRGBColor(r: 102, g: 102, b: 204),
            FVRGBColor(r: 102, g: 102, b: 153),
            FVRGBColor(r: 102, g: 102, b: 102),
            FVRGBColor(r: 102, g: 102, b: 51),
            FVRGBColor(r: 102, g: 102, b: 0),
            FVRGBColor(r: 102, g: 51, b: 255),
            FVRGBColor(r: 102, g: 51, b: 204),
            FVRGBColor(r: 102, g: 51, b: 153),
            FVRGBColor(r: 102, g: 51, b: 102),
            FVRGBColor(r: 102, g: 51, b: 51),
            FVRGBColor(r: 102, g: 51, b: 0),
            FVRGBColor(r: 102, g: 0, b: 255),
            FVRGBColor(r: 102, g: 0, b: 204),
            FVRGBColor(r: 102, g: 0, b: 153),
            FVRGBColor(r: 102, g: 0, b: 102),
            FVRGBColor(r: 102, g: 0, b: 51),
            FVRGBColor(r: 102, g: 0, b: 0),
            FVRGBColor(r: 51, g: 255, b: 255),
            FVRGBColor(r: 51, g: 255, b: 204),
            FVRGBColor(r: 51, g: 255, b: 153),
            FVRGBColor(r: 51, g: 255, b: 102),
            FVRGBColor(r: 51, g: 255, b: 51),
            FVRGBColor(r: 51, g: 255, b: 0),
            FVRGBColor(r: 51, g: 204, b: 255),
            FVRGBColor(r: 51, g: 204, b: 204),
            FVRGBColor(r: 51, g: 204, b: 153),
            FVRGBColor(r: 51, g: 204, b: 102),
            FVRGBColor(r: 51, g: 204, b: 51),
            FVRGBColor(r: 51, g: 204, b: 0),
            FVRGBColor(r: 51, g: 153, b: 255),
            FVRGBColor(r: 51, g: 153, b: 204),
            FVRGBColor(r: 51, g: 153, b: 153),
            FVRGBColor(r: 51, g: 153, b: 102),
            FVRGBColor(r: 51, g: 153, b: 51),
            FVRGBColor(r: 51, g: 153, b: 0),
            FVRGBColor(r: 51, g: 102, b: 255),
            FVRGBColor(r: 51, g: 102, b: 204),
            FVRGBColor(r: 51, g: 102, b: 153),
            FVRGBColor(r: 51, g: 102, b: 102),
            FVRGBColor(r: 51, g: 102, b: 51),
            FVRGBColor(r: 51, g: 102, b: 0),
            FVRGBColor(r: 51, g: 51, b: 255),
            FVRGBColor(r: 51, g: 51, b: 204),
            FVRGBColor(r: 51, g: 51, b: 153),
            FVRGBColor(r: 51, g: 51, b: 102),
            FVRGBColor(r: 51, g: 51, b: 51),
            FVRGBColor(r: 51, g: 51, b: 0),
            FVRGBColor(r: 51, g: 0, b: 255),
            FVRGBColor(r: 51, g: 0, b: 204),
            FVRGBColor(r: 51, g: 0, b: 153),
            FVRGBColor(r: 51, g: 0, b: 102),
            FVRGBColor(r: 51, g: 0, b: 51),
            FVRGBColor(r: 51, g: 0, b: 0),
            FVRGBColor(r: 0, g: 255, b: 255),
            FVRGBColor(r: 0, g: 255, b: 204),
            FVRGBColor(r: 0, g: 255, b: 153),
            FVRGBColor(r: 0, g: 255, b: 102),
            FVRGBColor(r: 0, g: 255, b: 51),
            FVRGBColor(r: 0, g: 255, b: 0),
            FVRGBColor(r: 0, g: 204, b: 255),
            FVRGBColor(r: 0, g: 204, b: 204),
            FVRGBColor(r: 0, g: 204, b: 153),
            FVRGBColor(r: 0, g: 204, b: 102),
            FVRGBColor(r: 0, g: 204, b: 51),
            FVRGBColor(r: 0, g: 204, b: 0),
            FVRGBColor(r: 0, g: 153, b: 255),
            FVRGBColor(r: 0, g: 153, b: 204),
            FVRGBColor(r: 0, g: 153, b: 153),
            FVRGBColor(r: 0, g: 153, b: 102),
            FVRGBColor(r: 0, g: 153, b: 51),
            FVRGBColor(r: 0, g: 153, b: 0),
            FVRGBColor(r: 0, g: 102, b: 255),
            FVRGBColor(r: 0, g: 102, b: 204),
            FVRGBColor(r: 0, g: 102, b: 153),
            FVRGBColor(r: 0, g: 102, b: 102),
            FVRGBColor(r: 0, g: 102, b: 51),
            FVRGBColor(r: 0, g: 102, b: 0),
            FVRGBColor(r: 0, g: 51, b: 255),
            FVRGBColor(r: 0, g: 51, b: 204),
            FVRGBColor(r: 0, g: 51, b: 153),
            FVRGBColor(r: 0, g: 51, b: 102),
            FVRGBColor(r: 0, g: 51, b: 51),
            FVRGBColor(r: 0, g: 51, b: 0),
            FVRGBColor(r: 0, g: 0, b: 255),
            FVRGBColor(r: 0, g: 0, b: 204),
            FVRGBColor(r: 0, g: 0, b: 153),
            FVRGBColor(r: 0, g: 0, b: 102),
            FVRGBColor(r: 0, g: 0, b: 51),
            FVRGBColor(r: 238, g: 0, b: 0),
            FVRGBColor(r: 221, g: 0, b: 0),
            FVRGBColor(r: 187, g: 0, b: 0),
            FVRGBColor(r: 170, g: 0, b: 0),
            FVRGBColor(r: 136, g: 0, b: 0),
            FVRGBColor(r: 119, g: 0, b: 0),
            FVRGBColor(r: 85, g: 0, b: 0),
            FVRGBColor(r: 68, g: 0, b: 0),
            FVRGBColor(r: 34, g: 0, b: 0),
            FVRGBColor(r: 17, g: 0, b: 0),
            FVRGBColor(r: 0, g: 238, b: 0),
            FVRGBColor(r: 0, g: 221, b: 0),
            FVRGBColor(r: 0, g: 187, b: 0),
            FVRGBColor(r: 0, g: 170, b: 0),
            FVRGBColor(r: 0, g: 136, b: 0),
            FVRGBColor(r: 0, g: 119, b: 0),
            FVRGBColor(r: 0, g: 85, b: 0),
            FVRGBColor(r: 0, g: 68, b: 0),
            FVRGBColor(r: 0, g: 34, b: 0),
            FVRGBColor(r: 0, g: 17, b: 0),
            FVRGBColor(r: 0, g: 0, b: 238),
            FVRGBColor(r: 0, g: 0, b: 221),
            FVRGBColor(r: 0, g: 0, b: 187),
            FVRGBColor(r: 0, g: 0, b: 170),
            FVRGBColor(r: 0, g: 0, b: 136),
            FVRGBColor(r: 0, g: 0, b: 119),
            FVRGBColor(r: 0, g: 0, b: 85),
            FVRGBColor(r: 0, g: 0, b: 68),
            FVRGBColor(r: 0, g: 0, b: 34),
            FVRGBColor(r: 0, g: 0, b: 17),
            FVRGBColor(r: 238, g: 238, b: 238),
            FVRGBColor(r: 221, g: 221, b: 221),
            FVRGBColor(r: 187, g: 187, b: 187),
            FVRGBColor(r: 170, g: 170, b: 170),
            FVRGBColor(r: 136, g: 136, b: 136),
            FVRGBColor(r: 119, g: 119, b: 119),
            FVRGBColor(r: 85, g: 85, b: 85),
            FVRGBColor(r: 68, g: 68, b: 68),
            FVRGBColor(r: 34, g: 34, b: 34),
            FVRGBColor(r: 17, g: 17, b: 17),
            FVRGBColor(r: 0, g: 0, b: 0)
        ]

        guard let bitmap = makeBitmap(size) else {
            return nil
        }
        let numPixels = size * size
        var color: UnsafeMutablePointer<FVRGBAColor>?
        bitmap.bitmapData?.withMemoryRebound(to: FVRGBAColor.self, capacity: numPixels, { (colorPtr) in
            color = colorPtr
        })
        guard let colorPtr = color else {
            print("Failed to get rgb colors")
            return nil
        }
        let ptr = data.bytes.assumingMemoryBound(to: UInt8.self)
        for idx in 0 ..< numPixels {
            let rgb = palette[Int(ptr[idx])]
            colorPtr[idx].r = rgb.r
            colorPtr[idx].g = rgb.g
            colorPtr[idx].b = rgb.b
            colorPtr[idx].a = 255
        }

        let img = NSImage()
        img.addRepresentation(bitmap)
        return img
    }
    // swiftlint:enable function_body_length

    func imageFromResource(_ rsrcData: Data, type: String) -> NSImage? {
        switch type {
        case "icns", "PNG ", "kcns", "GIFF", "PICT":
            return NSImage(data: rsrcData)
        case "ICON":
            if rsrcData.count == 128 {
                return imageFromBitmapData(rsrcData, size: 32)
            }
        case "ICN#":
            if rsrcData.count == 256 {
                let data = rsrcData[(rsrcData.startIndex+0)..<(rsrcData.startIndex.advanced(by: 128))]
                let mask = rsrcData[(rsrcData.startIndex.advanced(by: 128))..<(rsrcData.startIndex.advanced(by: 256))]
                return imageFromBitmapData(data, maskData: mask, size: 32)
            }
        case "ics#":
            if rsrcData.count == 64 {
                return imageFromBitmapData(rsrcData, size: 16)
            }
        case "CURS":
            if rsrcData.count == 68 {
                let data = rsrcData[(rsrcData.startIndex+0)..<rsrcData.startIndex.advanced(by: 32)]
                let mask = rsrcData[rsrcData.startIndex.advanced(by: 32)..<rsrcData.startIndex.advanced(by: 64)]
                return imageFromBitmapData(data, maskData: mask, size: 16)
            }
        case "PAT ":
            if rsrcData.count == 8 {
                return imageFromBitmapData(rsrcData, size: 8)
            }
        case "icl4":
            if rsrcData.count == 512 {
                return imageFrom4BitColorData(rsrcData as NSData, size: 32)
            }
        case "icl8":
            if rsrcData.count == 1024 {
                return imageFrom8BitColorData(data: rsrcData as NSData, size: 32)
            }
        case "ics4":
            if rsrcData.count == 128 {
                return imageFrom4BitColorData(rsrcData as NSData, size: 16)
            }
        case "ics8":
            if rsrcData.count == 256 {
                return imageFrom8BitColorData(data: rsrcData as NSData, size: 16)
            }
        default:
            return nil
        }
        return nil
    }
}
// swiftlint:enable type_body_length

final class FVImageView: NSImageView {
    override var acceptsFirstResponder: Bool {
        return true
    }

    override var needsPanelToBecomeKey: Bool {
        return true
    }
}
