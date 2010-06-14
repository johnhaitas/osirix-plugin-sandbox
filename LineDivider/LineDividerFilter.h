//
//  LineDividerFilter.h
//  LineDivider
//
//  Copyright (c) 2010 John Haitas. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PluginFilter.h"

#define FBOX(x) [NSNumber numberWithFloat:x]

@interface LineDividerFilter : PluginFilter {
	NSArray			*tenTwentyIntervals;
	NSMutableArray	*roiSelectedArray;
	NSMutableArray	*selectedOPolyRois;
	
	NSMutableArray	*currentSpline;
	NSMutableArray	*currentInterPoints;
}

- (long) filterImage:(NSString*) menuName;
- (void) findSelectedROIs;
- (void) findLineROIs;
- (void) partitionAllOpenPolyROIs;
- (void) drawIntermediateROIs;
- (float) accumulatedIntervalAtIndex: (int)index;

@end