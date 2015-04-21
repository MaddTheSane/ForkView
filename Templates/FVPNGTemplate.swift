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

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
	
	//+ (NSImage*)imageFromResource:(FVResource*)resource
	class func imageFromResource(resource: FVResource) -> NSImage? {
		/*
		{
		NSData *rsrcData = [resource data];
		switch (resource.type.type) {
		case 'icns':
		case 'PICT':
		case 'PNG ':
		return [[NSImage alloc] initWithData:rsrcData];
		case 'ICON':
		{
		if ([rsrcData length] == 128) {
		int width = 32, height = 32;
		CFBitVectorRef bitVector = CFBitVectorCreate(kCFAllocatorDefault, (const UInt8*)[rsrcData bytes], [rsrcData length]*8);
		NSBitmapImageRep *bmp = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
		pixelsWide:width
		pixelsHigh:height
		bitsPerSample:8
		samplesPerPixel:4
		hasAlpha:YES
		isPlanar:NO
		colorSpaceName:NSCalibratedRGBColorSpace
		bytesPerRow:width*4
		bitsPerPixel:32];
		struct FVRGBColor *color = (struct FVRGBColor*)[bmp bitmapData];
		const unsigned numPixels = width * height;
		for (int i = 0; i < numPixels; ++i, ++color) {
		if (CFBitVectorGetBitAtIndex(bitVector, i)) {
		color->r = color->g = color->b = 0;
		} else {
		color->r = color->g = color->b = 255;
		}
		color->a = 255;
		}
		CFRelease(bitVector);
		NSImage *img = [[NSImage alloc] init];
		[img addRepresentation:bmp];
		return img;
		}
		break;
		}
		case 'ICN#':
		{
		if ([rsrcData length] == 256) {
		int width = 32, height = 32;
		CFBitVectorRef bitVector = CFBitVectorCreate(kCFAllocatorDefault, (const UInt8*)[rsrcData bytes], [rsrcData length]*8);
		NSBitmapImageRep *bmp = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
		pixelsWide:width
		pixelsHigh:height
		bitsPerSample:8
		samplesPerPixel:4
		hasAlpha:YES
		isPlanar:NO
		colorSpaceName:NSCalibratedRGBColorSpace
		bytesPerRow:width*4
		bitsPerPixel:32];
		struct FVRGBColor *color = (struct FVRGBColor*)[bmp bitmapData];
		const unsigned numPixels = width * height;
		for (int i = 0; i < numPixels; ++i, ++color) {
		if (CFBitVectorGetBitAtIndex(bitVector, i)) {
		color->r = color->g = color->b = 0;
		} else {
		color->r = color->g = color->b = 255;
		}
		if (CFBitVectorGetBitAtIndex(bitVector, i + numPixels)) {
		color->a = 255;
		} else {
		color->a = 0;
		}
		}
		CFRelease(bitVector);
		NSImage *img = [[NSImage alloc] init];
		[img addRepresentation:bmp];
		return img;
		}
		break;
		}
		case 'ics#':
		{
		if ([rsrcData length] == 64) {
		int width = 16, height = 16;
		CFBitVectorRef bitVector = CFBitVectorCreate(kCFAllocatorDefault, (const UInt8*)[rsrcData bytes], [rsrcData length]*8);
		NSBitmapImageRep *bmp = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
		pixelsWide:width
		pixelsHigh:height
		bitsPerSample:8
		samplesPerPixel:4
		hasAlpha:YES
		isPlanar:NO
		colorSpaceName:NSCalibratedRGBColorSpace
		bytesPerRow:width*4
		bitsPerPixel:32];
		struct FVRGBColor *color = (struct FVRGBColor*)[bmp bitmapData];
		const unsigned numPixels = width * height;
		for (int i = 0; i < numPixels; ++i, ++color) {
		if (CFBitVectorGetBitAtIndex(bitVector, i)) {
		color->r = color->g = color->b = 0;
		} else {
		color->r = color->g = color->b = 255;
		}
		color->a = 255;
		}
		CFRelease(bitVector);
		NSImage *img = [[NSImage alloc] init];
		[img addRepresentation:bmp];
		return img;
		}
		break;
		}
		}
		return nil;
		}
*/
		return nil
	}
	
	init!(resource: FVResource!) {
		
		//- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}
}
