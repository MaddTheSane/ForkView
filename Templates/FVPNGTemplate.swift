//
//  FVPNGTemplate.swift
//  ForkView
//
//  Created by C.W. Betts on 4/21/15.
//  Copyright (c) 2015 Kevin Wojniak. All rights reserved.
//

import Cocoa
import SwiftAdditions

private final class FVImageView: NSImageView {
	override var acceptsFirstResponder: Bool {
		return true
	}
	
	override var needsPanelToBecomeKey: Bool {
		return true
	}
}

private struct FVRGBColor {
	var r: UInt8
	var g: UInt8
	var b: UInt8
	var a: UInt8
}

private final class FVColorView: NSView {
	var color: NSColor?
	
	private override func drawRect(dirtyRect: NSRect) {
		if let color = color {
			color.set()
			NSBezierPath.fillRect(dirtyRect)
		}
	}
}

final class FVPNGTemplate: NSViewController, FVTemplate {

	class func handledResourceTypes() -> Set<NSObject> {
		return [NSNumber(unsignedInt: "icns"), NSNumber(unsignedInt: "PICT"), NSNumber(unsignedInt: "PNG "), NSNumber(unsignedInt: "ICON"), NSNumber(unsignedInt: "ICN#"), NSNumber(unsignedInt: "ics#")]
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
	
	class func imageFromResource(resource: FVResource) -> NSImage? {
		if let rsrcData = resource.data {
			switch resource.type!.type {
			case "icns", "PICT", "PNG ":
				return NSImage(data: rsrcData)
				
			case "ICON":
				if rsrcData.length == 128 {
					let width = 32
					let height = 32
					let bitVector = CFBitVectorCreate(kCFAllocatorDefault, UnsafePointer<UInt8>(rsrcData.bytes), rsrcData.length * 8)
					if let bmp = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: NSCalibratedRGBColorSpace, bytesPerRow: width * 4, bitsPerPixel: 32) {
						var color = UnsafeMutablePointer<FVRGBColor>(bmp.bitmapData)
						let numPixels = width * height
						for var i = 0; i < numPixels; ++i, ++color {
							if (CFBitVectorGetBitAtIndex(bitVector, i) != 0) {
								color.memory.r = 0
								color.memory.g = 0
								color.memory.b = 0;
							} else {
								color.memory.r = 255
								color.memory.g = 255
								color.memory.b = 255
							}
							color.memory.a = 255;
						}
						let img = NSImage()
						img.addRepresentation(bmp)
						return img
					}
				}
				
			case "ICN#":
				if rsrcData.length == 256 {
					let width = 32
					let height = 32
					let bitVector = CFBitVectorCreate(kCFAllocatorDefault, UnsafePointer<UInt8>(rsrcData.bytes), rsrcData.length * 8)
					if let bmp = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: NSCalibratedRGBColorSpace, bytesPerRow: width * 4, bitsPerPixel: 32) {
						var color = UnsafeMutablePointer<FVRGBColor>(bmp.bitmapData)
						let numPixels = width * height
						for var i = 0; i < numPixels; ++i, ++color {
							if (CFBitVectorGetBitAtIndex(bitVector, i) != 0) {
								color.memory.r = 0
								color.memory.g = 0
								color.memory.b = 0;
							} else {
								color.memory.r = 255
								color.memory.g = 255
								color.memory.b = 255
							}
							if (CFBitVectorGetBitAtIndex(bitVector, i + numPixels) != 0) {
								color.memory.a = 255;
							} else {
								color.memory.a = 0;
							}
						}
						let img = NSImage()
						img.addRepresentation(bmp)
						return img
					}
				}
				
			case "ics#":
				if rsrcData.length == 64 {
					let width = 16
					let height = 16
					let bitVector = CFBitVectorCreate(kCFAllocatorDefault, UnsafePointer<UInt8>(rsrcData.bytes), rsrcData.length * 8)
					if let bmp = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: NSCalibratedRGBColorSpace, bytesPerRow: width * 4, bitsPerPixel: 32) {
						var color = UnsafeMutablePointer<FVRGBColor>(bmp.bitmapData)
						let numPixels = width * height
						for var i = 0; i < numPixels; ++i, ++color {
							if (CFBitVectorGetBitAtIndex(bitVector, i) != 0) {
								color.memory.r = 0
								color.memory.g = 0
								color.memory.b = 0;
							} else {
								color.memory.r = 255
								color.memory.g = 255
								color.memory.b = 255
							}
							color.memory.a = 255;
						}
						let img = NSImage()
						img.addRepresentation(bmp)
						return img
					}
				}

				
			default:
				break
			}
		}
		return nil
	}
	
	init?(resource: FVResource) {
		if let img = FVPNGTemplate.imageFromResource(resource) {
			var rect = NSRect(origin: NSPoint.zeroPoint, size: img.size)
			let colorView = FVColorView(frame:rect)
			let imgView = FVImageView(frame: colorView.bounds)
			imgView.image = img
			imgView.autoresizingMask = .ViewWidthSizable | .ViewHeightSizable
			colorView.addSubview(imgView)
			
			super.init(nibName: nil, bundle: nil)
			self.view = colorView
		} else {
			super.init(nibName: nil, bundle: nil)
			return nil
		}
	}

	required init?(coder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}
}
