//
//  FVResourceFile.h
//  ForkView
//
//  Created by Kevin Wojniak on 5/25/11.
//  Copyright 2011 Kevin Wojniak. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FVFork.h"

typedef NS_OPTIONS(SInt16, FVResAttributes) {
	///System or application heap?
	FVResSysHeap	= 64,
	
	///Purgeable resource?
	FVResPurgeable	= 32,
	
	///Load it in locked?
	FVResLocked		= 16,
	
	///Protected?
	FVResProtected	= 8,
	
	///Load in on OpenResFile?
	FVResPreload	= 4,
	
	///Resource changed?
	FVResChanged	= 2
};


typedef struct FVResourceHeader FVResourceHeader;
typedef struct FVResourceMap FVResourceMap;

@interface FVResourceFile : NSObject
{
	FVFork *fork;
	FVResourceHeader *header;
	FVResourceMap *map;
	NSArray *types;
}

- (nullable instancetype)initWithContentsOfURL:(nonnull NSURL *)fileURL error:(NSError * __nullable * __nullable)error;
+ (nullable instancetype)resourceFileWithContentsOfURL:(nonnull NSURL *)fileURL error:(NSError * __nullable * __nullable)error;

@property (readonly, nonnull) NSArray *types;

@property (readonly) FVForkType forkType;

@end
