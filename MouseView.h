//
//  MouseView.h
//  Sesamouse
//
//  Created by Nathan Vander Wilt on 1/16/10.
//  Copyright 2010 Calf Trail Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class CATextLayer;

@interface MouseView : NSView {
@private
	BOOL windowActive;
	NSSet* activeTouches;
	NSMapTable* touchLayers;
	CATextLayer* logoLayer;
}

@end
