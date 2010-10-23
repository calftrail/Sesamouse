//
//  BorderlessWindow.h
//  Sesamouse
//
//  Created by Nathan Vander Wilt on 1/16/10.
//  Copyright 2010 Calf Trail Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface BorderlessWindow : NSWindow {

}

- (id)initWithContentRect:(NSRect)contentRect
					defer:(BOOL)flag;

@end
