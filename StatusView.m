//
//  StatusView.m
//  Sesamouse
//
//  Created by Nathan Vander Wilt on 1/16/10.
//  Copyright 2010 Calf Trail Software, LLC. All rights reserved.
//

#import "StatusView.h"

#import <QuartzCore/QuartzCore.h>

extern CGColorRef tlCGColorMakeRGB(CGFloat r, CGFloat g,  CGFloat b, CGFloat a);
extern CGColorRef tlCGColorMakeGray(CGFloat gray, CGFloat a);

static NSString* KVOContext = @"StatusView KVO context";


@interface CALayer (TLExtensions)
- (CALayer*)tl_rootLayer;
- (CGRect)tl_pixelAlignRect:(CGRect)proposedRect;
@end


@implementation StatusView

@synthesize status;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		self.layer = [CALayer layer];
		self.wantsLayer = YES;
		[self addObserver:self forKeyPath:@"status"
				  options:NSKeyValueObservingOptionNew context:&KVOContext];
		
		statusText = [CATextLayer layer];
		statusText.font = @"Futura";
		statusText.alignmentMode = kCAAlignmentCenter;
		//statusText.backgroundColor = tlCGColorMakeRGB(0, 0, 0.5, 0.5);
		
		proceedButton = [CATextLayer layer];
		proceedButton.font = @"American Typewriter";
		proceedButton.alignmentMode = kCAAlignmentCenter;
		proceedButton.foregroundColor = tlCGColorMakeGray(0, 1);
		//proceedButton.borderWidth = 1;
		//proceedButton.backgroundColor = tlCGColorMakeRGB(0, 0.5, 0, 0.5);
		proceedButton.hidden = YES;
		
		self.layer.layoutManager = self;
		[self.layer addSublayer:statusText];
		[self.layer addSublayer:proceedButton];
		[self.layer setNeedsLayout];
    }
    return self;
}

- (void)dealloc {
	[self removeObserver:self forKeyPath:@"status"];
	[super dealloc];
}

- (void)updateStatus {
	//printf("New status: %i\n", self.status);
	switch (self.status) {
		case MouseStatusTrackpad:
			statusText.string = @"Trackpad?";
			statusText.foregroundColor = tlCGColorMakeRGB(1, 0.25f, 0, 1);
			proceedButton.string = @"See details on site.";
			proceedButton.hidden = NO;
			break;
		case MouseStatusFailed:
			statusText.string = @"Failed";
			statusText.foregroundColor = tlCGColorMakeRGB(1, 0, 0, 1);
			proceedButton.string = @"Check for update";
			proceedButton.hidden = NO;
			break;
		case MouseStatusNoMouse:
			statusText.string = @"No mouse";
			statusText.foregroundColor = tlCGColorMakeRGB(1, 0.5f, 0, 1);
			proceedButton.string = @"Try again";
			proceedButton.hidden = NO;
			break;
		case MouseStatusLoading:
			statusText.string = @"Loading";
			statusText.foregroundColor = tlCGColorMakeRGB(1, 1, 0, 1);
			proceedButton.hidden = YES;
			break;
		case MouseStatusReady:
			statusText.string = @"Ready";
			statusText.foregroundColor = tlCGColorMakeRGB(0, 1, 0, 1);
			proceedButton.hidden = YES;
			break;
	}
	
	[statusText removeAllAnimations];
	if (self.status == MouseStatusLoading) {
		CABasicAnimation* anim = [CABasicAnimation animationWithKeyPath:@"foregroundColor"];
		anim.autoreverses = YES;
		anim.repeatCount = FLT_MAX;
		anim.duration = 5;
		anim.fromValue = (id)tlCGColorMakeRGB(249 / 255.0f,
											  248 / 255.0f,
											  72 / 255.0f, 1);
		anim.toValue = (id)tlCGColorMakeRGB(255 / 255.0f,
											210 / 255.0f,
											0 / 255.0f, 1);
		[statusText addAnimation:anim forKey:nil];
	}
	else if (self.status == MouseStatusReady) {
		CABasicAnimation* anim = [CABasicAnimation animationWithKeyPath:@"opacity"];
		anim.timingFunction = [CAMediaTimingFunction
							   functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
		anim.removedOnCompletion = NO;
		anim.fillMode = kCAFillModeBoth;
		anim.duration = 15;
		anim.toValue = [NSNumber numberWithInt:0];
		[statusText addAnimation:anim forKey:nil];
	}
}

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object
						change:(NSDictionary*)change context:(void*)context
{
	(void)object;
	(void)change;
    if (context == &KVOContext) {
		if ([keyPath isEqualToString:@"status"]) {
			[self performSelectorOnMainThread:@selector(updateStatus)
								   withObject:nil
								waitUntilDone:NO];
		}
	}
	else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

- (void)layoutSublayersOfLayer:(CALayer*)theLayer {
	NSAssert(theLayer == self.layer, @"Only layout own layer");
	
	CGRect target = theLayer.bounds;
	CGFloat scale = CGRectGetWidth(target) / 250;
	statusText.fontSize = 32 * scale;
	statusText.bounds = CGRectMake(0, 0, CGRectGetWidth(target) / 1.5f, 50 * scale);
	proceedButton.fontSize = 12 * scale;
	proceedButton.bounds = CGRectMake(0, 0, CGRectGetWidth(target) / 2, 14 * scale);
	proceedButton.cornerRadius = 5 * scale;
	
	statusText.position = CGPointMake(CGRectGetMidX(target),
									  CGRectGetMaxY(target) - 85 * scale);
	proceedButton.position = CGPointMake(CGRectGetMidX(target),
										 CGRectGetMaxY(target) - 115 * scale);
	statusText.frame = [theLayer tl_pixelAlignRect:statusText.frame];
	proceedButton.frame = [theLayer tl_pixelAlignRect:proceedButton.frame];
}

- (void)mouseUp:(NSEvent*)theEvent {
	(void)theEvent;
	if (self.status == MouseStatusNoMouse) {
		// TODO: retry loading
	}
	else if (self.status == MouseStatusNoMouse) {
		// TODO: check for update
	}
}

@end


@implementation CALayer (TLExtensions)

- (CALayer*)tl_rootLayer {
	CALayer* parentLayer = self;
	while (parentLayer.superlayer) {
		parentLayer = parentLayer.superlayer;
	}
	return parentLayer;
}

- (CGRect)tl_pixelAlignRect:(CGRect)proposedRect {
	CALayer* rootLayer = self.tl_rootLayer;
	CGRect baseRect = [self convertRect:proposedRect toLayer:rootLayer];
	return [self convertRect:CGRectIntegral(baseRect) fromLayer:rootLayer];
}

@end
