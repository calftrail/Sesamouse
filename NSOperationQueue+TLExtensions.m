//
//  NSOperationQueue+TLExtensions.m
//  Sesamouse
//
//  Created by Nathan Vander Wilt on 2/11/10.
//  Copyright 2010 Calf Trail Software, LLC. All rights reserved.
//

#import "NSOperationQueue+TLExtensions.h"


@implementation NSOperationQueue (TLExtensions)

- (void)tl_addOperationForTarget:(id)target
						selector:(SEL)sel
						  object:(id)arg
{
	NSInvocationOperation* op = [[NSInvocationOperation alloc] initWithTarget:target selector:sel object:arg];
	[self addOperation:op];
	[op release];
}

@end
