//
//  OTRXMPPMessageYapStroage.h
//  ChatSecure
//
//  Created by David Chiles on 8/13/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "XMPPModule.h"
#import "YapDatabaseConnection.h"
@class XMPPMessage;

@interface OTRXMPPMessageYapStroage : XMPPModule

@property (nonatomic, strong, readonly) YapDatabaseConnection *databaseConnection;
@property (nonatomic, readonly) dispatch_queue_t moduleDelegateQueue;

- (instancetype)initWithDatabaseConnection:(YapDatabaseConnection *)connection;

@end
