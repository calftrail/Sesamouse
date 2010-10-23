//
//  NSOperationQueue+TLExtensions.h
//  Sesamouse
//
//  Created by Nathan Vander Wilt on 2/11/10.
//  Copyright 2010 Calf Trail Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSOperationQueue (TLExtensions)

- (void)tl_addOperationForTarget:(id)target
						selector:(SEL)sel
						  object:(id)arg;

@end
