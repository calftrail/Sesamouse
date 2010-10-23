//
//  MouseView.m
//  Sesamouse
//
//  Created by Nathan Vander Wilt on 1/16/10.
//  Copyright 2010 Calf Trail Software, LLC. All rights reserved.
//

#import "MouseView.h"

#import <QuartzCore/QuartzCore.h>

static CGPoint tlCGRectDenormalizedPoint(CGRect rect, CGPoint pos);
CGColorRef tlCGColorMakeRGB(CGFloat r, CGFloat g,  CGFloat b, CGFloat a);
CGColorRef tlCGColorMakeGray(CGFloat gray, CGFloat a);
static CGRect tlCGRectInsetToAspect(CGRect rect, CGFloat aspect);
static void tlCGContextAddRoundRect(CGContextRef ctx, CGRect rect, CGFloat r);
static void tlCGContextAddRoundRect2(CGContextRef ctx, CGRect rect, CGFloat rX, CGFloat rY);
static CGRect tlCGRectMakeWithCenter(CGPoint center, CGSize size);
static CGSize tlCGSizeApplyTransform3D(CGSize s, CATransform3D t);

static NSString* KVOContext = @"MouseView KVO context";

@interface MouseView ()
@property BOOL windowActive;
@property (copy) NSSet* activeTouches;
@property (retain) NSMapTable* touchLayers;
@end


@implementation MouseView

@synthesize windowActive;
@synthesize activeTouches;
@synthesize touchLayers;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		self.layer = [CALayer layer];
		self.wantsLayer = YES;
		//self.layer.backgroundColor = tlCGColorMakeGray(0, 1);
		self.layer.speed = 5.0f;
		self.layer.shadowOpacity = 1.0f;
		
		self.layer.delegate = self;
		self.layer.needsDisplayOnBoundsChange = YES;
		self.layer.layoutManager = self;
		
		logoLayer = [CATextLayer layer];
		//logoLayer.anchorPoint = CGPointMake(0.5f, 0.65f);
		logoLayer.foregroundColor = tlCGColorMakeGray(0.5f, 0.25f);
		logoLayer.alignmentMode = kCAAlignmentCenter;
		logoLayer.string = @"♣";
		[self.layer addSublayer:logoLayer];
		[self.layer setNeedsLayout];
		
		if ([self respondsToSelector:@selector(setAcceptsTouchEvents:)]) {
			self.acceptsTouchEvents = YES;
			self.wantsRestingTouches = YES;
		}
		
		[self addObserver:self forKeyPath:@"activeTouches"
				  options:NSKeyValueObservingOptionNew context:&KVOContext];
		[self addObserver:self forKeyPath:@"windowActive"
				  options:NSKeyValueObservingOptionNew context:&KVOContext];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(updateActive:)
													 name:NSWindowDidBecomeMainNotification
												   object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(updateActive:)
													 name:NSWindowDidResignMainNotification
												   object:nil];
    }
    return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[self removeObserver:self forKeyPath:@"activeTouches"];
	[self removeObserver:self forKeyPath:@"windowActive"];
	[activeTouches release];
	[touchLayers release];
	[super dealloc];
}

- (void)updateActive:(NSNotification*)aNotification {
	if ([aNotification object] == [self window]) {
		self.windowActive = [[self window] isMainWindow];
	}
}

+ (CGRect)mouseRect:(CGRect)targetRect {
	// width = height / 2
	return tlCGRectInsetToAspect(targetRect, 0.5f);
}

+ (CGFloat)mouseRadius:(CGRect)targetRect {
	// cornerRadius = 85 / 250 * width
	return 0.34 * CGRectGetWidth(targetRect);
}

+ (CGPoint)logoPoint:(CGRect)mouseRect {
	return tlCGRectDenormalizedPoint(mouseRect, CGPointMake(0.5f, 0.2f));
}

+ (CGFloat)logoSize:(CGRect)mouseRect {
	return mouseRect.size.width / 5;
}

+ (CGFloat)touchRadius:(CGRect)touchRect {
	return touchRect.size.width / 7;
}

- (CGRect)mousePad {
	const CGFloat padding = self.layer.bounds.size.width / 15;
	return CGRectInset(self.layer.bounds, padding, padding);
}

- (CGRect)touchRect {
	CGRect targetRect = [self mousePad];
	CGRect mouseRect = [[self class] mouseRect:targetRect];
	CGPoint logoPoint = [[self class] logoPoint:mouseRect];
	return CGRectMake(mouseRect.origin.x, logoPoint.y,
					  mouseRect.size.width, mouseRect.size.height * 0.8f);
}

