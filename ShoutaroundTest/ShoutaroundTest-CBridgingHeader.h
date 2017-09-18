//
//  ShoutaroundTest-CBridgingHeader.h
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 9/17/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

#ifndef ShoutaroundTest_CBridgingHeader_h
#define ShoutaroundTest_CBridgingHeader_h
#import <Foundation/Foundation.h>
#import <mailgun/Mailgun.h>


@interface mailTest: NSObject
- (void) sendMail: (NSString*)email;

@end



#endif /* ShoutaroundTest_CBridgingHeader_h */
