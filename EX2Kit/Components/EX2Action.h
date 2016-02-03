//
//  EX2Operation.h
//  EX2Kit
//
//  Created by Benjamin Baron on 5/23/13.
//
//

#import "EX2ActionQueue.h"

typedef NS_ENUM(NSInteger, EX2ActionState)
{
    EX2ActionState_NotQueued,
    EX2ActionState_Waiting,
    EX2ActionState_Running,
    EX2ActionState_Failed,
    EX2ActionState_Completed,
    EX2ActionState_Cancelled
};

@class EX2ActionQueue;
@protocol EX2Action <NSObject>

@required
@property (weak) EX2ActionQueue *actionQueue;
@property EX2ActionState actionState;
- (void)runAction;
- (BOOL)cancelAction;

@end
