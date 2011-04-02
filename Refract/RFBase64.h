//
//  RFBase64.h
//  Refract
//
//  Created by xiphux on 4/2/11.
//  Copied from QSUtilities
//

#import <Foundation/Foundation.h>


@interface RFBase64 : NSObject {
@private
    
}
+ (NSString *)encodeBase64WithString:(NSString *)strData;
+ (NSString *)encodeBase64WithData:(NSData *)objData;
+ (NSData *)decodeBase64WithString:(NSString *)strBase64;
@end
