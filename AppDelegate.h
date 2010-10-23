//
//  AppDelegate.h
//  Sesamouse
//
//  Created by Nathan Vander Wilt on 1/16/10.
//  Copyright 2010 Calf Trail Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>



@class StatusView, PreferencesController;

@interface AppDelegate : NSObject <NSApplicationDelegate> {
@private
	PreferencesController* prefs;
	NSStatusItem* statusItem;
    NSWindow* window;
	StatusView* statusView;
	NSOperationQueue* taskQueue;
	NSTask* task;
}

@property (assign) IBOutlet NSWindow* window;

- (IBAction)showHelp:(id)sender;
- (IBAction)showPreferences:(id)sender;

@end
