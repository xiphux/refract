//
//  URLTransformer.m
//  Refract
//
//  Created by xiphux on 6/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "URLTransformer.h"


@implementation URLTransformer

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (id)transformedValue:(id)value
{
    if (value == nil) return nil;
    
    if ([value isKindOfClass:[NSURL class]]) {
        return [NSString stringWithString:[(NSURL *)value absoluteString]];
    }
    
    [NSException raise:NSInternalInconsistencyException format:@"Invalid URL value"];
    return nil;
}

- (id)reverseTransformedValue:(id)value
{
    if (value == nil) return nil;
    
    if ([value isKindOfClass:[NSString class]]) {
        return [NSURL URLWithString:value];
    }
    
    [NSException raise:NSInternalInconsistencyException format:@"Invalid URL value"];
    return nil;
}

+(BOOL)allowsReverseTransformation
{
    return YES;
}

+(Class)transformedValueClass
{
    return [NSString class];
}

@end
