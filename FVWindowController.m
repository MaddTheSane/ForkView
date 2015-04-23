//
//  FVWindowController.m
//  ForkView
//
//  Created by Kevin Wojniak on 8/16/11.
//  Copyright 2011 Kevin Wojniak. All rights reserved.
//

#import "FVWindowController.h"
#import "FVResourceFile.h"
#import "ForkView-Swift.h"

@implementation FVWindowController {
	NSArray *templateClasses;
}

- (id)init
{
    if ((self = [super initWithWindowNibName:@"FVWindow"]) != nil) {
        windowControllers = [[NSMutableArray alloc] init];
		templateClasses = @[[FVPNGTemplate class], [StringListTemplate class]];
    }
	return self;
}

- (Class)templateClassForResource:(FVResource *)resource
{
	for (Class aClass in templateClasses) {
		for (NSNumber *aResID in [aClass handledResourceTypes]) {
			if (aResID.unsignedIntegerValue == resource.type.type) {
				return aClass;
			}
		}
	}
	
	return nil;
}

- (void)viewResource:(FVResource *)resource
{
	Class class = [self templateClassForResource:resource];
	if (!class) {
		NSBeep();
		return;
	}
	
	id <FVTemplate> controller = [[class alloc] initWithResource:resource];
	if (!controller) {
		NSBeep();
		return;
	}
	
	NSView *view = [controller view];
	
	NSSize minSize = NSMakeSize(250.0, 150.0);
	NSRect winFrame = [view frame];
	if (NSWidth(winFrame) < minSize.width) {
		winFrame.size.width = minSize.width;
	}
	if (NSHeight(winFrame) < minSize.height) {
		winFrame.size.height = minSize.height;
	}
	
	NSWindow *parentWin = [self window];
	NSRect parentWinFrame = [parentWin frameRectForContentRect:[[parentWin contentView] frame]];
	parentWinFrame.origin = [parentWin frame].origin;
	//winFrame.origin.x = NSMinX(parentWinFrame) + 15;
	//winFrame.origin.y = NSMinY(parentWinFrame);// - 15 - NSHeight(winFrame);
	
    NSUInteger styleMask = NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask;
	NSWindow *window = [[NSWindow alloc] initWithContentRect:winFrame styleMask:styleMask backing:NSBackingStoreBuffered defer:YES];
    [window setReleasedWhenClosed:YES];
	[window setContentView:[controller view]];
	[window setMinSize:minSize];
	
	NSPoint newPoint = [window cascadeTopLeftFromPoint:NSMakePoint(NSMinX(parentWinFrame), NSMaxY(parentWinFrame))];
	[window cascadeTopLeftFromPoint:newPoint];
	
	NSWindowController *windowController = [[NSWindowController alloc] initWithWindow:window];
	[windowController showWindow:nil];
	[windowControllers addObject:windowController];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowWillClose:) name:NSWindowWillCloseNotification object:window];
	
	[window setTitle:[NSString stringWithFormat:@"%@ ID = %u from %@", resource.type.typeString, resource.ident, [[[self document] fileURL] lastPathComponent]]];
}

- (void)windowWillClose:(NSNotification *)notif
{
	NSWindow *window = [notif object];
	NSWindowController *windowController = [window windowController];
	[windowControllers removeObject:windowController];
}

- (FVResource*)selectedResource
{
    return [[resourcesArrayController selectedObjects] lastObject];
}

- (void)openSelectedResource
{
	[self viewResource:[self selectedResource]];
}

- (void)close
{
	for (NSWindowController *windowController in windowControllers) {
		[windowController close];
	}
	[super close];
}

- (NSMenu *)tableViewMenuForSelection
{
	NSMenu *menu = [[NSMenu alloc] init];
	[[menu addItemWithTitle:@"Export\u2026" action:@selector(writeSelectedResource) keyEquivalent:@""] setTarget:self];
	return menu;
}

- (void)writeSelectedResource
{
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton) {
            [[[self selectedResource] data] writeToURL:[savePanel URL] atomically:YES];
        }
    }];
}

- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName
{
	FVDocument *doc = [self document];
	return [NSString stringWithFormat:@"%@ [%@]", displayName, doc.resourceFile.forkType == FVForkTypeData ? @"Data Fork" : @"Resource Fork"];
}

@end
