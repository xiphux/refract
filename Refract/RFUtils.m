//
//  RFUtils.m
//  Refract
//
//  Created by xiphux on 4/16/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "RFUtils.h"

@interface RFUtils ()
+ (unsigned int)readableBytesReducePower:(unsigned long)bytes unit:(unsigned int)unit;
+ (NSString *)bytesUnit:(unsigned int)power unit:(unsigned int)unit;
+ (NSString *)rateUnit:(unsigned int)power unit:(unsigned int)unit;
+ (NSString *)readableRate:(unsigned long)bytes unit:(unsigned int)unit;
+ (NSString *)readableBytes:(unsigned long)bytes unit:(unsigned int)unit;
@end

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
    unsigned int power = [self readableBytesReducePower:bytes unit:unit];
    return [NSString stringWithFormat:@"%.2f %@", (((float)bytes) / pow(unit, power)), [RFUtils bytesUnit:power unit:unit]];
}

+ (NSString *)readableRateDecimal:(unsigned long)bytes
{
    return [RFUtils readableRate:bytes unit:1000];
}

+ (NSString *)readableRateBinary:(unsigned long)bytes
{
    return [RFUtils readableRate:bytes unit:1024];
}

+ (NSString *)readableRate:(unsigned long)bytes unit:(unsigned int)unit
{
    unsigned int power = [self readableBytesReducePower:bytes unit:unit];
    return [NSString stringWithFormat:@"%.2f %@", (((float)bytes) / pow(unit, power)), [RFUtils rateUnit:power unit:unit]];
}

+ (unsigned int)readableBytesReducePower:(unsigned long)bytes unit:(unsigned int)unit
{
    for (unsigned int i = 5; i > 1; i--) {
        unsigned long factor = pow(unit, i);
        if (bytes > factor) {
            return i;
        }
    }
    
    return 1;
}

+ (NSString *)bytesUnit:(unsigned int)power unit:(unsigned int)unit
{
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
        }
    }
    
    return nil;
}


+ (NSString *)rateUnit:(unsigned int)power unit:(unsigned int)unit
{
    if (unit == 1024) {
        switch (power) {
            case 1:
                return @"KiB/s";
                break;
                
            case 2:
                return @"MiB/s";
                break;
                
            case 3:
                return @"GiB/s";
                break;
                
            case 4:
                return @"TiB/s";
                break;
                
            case 5:
                return @"PiB/s";
                break;
        }
    } else if (unit == 1000) {
        switch (power) {
            case 1:
                return @"kB/s";
                break;
                
            case 2:
                return @"MB/s";
                break;
                
            case 3:
                return @"GB/s";
                break;
                
            case 4:
                return @"TB/s";
                break;
                
            case 5:
                return @"PB/s";
                break;
        }
    }
    
    return nil;
}

@end
