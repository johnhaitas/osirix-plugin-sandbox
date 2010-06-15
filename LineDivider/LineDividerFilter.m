//
//  LineDividerFilter.m
//  LineDivider
//
//  Copyright (c) 2010 John Haitas. All rights reserved.
//

#import "LineDividerFilter.h"

@implementation LineDividerFilter

- (void) initPlugin
{
	tenTwentyIntervals	= [[NSArray alloc] initWithObjects:
										FBOX(.1),FBOX(.2),FBOX(.2),
						   FBOX(.2),FBOX(.2),FBOX(.1),nil];
	roiSelectedArray	= [[NSMutableArray alloc] initWithCapacity:0];
	selectedOPolyRois	= [[NSMutableArray alloc] initWithCapacity:0];
	
	
	currentSpline		= [[NSMutableArray alloc] initWithCapacity:0];
	currentInterPoints	= [[NSMutableArray alloc] initWithCapacity:0];
}

- (long) filterImage:(NSString*) menuName
{
		
	[self findSelectedROIs];	
	[self findLineROIs];
	
	// if there are no selected Open Polygons...
	// ... return with error
	if ([selectedOPolyRois count] == 0) {
		return -1;
	}
	
	// Now we know we have selected ROIs ...
	//... some of those are Open Polygon ROIs
	
	[self partitionAllOpenPolyROIs];
	
	NSLog(@"Executed to completion!\n");
	return 0; // No Errors
}

- (void) findSelectedROIs
{
	int				i;
	BOOL			roiSelected			= NO;
	NSMutableArray	*curRoiList			= [[viewerController imageView] curRoiList];
	
	// clear existing array of selected objects
	[roiSelectedArray removeAllObjects];
	
	// iterate through each ROI
	for (i = 0; i < [curRoiList count]; i++) {
		// check if this ROI is selected 
		if( [[curRoiList objectAtIndex:i] ROImode] == ROI_selected) {
			// note that there are selected ROIs
			roiSelected = YES;
			
			// add this selected ROI to the array of selected ROIs
			[roiSelectedArray addObject: [curRoiList objectAtIndex:i]];
		}
	}	
	
	// notify user if there are no selected ROI
	if (!roiSelected) {
		// alert the user there are no selected ROIs
		NSRunAlertPanel(NSLocalizedString(@"Plugins Error", nil),
						NSLocalizedString(@"No selected ROIs!", nil), 
						nil, nil, nil);
	}
}

- (void) findLineROIs
{
	int				i;
	BOOL			selectedLines		= NO;
	
	// clear existing array of selected Open Polygon objects
	[selectedOPolyRois removeAllObjects];
	
	// iterate through each selected ROI
	for (i = 0; i < [roiSelectedArray count]; i++) {
		// check if this ROI is an Open Polygon
		ROI *thisROI = [roiSelectedArray objectAtIndex:i];
		if (thisROI.type == tOPolygon) {
			// note that there are lines selected
			selectedLines = YES;
			
			// add this selected line to array of selected lines
			[selectedOPolyRois addObject: [roiSelectedArray objectAtIndex:i]];
		}
	}
	
	// if the current ROI is not an Open Polygon...
	// ... notify the user
	if (!selectedLines) {
		// notify the user through the NSRunAlertPanel		
		NSRunAlertPanel(NSLocalizedString(@"Plugins Error", nil),
						NSLocalizedString(@"No selected Open Polygon ROIs!", nil), 
						nil, nil, nil);
	}
}

- (void) partitionAllOpenPolyROIs
{
	int				i,ii;
	long			numInterPoints,numSplinePoints;
	ROI				*roiOPoly;
	
	// iterate through each selected Open Polygon ROI
	for (i = 0; i < [selectedOPolyRois count]; i++) {
		roiOPoly			= [selectedOPolyRois objectAtIndex:i];
		currentSpline		= [roiOPoly splinePoints];
		currentInterPoints	= [NSMutableArray arrayWithCapacity:0];
		numSplinePoints		= [currentSpline count];
		numInterPoints		= [tenTwentyIntervals count] - 1;
		
		for (ii = 0; ii < [tenTwentyIntervals count]; ii++) {
			// determine where on the spline we want to be
			float accumulatedInterval = [self accumulatedIntervalAtIndex:ii];
			
			// calculate the index of the point we want on spline
			int pointIndex = (numSplinePoints * accumulatedInterval) - 1;
			
			// select indexed point from spline and add it to array
			[currentInterPoints addObject: [currentSpline objectAtIndex:pointIndex]];
		}
		
		// add these intermediate points on line as ROIs
		[self addIntermediateROIs];
	}
}

- (void) addIntermediateROIs
{
	
	int				i;
	int				thisRoiType;
	double			pixelSpacingX,pixelSpacingY;
	NSPoint			thisOrigin;
	
	// temporary pointers for creating new ROI
	MyPoint			*thisPoint;
	ROI				*thisROI;
	
	// pointer to current DCMPix in OsiriX
	DCMPix			*thisDCMPix				= [[viewerController imageView] curDCM];

	// parameters necessary for initializting a new ROI
	thisRoiType		= t2DPoint;
	pixelSpacingX	= [thisDCMPix pixelSpacingX];
	pixelSpacingY	= [thisDCMPix pixelSpacingY];
	thisOrigin		= [DCMPix originCorrectedAccordingToOrientation: thisDCMPix];
	
	for (i = 0; i < [currentInterPoints count]; i++) {
		// point to 
		thisPoint = [[MyPoint alloc] initWithPoint: [[currentInterPoints objectAtIndex:i] point]];
		
		// allocate and initialize a new ROI
		thisROI = [[ROI alloc] initWithType: thisRoiType :pixelSpacingX :pixelSpacingY :thisOrigin];
		
		// move the ROI from the 0,0 to correct coordinates
		thisROI.rect = NSOffsetRect(thisROI.rect, thisPoint.x, thisPoint.y);
		
		// add the new ROI to the current ROI list
		[[[viewerController imageView] curRoiList] addObject:thisROI];
	}
	[thisPoint release];
	[thisROI release];
}

- (float) accumulatedIntervalAtIndex: (int)index
{
	// instanciate iterator
	int i;
	float accumulator = 0;
	// make sure given index exists
	assert(index <= ([tenTwentyIntervals count] - 1));
	for (i = 0; i <= index; i++) {
		accumulator += [[tenTwentyIntervals objectAtIndex:i] floatValue];
	}
	return accumulator;	
}

@end
