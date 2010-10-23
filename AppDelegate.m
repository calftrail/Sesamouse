//
//  AppDelegate.m
//  Sesamouse
//
//  Created by Nathan Vander Wilt on 1/16/10.
//  Copyright 2010 Calf Trail Software, LLC. All rights reserved.
//

#import "AppDelegate.h"

#import "BorderlessWindow.h"
#import "MouseView.h"
#import "StatusView.h"
#import "PreferencesController.h"

#import "NSOperationQueue+TLExtensions.h"

@interface AppDelegate () <NSMenuDelegate>
- (void)showInMenuBar;
- (void)loadWindow;
@end


@implementation AppDelegate

@synthesize window;

- (id)init {
	self = [super init];
	if (self) {
		taskQueue = [NSOperationQueue new];
		taskQueue.maxConcurrentOperationCount = 1;
		prefs = [[PreferencesController alloc] initWithWindowNibName:@"Preferences"];
	}
	return self;
}

- (void)dealloc {
	[statusItem release];
	[taskQueue release];
	[super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	BOOL dockless = [[[[NSBundle mainBundle] infoDictionary] objectForKey:@"LSUIElement"] boolValue];
	BOOL clutterless = [[NSUserDefaults standardUserDefaults] boolForKey:@"PreventMenuItem"];
	if (dockless && !clutterless) {
		[self showInMenuBar];
	}
	
	[self loadWindow];
	[window makeKeyAndOrderFront:self];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(taskTerminated:)
												 name:NSTaskDidTerminateNotification object:nil];
	
#if 1
	[taskQueue tl_addOperationForTarget:self selector:@selector(cleanupChildren) object:nil];
#endif
	
	[taskQueue tl_addOperationForTarget:self selector:@selector(launchChild) object:nil];
}

- (BOOL)applicationShouldHandleReopen:(NSApplication*)theApplication hasVisibleWindows:(BOOL)flag {
	(void)theApplication;
	(void)flag;
	[window makeKeyAndOrderFront:self];
	return NO;
}

- (void)loadWindow {
	NSRect windowRect = NSMakeRect(10.0f, 10.0f, 300.0f, 550.0f);
	window = [[BorderlessWindow alloc] initWithContentRect:windowRect defer:NO];
	[window setReleasedWhenClosed:NO];
	[window setFrameAutosaveName:@"Mouse"];
	[window setMovableByWindowBackground:YES];
	[window setLevel:NSFloatingWindowLevel];
	
	MouseView* mouseView = [[MouseView alloc] initWithFrame:NSZeroRect];
	[window setContentView:mouseView];
	[mouseView release];
	
	statusView = [[StatusView alloc] initWithFrame:[mouseView bounds]];
	[mouseView addSubview:statusView];
	[statusView release];
}

- (void)showInMenuBar {
	NSMenu* menu = [[NSMenu alloc] initWithTitle:@"Sesamouse"];
	menu.delegate = self;
	NSMenuItem* toggleItem = [menu addItemWithTitle:@"" action:NULL keyEquivalent:@""];
	toggleItem.tag = 1;
	[menu addItemWithTitle:@"Quit" action:@selector(terminate:) keyEquivalent:@""];
	[menu addItem:[NSMenuItem separatorItem]];
	[menu addItemWithTitle:@"Open Sesamouse Preferences..."
					action:@selector(showPreferences:) keyEquivalent:@""];
	
	statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
	statusItem.image = [NSImage imageNamed:@"ClubIconTiny"];
	statusItem.highlightMode = YES;
	statusItem.menu = [menu autorelease];
	[statusItem retain];
}

- (void)menuNeedsUpdate:(NSMenu*)menu {
	NSMenuItem* toggleItem = [menu itemWithTag:1];
	toggleItem.target = window;
	if ([window isVisible]) {
		toggleItem.title = @"Hide Mouse Viewer";
		toggleItem.action = @selector(orderOut:);
	}
	else {
		toggleItem.title = @"Show Mouse Viewer";
		toggleItem.action = @selector(makeKeyAndOrderFront:);
	}
}

- (void)taskTerminated:(NSNotification*)notification {
	if ([notification object] != task) return;
	int exit = [task terminationStatus];
	switch (exit) {
		case 42:
			statusView.status = MouseStatusNoMouse;
			break;
		case 43:
			statusView.status = MouseStatusTrackpad;
			break;
		default:
			statusView.status = MouseStatusFailed;
	}
	//printf("Task terminated (%i)!\n", exit);
	[task release], task = nil;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication*)sender {
	[taskQueue tl_addOperationForTarget:self selector:@selector(cleanupChildAndExit) object:nil];
	return NSTerminateLater;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication*)theApplication {
	[theApplication hide:self];
	return NO;
}

- (void)cleanupChildren {
	NSTask* cleanupTask = [NSTask new];
	cleanupTask.launchPath = @"/usr/bin/killall";
	cleanupTask.arguments = [NSArray arrayWithObject:@"TouchSynthesis"];
	[cleanupTask launch];
	[cleanupTask waitUntilExit];
	[cleanupTask release];
}
	 
- (void)launchChild {
	statusView.status = MouseStatusLoading;
	NSString* path = [[NSBundle mainBundle] pathForResource:@"TouchSynthesis" ofType:nil];
	task = [NSTask new];
	[task setLaunchPath:path];
	// task must be launched on main thread to workaround rdar://problem/7549966
	[task performSelectorOnMainThread:@selector(launch) withObject:nil waitUntilDone:YES];
	sleep(2);
	if ([task isRunning]) {
		statusView.status = MouseStatusReady;
	}
}

- (void)exitReply {
	[NSApp replyToApplicationShouldTerminate:YES];
}

- (void)cleanupChildAndExit {
	if ([task isRunning]) {
		[task terminate];
	}
	[task release], task = nil;
	[self performSelectorOnMainThread:@selector(exitReply) withObject:nil waitUntilDone:NO];
}

- (IBAction)showHelp:(id)sender {
	(void)sender;
	NSURL* helpURL = [NSURL URLWithString:@"http://calftrail.com/support/sesamouse_instructions.html"];
	[[NSWorkspace sharedWorkspace] openURL:helpURL];
}

- (IBAction)showPreferences:(id)sender {
	[prefs showWindow:sender];
}

@end
