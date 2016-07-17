//
//  FVImageTemplate.swift
//  ForkView
//
//  Created by Kevin Wojniak on 5/2/15.
//  Copyright (c) 2015 Kevin Wojniak. All rights reserved.
//

import Cocoa

final class FVImageTypeController: FVTypeController {
    let supportedTypes = ["icns", "PICT", "PNG ", "ICON", "ICN#", "ics#", "CURS", "PAT ", "icl4", "icl8", "kcns", "ics4", "ics8",
		"GIFF"
	]
    
    func viewControllerFromResourceData(data: NSData, type: String, inout errmsg: String) -> NSViewController? {
        if type == "PICT" {
            //First, see if we can get the image size via NSImage
            let tmpCocoaImg = NSImage(data: data)
            let imgSize = tmpCocoaImg?.size ?? NSSize(width: 32, height: 32)
            
            let connectionToService = NSXPCConnection(serviceName: "com.kainjow.PICTConverter")
            connectionToService.remoteObjectInterface = NSXPCInterface(withProtocol: PICTConverterProtocol.self)
            connectionToService.resume()
            
            let rect = NSRect(origin: .zero, size: imgSize)
            let imgView = FVImageView(frame: rect)
            // TODO: temporary image showing we're fetching the image.
            imgView.autoresizingMask = [.ViewWidthSizable, .ViewHeightSizable]
            let viewController = NSViewController()
            viewController.view = imgView

            connectionToService.remoteObjectProxyWithErrorHandler({ (err) -> Void in
                //TODO: image or some other way of showing failure.
                NSLog("Error encountered when trying to speak with XPC service: %@", err)
            }).convertPICTDataToTIFF(data, withReply: { (replyData) -> Void in
                NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                    if let replyData = replyData {
                        imgView.image = NSImage(data: replyData)!
                    } else if let cocoaImg = tmpCocoaImg {
                        imgView.image = cocoaImg
                    } else {
                        //TODO: image or some other way of showing failure.
                    }
                    connectionToService.invalidate()
                })
            })
            return viewController
        }
        guard let img = imageFromResource(data, type: type) else {
            return nil
        }
        
        let rect = NSRect(origin: .zero, size: img.size)
        let imgView = FVImageView(frame: rect)
        imgView.image = img
        imgView.autoresizingMask = [.ViewWidthSizable, .ViewHeightSizable]
        let viewController = NSViewController()
        viewController.view = imgView
        return viewController
    }
    
    private struct FVRGBAColor {
        var r: UInt8
        var g: UInt8
        var b: UInt8
        var a: UInt8
    }

    private struct FVRGBColor {
        var r: UInt8
        var g: UInt8
        var b: UInt8
    }
    
    func makeBitmap(size: Int) -> NSBitmapImageRep? {
        return NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: size,
            pixelsHigh: size,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: NSCalibratedRGBColorSpace,
            bytesPerRow: size * 4,
            bitsPerPixel: 32
        )
    }

    func imageFromBitmapData(data: NSData, maskData: NSData? = nil, size: Int) -> NSImage? {
        let ptr: UnsafePointer<UInt8> = UnsafePointer(data.bytes)
        guard let bitVector = CFBitVectorCreate(kCFAllocatorDefault, ptr, data.length * 8) else {
            return nil
        }
        
        let haveAlpha  = maskData != nil
        var maskBitVector: CFBitVectorRef
        if haveAlpha {
            if data.length != maskData!.length {
                print("Data and mask lengths mismatch!")
                return nil
            }
            let maskPtr: UnsafePointer<UInt8> = UnsafePointer(maskData!.bytes)
            maskBitVector = CFBitVectorCreate(kCFAllocatorDefault, maskPtr, maskData!.length * 8)
        } else {
            // create a dummy value since CFBitVector can't be nil
            maskBitVector = CFBitVectorCreate(kCFAllocatorDefault, ptr, data.length * 8)
        }
        
        guard let bitmap = makeBitmap(size) else {
            return nil
        }
        let color = UnsafeMutablePointer<FVRGBAColor>(bitmap.bitmapData)
        let numPixels = size * size
        for i in 0 ..< numPixels {
            let value: UInt8 = CFBitVectorGetBitAtIndex(bitVector, i) == 1 ? 0 : 255
            color[i].r = value
            color[i].g = value
            color[i].b = value
            color[i].a = !haveAlpha ? 255 : (CFBitVectorGetBitAtIndex(maskBitVector, i) == 1 ? 255 : 0)
        }
        
        let img = NSImage()
        img.addRepresentation(bitmap)
        return img
    }
    
    func imageFrom4BitColorData(data: NSData, size: Int) -> NSImage? {
        let ptr: UnsafePointer<UInt8> = UnsafePointer(data.bytes)
        
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
            FVRGBColor(r: 0, g: 0, b: 0),
        ]
        
        guard bitmap = makeBitmap(size) else {
            return nil
        }
        let color = UnsafeMutablePointer<FVRGBAColor>(bitmap.bitmapData)
        let numPixels = size * size
        var ptrIndex = 0
        for i in 0 ..< numPixels {
            let index: UInt8
            if i & 1 == 0 {
                index = (ptr[ptrIndex] & 0xF0) >> 4
            } else {
                index = (ptr[ptrIndex] & 0x0F)
            }
            if i > 0 && (i & 1) == 1 {
                ptrIndex += 1
            }
            let rgb = palette[Int(index)]
            color[i].r = rgb.r
            color[i].g = rgb.g
            color[i].b = rgb.b
            color[i].a = 255
        }
        
        let img = NSImage()
        img.addRepresentation(bitmap)
        return img
    }

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
            FVRGBColor(r: 0, g: 0, b: 0),
        ]
        
        guard let bitmap = makeBitmap(size) else {
            return nil
        }
        let color = UnsafeMutablePointer<FVRGBAColor>(bitmap.bitmapData)
        let numPixels = size * size
        let ptr: UnsafePointer<UInt8> = UnsafePointer(data.bytes)
        for i in 0 ..< numPixels {
            let rgb = palette[Int(ptr[i])]
            color[i].r = rgb.r
            color[i].g = rgb.g
            color[i].b = rgb.b
            color[i].a = 255
        }
        
        let img = NSImage()
        img.addRepresentation(bitmap)
        return img
    }
    
    func imageFromResource(rsrcData: NSData, type: String) -> NSImage? {
        switch type {
        case "icns", "PNG ", "kcns", "GIFF":
            return NSImage(data: rsrcData)
        case "ICON":
            if rsrcData.length == 128 {
                return imageFromBitmapData(rsrcData, size: 32)
            }
        case "ICN#":
            if rsrcData.length == 256 {
                let data = rsrcData.subdataWithRange(NSMakeRange(0, 128))
                let mask = rsrcData.subdataWithRange(NSMakeRange(128, 128))
                return imageFromBitmapData(data, maskData: mask, size: 32)
            }
        case "ics#":
            if rsrcData.length == 64 {
                return imageFromBitmapData(rsrcData, size: 16)
            }
        case "CURS":
            if rsrcData.length == 68 {
                let data = rsrcData.subdataWithRange(NSMakeRange(0, 32))
                let mask = rsrcData.subdataWithRange(NSMakeRange(32, 32))
                return imageFromBitmapData(data, maskData: mask, size: 16)
            }
        case "PAT ":
            if rsrcData.length == 8 {
                return imageFromBitmapData(rsrcData, size: 8)
            }
        case "icl4":
            if rsrcData.length == 512 {
                return imageFrom4BitColorData(rsrcData, size: 32)
            }
        case "icl8":
            if rsrcData.length == 1024 {
                return imageFrom8BitColorData(rsrcData, size: 32)
            }
        case "ics4":
            if rsrcData.length == 128 {
                return imageFrom4BitColorData(rsrcData, size: 16)
            }
        case "ics8":
            if rsrcData.length == 256 {
                return imageFrom8BitColorData(rsrcData, size: 16)
            }
        default:
            return nil
        }
        return nil
    }
}

final class FVImageView: NSImageView {
    override var acceptsFirstResponder: Bool {
        get {
            return true
        }
    }

    override var needsPanelToBecomeKey: Bool {
        get {
            return true
        }
    }
}
