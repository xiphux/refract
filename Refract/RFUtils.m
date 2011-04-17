//
//  RFUtils.m
//  Refract
//
//  Created by xiphux on 4/16/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "RFUtils.h"


@implementation RFUtils

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

+ (NSString *)readableBytesDecimal:(unsigned long)bytes
{
    return [RFUtils readableBytes:bytes unit:1000];
}

+ (NSString *)readableBytesBinary:(unsigned long)bytes
{
    return [RFUtils readableBytes:bytes unit:1024];
}

+ (NSString *)readableBytes:(unsigned long)bytes unit:(unsigned int)unit
{
    for (int i = 5; i > 0; i--) {
        unsigned long factor = pow(unit,i);
        if (bytes > factor) {
            NSString *uStr = [RFUtils bytesUnit:i unit:unit];
            float val = ((float)bytes) / factor;
            return [NSString stringWithFormat:@"%.2f %@", val, uStr];
        }
    }
    
    return [NSString stringWithFormat:@"%d %@", bytes, [RFUtils bytesUnit:0 unit:unit]];
}

+ (NSString *)bytesUnitBinary:(unsigned int)power
{
    return [RFUtils bytesUnit:power unit:1024];
}

+ (NSString *)bytesUnitDecimal:(unsigned int)power
{
    return [RFUtils bytesUnit:power unit:1000];
}

+ (NSString *)bytesUnit:(unsigned int)power unit:(unsigned int)unit
{
    if (power == 0) {
        return @"B";
    }
    
    if (unit == 1024) {
        switch (power) {
            case 1:
                return @"KiB";
                break;
                
            case 2:
                return @"MiB";
                break;
                
            case 3:
                return @"GiB";
                break;
                
            case 4:
                return @"TiB";
                break;
                
            case 5:
                return @"PiB";
                break;
            
            case 6:
                return @"EiB";
                break;
                
            case 7:
                return @"ZiB";
                break;
                
            case 8:
                return @"YiB";
                break;
        }
    } else if (unit == 1000) {
        switch (power) {
            case 1:
                return @"kB";
                break;
                
            case 2:
                return @"MB";
                break;
                
            case 3:
                return @"GB";
                break;
                
            case 4:
                return @"TB";
                break;
                
            case 5:
                return @"PB";
                break;
                
            case 6:
                return @"EB";
                break;
                
            case 7:
                return @"ZB";
                break;
                
            case 8:
                return @"YB";
                break;
        }
    }
    
    return nil;
}

@end
