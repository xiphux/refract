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
+ (NSString *)readableBytes:(unsigned long)bytes unit:(unsigned int)unit;

+ (NSString *)bytesUnitDecimal:(unsigned int)power;
+ (NSString *)bytesUnitBinary:(unsigned int)power;
+ (NSString *)bytesUnit:(unsigned int)power unit:(unsigned int)unit;

@end
