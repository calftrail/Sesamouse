//
//  StatusView.h
//  Sesamouse
//
//  Created by Nathan Vander Wilt on 1/16/10.
//  Copyright 2010 Calf Trail Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


typedef enum {
	MouseStatusTrackpad = -3,
	MouseStatusFailed = -2,
	MouseStatusNoMouse = -1,
	MouseStatusLoading = 0,
	MouseStatusReady = 1
} MouseStatus;


@class CATextLayer;

@interface StatusView : NSView {
@private
	MouseStatus status;
	CATextLayer* statusText;
	CATextLayer* proceedButton;
}

@property MouseStatus status;

@end