- (void)layoutSublayersOfLayer:(CALayer*)theLayer {
	NSAssert(theLayer == self.layer, @"Layouts own layer only");
	
	CGRect targetRect = [self mousePad];
	CGRect mouseRect = [[self class] mouseRect:targetRect];
	logoLayer.position = [[self class] logoPoint:mouseRect];
	logoLayer.fontSize = [[self class] logoSize:mouseRect];
	logoLayer.bounds = CGRectMake(0, 0, logoLayer.fontSize, logoLayer.fontSize);
}

static void drawTextInBox(CGContextRef ctx, CGRect textBox,
						  const char* font, const char* text)
{
	CGContextSelectFont(ctx, font, CGRectGetHeight(textBox), kCGEncodingMacRoman);
	CGContextSetTextPosition(ctx, 0, 0);
	CGContextSetTextDrawingMode(ctx, kCGTextInvisible);
	CGContextShowText(ctx, text, strlen(text));
	CGFloat textWidth = CGContextGetTextPosition(ctx).x;
	CGFloat textX = CGRectGetMidX(textBox) - textWidth / 2;
	
	CGContextSetTextPosition(ctx, textX, CGRectGetMinY(textBox));
	CGContextSetTextDrawingMode(ctx, kCGTextFill);
	CGContextSetFillColorWithColor(ctx, tlCGColorMakeRGB(0, .5f, .95f, 0.6f));
	CGContextShowText(ctx, text, strlen(text));
}

- (void)drawLayer:(CALayer*)theLayer inContext:(CGContextRef)ctx {
	NSAssert(theLayer == self.layer, @"Draws own layer only");
	
	CGRect targetRect = [self mousePad];
	CGRect mouseRect = [[self class] mouseRect:targetRect];
	CGFloat mouseRadius = [[self class] mouseRadius:targetRect];
	tlCGContextAddRoundRect(ctx, mouseRect, mouseRadius);
	CGContextSetGrayFillColor(ctx, 1, 1);
	CGContextFillPath(ctx);
	
	CGRect realTouchRect = [self touchRect];
	CGContextSetLineDash(ctx, 0, (CGFloat[]){4,4}, 2);
	CGContextSetGrayStrokeColor(ctx, 0.75f, 0.5f);
	
	CGFloat touchRadius = mouseRadius / 5;
	CGRect touchRect = CGRectInset(realTouchRect, touchRadius, 0);
	touchRect.size.height -= mouseRadius / 2;
	tlCGContextAddRoundRect(ctx, touchRect, touchRadius);
	CGContextStrokePath(ctx);
	
	CGFloat splitY = CGRectGetMinY(realTouchRect) + 0.6f * CGRectGetHeight(realTouchRect);
	CGContextMoveToPoint(ctx, CGRectGetMinX(touchRect), splitY);
	CGContextAddLineToPoint(ctx, CGRectGetMaxX(touchRect), splitY);
	CGContextSetGrayStrokeColor(ctx, 0, 0.5f);
	CGContextStrokePath(ctx);
	
	if (!NSClassFromString(@"NSTouch")) {
		const char* text = "Leopard mode: Gestures only";
		const char* font = "American Typewriter";
		CGFloat textHeight = CGRectGetHeight(touchRect) / 25;
		CGRect textBox = CGRectMake(CGRectGetMinX(touchRect), splitY - textHeight,
									CGRectGetWidth(touchRect), textHeight);
		drawTextInBox(ctx, textBox, font, text);
	}
}

