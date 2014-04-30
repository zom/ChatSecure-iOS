//
//  OTRBuddy.m
//  Off the Record
//
//  Created by David Chiles on 3/28/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRBuddy.h"
#import "OTRAccount.h"
#import "OTRMessage.h"
#import "OTRDatabaseManager.h"
#import "YapDatabaseRelationshipTransaction.h"
#import "OTRKit.h"

const struct OTRBuddyAttributes OTRBuddyAttributes = {
	.username = @"username",
	.displayName = @"displayName",
	.composingMessageString = @"composingMessageString",
	.statusMessage = @"statusMessage",
	.chatState = @"chatState",
	.lastSentChatState = @"lastSentChatState",
	.status = @"status",
    .lastMessageDate = @"lastMessageDate",
    .avatarData = @"avatarData",
    .encryptionStatus = @"encryptionStatus"
};

const struct OTRBuddyRelationships OTRBuddyRelationships = {
	.accountUniqueId = @"accountUniqueId",
};

const struct OTRBuddyEdges OTRBuddyEdges = {
	.account = @"account",
};

@implementation OTRBuddy

- (id)init
{
    if (self = [super init]) {
        self.status = OTRBuddyStatusOffline;
        self.chatState = kOTRChatStateUnknown;
        self.lastSentChatState = kOTRChatStateUnknown;
        self.encryptionStatus = kOTRKitMessageStatePlaintext;
    }
    return self;
}

- (UIImage *)avatarImage
{
    return [UIImage imageWithData:self.avatarData];
}


- (BOOL)hasMessagesWithTransaction:(YapDatabaseReadTransaction *)transaction
{
    NSUInteger numberOfMessages = [[transaction ext:OTRYapDatabaseRelationshipName] edgeCountWithName:OTRMessageEdges.buddy destinationKey:self.uniqueId collection:[OTRBuddy collection]];
    return (numberOfMessages > 0);
}

- (NSInteger)numberOfUnreadMessagesWithTransaction:(YapDatabaseReadTransaction *)transaction
{
    __block NSUInteger count = 0;
    [[transaction ext:OTRYapDatabaseRelationshipName] enumerateEdgesWithName:OTRMessageEdges.buddy destinationKey:self.uniqueId collection:[OTRBuddy collection] usingBlock:^(YapDatabaseRelationshipEdge *edge, BOOL *stop) {
        OTRMessage *message = [OTRMessage fetchObjectWithUniqueID:edge.sourceKey transaction:transaction];
        if (!message.isRead) {
            count += 1;
        }
    }];
    return count;
}

- (OTRAccount*)accountWithTransaction:(YapDatabaseReadTransaction *)transaction
{
    return [OTRAccount fetchObjectWithUniqueID:self.accountUniqueId transaction:transaction];
}

- (void)setAllMessagesRead:(YapDatabaseReadWriteTransaction *)transaction
{
    [[transaction ext:OTRYapDatabaseRelationshipName] enumerateEdgesWithName:OTRMessageEdges.buddy destinationKey:self.uniqueId collection:[OTRBuddy collection] usingBlock:^(YapDatabaseRelationshipEdge *edge, BOOL *stop) {
        OTRMessage *message = [[OTRMessage fetchObjectWithUniqueID:edge.sourceKey transaction:transaction] copy];
        
        if (!message.isRead) {
            message.read = YES;
            [message saveWithTransaction:transaction];
        }
    }];
}
- (OTRMessage *)lastMessageWithTransaction:(YapDatabaseReadTransaction *)transaction
{
    __block OTRMessage *finalMessage = nil;
    [[transaction ext:OTRYapDatabaseRelationshipName] enumerateEdgesWithName:OTRMessageEdges.buddy destinationKey:self.uniqueId collection:[OTRBuddy collection] usingBlock:^(YapDatabaseRelationshipEdge *edge, BOOL *stop) {
        OTRMessage *message = [OTRMessage fetchObjectWithUniqueID:edge.sourceKey transaction:transaction];
        if (!finalMessage ||    [message.date compare:finalMessage.date] == NSOrderedDescending) {
            finalMessage = message;
        }
        
    }];
    return [finalMessage copy];
}

#pragma - mark Class Methods

+ (instancetype)fetchBuddyWithUsername:(NSString *)username withAccountUniqueId:(NSString *)accountUniqueId transaction:(YapDatabaseReadTransaction *)transaction
{
    __block OTRBuddy *finalBuddy = nil;
    
    [[transaction ext:OTRYapDatabaseRelationshipName] enumerateEdgesWithName:OTRBuddyEdges.account destinationKey:accountUniqueId collection:[OTRAccount collection] usingBlock:^(YapDatabaseRelationshipEdge *edge, BOOL *stop) {
        OTRBuddy * buddy = [transaction objectForKey:edge.sourceKey inCollection:[OTRBuddy collection]];
        if ([buddy.username isEqualToString:username]) {
            *stop = YES;
            finalBuddy = buddy;
        }
    }];
    
    return [finalBuddy copy];
}

#pragma - mark YapDatabaseRelationshipNode

- (NSArray *)yapDatabaseRelationshipEdges
{
    NSArray *edges = nil;
    if (self.accountUniqueId) {
        YapDatabaseRelationshipEdge *accountEdge = [YapDatabaseRelationshipEdge edgeWithName:OTRBuddyEdges.account
                                                                              destinationKey:self.accountUniqueId
                                                                                  collection:[OTRAccount collection]
                                                                             nodeDeleteRules:YDB_DeleteSourceIfDestinationDeleted];
        edges = @[accountEdge];
    }
    
    
    return edges;
}

@end