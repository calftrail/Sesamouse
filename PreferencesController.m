//
//  PreferencesController.m
//  Sesamouse
//
//  Created by Nathan Vander Wilt on 3/6/10.
//  Copyright 2010 Calf Trail Software, LLC. All rights reserved.
//

#import "PreferencesController.h"

const CFStringRef HelperSuite = CFSTR("com.calftrail.touch-synthesis");
const CFStringRef HelperUpKey = CFSTR("SwipeActionUp");
const CFStringRef HelperDownKey = CFSTR("SwipeActionDown");


@implementation PreferencesController

// @"Ignore", @"Middle Click", @"Show Desktop", @"App Exposé", @"Exposé", @"Dashboard", @"Spaces"

- (NSArray*)upOptions {
	return [NSArray arrayWithObjects:
			@"Swipe up", @"Show Desktop", @"Dashboard",
			@"Exposé", @"Spaces", nil];
}

- (void)setUpAction:(NSString*)action {
	CFPreferencesSetAppValue(HelperUpKey, (CFStringRef)action, HelperSuite);
	CFPreferencesAppSynchronize(HelperSuite);
}

- (NSString*)upAction {
	CFStringRef action = CFPreferencesCopyAppValue(HelperUpKey, HelperSuite);
	if (!action) action = (CFStringRef)[[self upOptions] objectAtIndex:0];
	return [(NSString*)action autorelease];
}

- (NSArray*)downOptions {
	return [NSArray arrayWithObjects:
			@"Swipe down", @"Exposé", @"Spaces",
			@"Show Desktop", @"Dashboard", nil];
}

- (void)setDownAction:(NSString*)action {
	CFPreferencesSetAppValue(HelperDownKey, (CFStringRef)action, HelperSuite);
	CFPreferencesAppSynchronize(HelperSuite);
}

- (NSString*)downAction {
	CFStringRef action = CFPreferencesCopyAppValue(HelperDownKey, HelperSuite);
	if (!action) action = (CFStringRef)[[self downOptions] objectAtIndex:0];
	return [(NSString*)action autorelease];
}

@end
