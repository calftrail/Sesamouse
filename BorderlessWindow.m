//
//  BorderlessWindow.m
//  Sesamouse
//
//  Created by Nathan Vander Wilt on 1/16/10.
//  Copyright 2010 Calf Trail Software, LLC. All rights reserved.
//

#import "BorderlessWindow.h"


@implementation BorderlessWindow

- (id)initWithContentRect:(NSRect)contentRect
					defer:(BOOL)flag
{
	self = [super initWithContentRect:contentRect
							styleMask:NSBorderlessWindowMask
							  backing:NSBackingStoreBuffered
								defer:flag];
	if (self) {
		[self setBackgroundColor:[NSColor clearColor]];
		[self setOpaque:NO];
	}
    return self;
}

- (BOOL)canBecomeKeyWindow {
	return YES;
}

- (BOOL)canBecomeMainWindow {
	return YES;
}

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem {
	if ([anItem action] == @selector(performClose:)) {
		return YES;
	}
	else if ([anItem action] == @selector(performMiniaturize:)) {
		return YES;
	}
	return [super validateUserInterfaceItem:anItem];
}

- (void)performClose:(id)sender {
	(void)sender;
	BOOL shouldClose = YES;
	if ([[self delegate] respondsToSelector:@selector(windowShouldClose:)]) {
		shouldClose = [[self delegate] windowShouldClose:self];
	}
	else if ([self respondsToSelector:@selector(windowShouldClose:)]) {
		shouldClose = [(id)self windowShouldClose:self];
	}
	if (shouldClose) {
		[self close];
	}
}

- (void)performMiniaturize:(id)sender {
	(void)sender;
	[self miniaturize:sender];
}

@end
