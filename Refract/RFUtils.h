//
//  RFUtils.h
//  Refract
//
//  Created by xiphux on 4/16/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface RFUtils : NSObject {
@private
    
}

+ (NSString *)readableBytesDecimal:(unsigned long)bytes;
+ (NSString *)readableBytesBinary:(unsigned long)bytes;

+ (NSString *)readableRateDecimal:(unsigned long)bytes;
+ (NSString *)readableRateBinary:(unsigned long)bytes;
@end