- (void)updateTouchLayers {
	//printf("%s\n", [[self.activeTouches description] UTF8String]);
	
	NSMapTable* activeTouchLayers = [NSMapTable mapTableWithStrongToStrongObjects];
	CGRect targetBounds = [self touchRect];
	for (NSTouch* touch in self.activeTouches) {
		CALayer* touchLayer = [touchLayers objectForKey:touch.identity];
		if (!touchLayer) {
			touchLayer = [CALayer layer];
			CGFloat radius = [[self class] touchRadius:targetBounds];
			radius /= 2;
			touchLayer.bounds = CGRectMake(0, 0, 2*radius, 2*radius);
			touchLayer.cornerRadius = radius;
			touchLayer.shadowOpacity = 1.0f;
			touchLayer.shadowRadius = radius / 5;
			touchLayer.shadowOffset = CGSizeZero;
			touchLayer.shadowColor = tlCGColorMakeRGB(0, .45f, .85f, 1);
			[self.layer addSublayer:touchLayer];
		}
		[activeTouchLayers setObject:touchLayer forKey:touch.identity];
		
		CGPoint offset = NSPointToCGPoint(touch.normalizedPosition);
		touchLayer.position = tlCGRectDenormalizedPoint(targetBounds, offset);
		if (!touch.isResting) {
			touchLayer.backgroundColor = tlCGColorMakeRGB(0, .5f, .95f, 1);
		}
		else {
			touchLayer.backgroundColor = tlCGColorMakeRGB(0, .5f, .95f, 0.15f);
		}
	}
	for (id touchID in touchLayers) {
		if (![activeTouchLayers objectForKey:touchID]) {
			[[touchLayers objectForKey:touchID] removeFromSuperlayer];
		}
	}
	self.touchLayers = activeTouchLayers;
}

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object
						change:(NSDictionary*)change context:(void*)context
{
	(void)object;
	(void)change;
    if (context == &KVOContext) {
		if ([keyPath isEqualToString:@"activeTouches"]) {
			[self updateTouchLayers];
		}
		else if ([keyPath isEqualToString:@"windowActive"]) {
			CGFloat scale = self.layer.bounds.size.width / 250;
			self.layer.shadowRadius = scale * (self.windowActive ? 10 : 4);
			CGFloat logoGray = self.windowActive ? 0.5f : 0.65f;
			logoLayer.foregroundColor = tlCGColorMakeGray(logoGray, 0.25);
		}
	}
	else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

- (void)beginGestureWithEvent:(NSEvent*)event {
	logoLayer.foregroundColor = tlCGColorMakeGray(0, 0.25f);
	logoLayer.shadowOpacity = 0.05f;
}

- (void)endGestureWithEvent:(NSEvent*)event {
	[CATransaction begin];
	[CATransaction setValue:[NSNumber numberWithDouble:2.0]
					 forKey:(id)kCATransactionAnimationDuration];
	logoLayer.foregroundColor = tlCGColorMakeGray(0.5, 0.25);
	logoLayer.shadowOpacity = 0;
	logoLayer.transform = CATransform3DIdentity;
	[CATransaction commit];
}

- (void)magnifyWithEvent:(NSEvent*)event {
	CGFloat scale = 1 + [event magnification];
	const CGFloat scaleLimit = 5;
	CATransform3D prevTransform = logoLayer.transform;
	CGSize scaledSize = tlCGSizeApplyTransform3D(CGSizeMake(1,1), prevTransform);
	CGFloat currentScale = (CGFloat)MAX(fabs(scaledSize.width), fabs(scaledSize.height));
	if (currentScale * scale > scaleLimit) {
		scale = scaleLimit / currentScale;
	}
	logoLayer.transform = CATransform3DScale(prevTransform, scale, scale, scale);
}

static const CGFloat degreesToRadians = (CGFloat)(M_PI / 180.0);

- (void)rotateWithEvent:(NSEvent*)event {
	CGFloat rotation = degreesToRadians * [event rotation];
	logoLayer.transform = CATransform3DRotate(logoLayer.transform, rotation, 0, 0, 1);
}

- (void)swipeWithEvent:(NSEvent*)event {
	CGFloat swipeDistance = self.layer.bounds.size.width / 5;
	CGFloat dX = swipeDistance * [event deltaX];
	CGFloat dY = swipeDistance * -[event deltaY];
	
	CABasicAnimation* anim = [CABasicAnimation animationWithKeyPath:@"position"];
	anim.duration = 1.0;
	anim.autoreverses = YES;
	anim.byValue = [NSValue valueWithPoint:NSMakePoint(-dX, -dY)];
	[logoLayer addAnimation:anim forKey:nil];
}

- (void)touchesBeganWithEvent:(NSEvent*)event {
	self.activeTouches = [event touchesMatchingPhase:NSTouchPhaseTouching inView:nil];
}

- (void)touchesMovedWithEvent:(NSEvent*)event {
	self.activeTouches = [event touchesMatchingPhase:NSTouchPhaseTouching inView:nil];
}

- (void)touchesEndedWithEvent:(NSEvent*)event {
	self.activeTouches = [event touchesMatchingPhase:NSTouchPhaseTouching inView:nil];
}

- (void)touchesCancelledWithEvent:(NSEvent*)event {
	self.activeTouches = [event touchesMatchingPhase:NSTouchPhaseTouching inView:nil];
}

@end


CGPoint tlCGRectDenormalizedPoint(CGRect rect, CGPoint pos) {
	return CGPointMake(rect.origin.x + pos.x * rect.size.width,
					   rect.origin.y + pos.y * rect.size.height);
}

CGColorRef tlCGColorMakeRGB(CGFloat r, CGFloat g,  CGFloat b, CGFloat a) {
	CGColorRef c = CGColorCreateGenericRGB(r, g, b, a);
	return (CGColorRef)[(id)c autorelease];
}

CGColorRef tlCGColorMakeGray(CGFloat gray, CGFloat a) {
	CGColorRef c = CGColorCreateGenericGray(gray, a);
	return (CGColorRef)[(id)c autorelease];
}

// aspect = width / height
CGRect tlCGRectInsetToAspect(CGRect rect, CGFloat aspect) {
	CGFloat currentAspect = CGRectGetWidth(rect) / CGRectGetHeight(rect);
	if (currentAspect < aspect) {			// too tall
		CGFloat newHeight = CGRectGetWidth(rect) / aspect;
		CGFloat diff = CGRectGetHeight(rect) - newHeight;
		NSCAssert(diff > 0, @"Not as planned");
		return CGRectInset(rect, 0, diff / 2);
	}
	else if (aspect < currentAspect) {		// too wide
		CGFloat newWidth = CGRectGetHeight(rect) * aspect;
		CGFloat diff = CGRectGetWidth(rect) - newWidth;
		NSCAssert(diff > 0, @"Not as planned");
		return CGRectInset(rect, diff / 2, 0);
	}
	else {
		return rect;
	}
}

void tlCGContextAddRoundRect(CGContextRef ctx, CGRect rect, CGFloat r) {
	CGContextMoveToPoint(ctx, CGRectGetMinX(rect), CGRectGetMidY(rect));
	CGContextAddArcToPoint(ctx, CGRectGetMinX(rect), CGRectGetMaxY(rect),
						   CGRectGetMidX(rect), CGRectGetMaxY(rect), r);
	CGContextAddArcToPoint(ctx, CGRectGetMaxX(rect), CGRectGetMaxY(rect),
						   CGRectGetMaxX(rect), CGRectGetMidY(rect), r);
	CGContextAddArcToPoint(ctx, CGRectGetMaxX(rect), CGRectGetMinY(rect),
						   CGRectGetMidX(rect), CGRectGetMinY(rect), r);
	CGContextAddArcToPoint(ctx, CGRectGetMinX(rect), CGRectGetMinY(rect),
						   CGRectGetMinX(rect), CGRectGetMidY(rect), r);
	CGContextClosePath(ctx);
}

// based on http://developer.apple.com/mac/library/samplecode/QuartzShapes/listing10.html
void tlCGContextAddRoundRect2(CGContextRef ctx, CGRect rect, CGFloat rX, CGFloat rY) {
    if (rX == 0 || rY == 0) {
        CGContextAddRect(ctx, rect);
        return;
    }
    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx, CGRectGetMinX(rect), CGRectGetMinY(rect));
    CGContextScaleCTM(ctx, rX, rY);
    CGFloat tW = CGRectGetWidth(rect) / rX;
    CGFloat tH = CGRectGetHeight(rect) / rY;
	CGContextMoveToPoint(ctx, 0, tH/2);
	CGContextAddArcToPoint(ctx, 0, tH, tW/2, tH, 1);
	CGContextAddArcToPoint(ctx, tW, tH, tW, tH/2, 1);
	CGContextAddArcToPoint(ctx, tW, 0, tW/2, 0, 1);
	CGContextAddArcToPoint(ctx, 0, 0, 0, tH/2, 1);
    CGContextClosePath(ctx);
    CGContextRestoreGState(ctx);
}

CGRect tlCGRectMakeWithCenter(CGPoint center, CGSize size) {
	return (CGRect){
		.origin = CGPointMake(center.x - size.width / 2,
							  center.y - size.height / 2),
		.size = size
	};
}

static CGSize tlCGSizeApplyTransform3D(CGSize s, CATransform3D t) {
	if (CATransform3DIsAffine(t)) {
		CGAffineTransform aT = CATransform3DGetAffineTransform(t);
		return CGSizeApplyAffineTransform(s, aT);
	}
	CGFloat w = (s.width * t.m11) + (s.width * t.m21) + (s.width * t.m31) + (s.width * t.m41);
	CGFloat h = (s.height * t.m12) + (s.height * t.m22) + (s.height * t.m32) + (s.height * t.m42);
	CGFloat d = t.m14 + t.m24 + t.m34 + t.m44;
	return CGSizeMake(w / d, h / d);
}
