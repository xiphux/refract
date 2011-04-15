//
//  RFURLConnection.h
//  Refract
//
//  Created by xiphux on 4/13/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface RFURLConnection : NSURLConnection {
@private
    NSDictionary *userInfo;
    NSData *requestData;
    NSHTTPURLResponse *response;
    NSMutableData *responseData;
}

@property (nonatomic, retain) NSDictionary *userInfo;
@property (nonatomic, retain) NSData *requestData;
@property (nonatomic, retain) NSHTTPURLResponse *response;
@property (nonatomic, retain) NSMutableData *responseData;

@end
