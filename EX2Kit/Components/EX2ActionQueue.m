//
//  EX2ActionQueue.m
//  EX2Kit
//
//  Created by Benjamin Baron on 5/23/13.
//
//

#import "EX2ActionQueue.h"

@interface EX2ActionQueue()
@property (nonatomic, strong) NSMutableArray *actionQueue;
@property (nonatomic) NSInteger absoluteActionCount;
@end

@implementation EX2ActionQueue

- (id)init
{
    if ((self = [super init]))
    {
        _actionQueue = [NSMutableArray arrayWithCapacity:0];
        _numberOfConcurrentActions = 1;
    }
    return self;
}

- (void)setQueueState:(EX2ActionQueueState)queueState
{
    if (_queueState == queueState) {
        return;
    }
    EX2ActionQueueState oldState = _queueState;
    _queueState = queueState;
    [self.delegate actionQueue:self stateChangedFrom:oldState to:queueState];
}

- (NSArray *)runningActions
{
    @synchronized(self.actionQueue)
    {        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"actionState == %u", EX2ActionState_Running];
        return [self.actionQueue filteredArrayUsingPredicate:predicate];
    }
}

- (NSArray *)waitingActions
{
    @synchronized(self.actionQueue)
    {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"actionState == %u", EX2ActionState_Waiting];
        return [self.actionQueue filteredArrayUsingPredicate:predicate];
    }
}

- (NSArray *)actions
{
    @synchronized(self.actionQueue)
    {                     
        return [NSArray arrayWithArray:self.actionQueue];
    }
}

- (NSUInteger)actionCount
{    
    @synchronized(self.actionQueue)
    {
        return self.actionQueue.count;
    }
}

- (BOOL)isActionInQueue:(id<EX2Action>)action
{
    @synchronized(self.actionQueue)
    {
        return [self.actionQueue containsObject:action];
    }
}

- (BOOL)isActionOfTypeInQueue:(Class)type
{
    @synchronized(self.actionQueue)
    {
        for (id object in self.actionQueue)
        {
            if ([object isKindOfClass:type])
            {
                return YES;
            }
        }
        return NO;
    }
}

- (void)startQueue
{
    @synchronized(self.actionQueue)
    {
        if (self.queueState == EX2ActionQueueState_Started)
            return;
        
        self.queueState = EX2ActionQueueState_Started;
    }
    
    [self runNextActions];
}

- (void)stopQueue:(BOOL)cancelRunningActions
{
    @synchronized(self.actionQueue)
    {
        if (self.queueState != EX2ActionQueueState_Started)
            return;
    }
    
    NSArray *actionsToCancel;
    @synchronized(self.actionQueue)
    {
        
        actionsToCancel = self.runningActions;
        
        self.queueState = EX2ActionQueueState_Stopped;
    }

    // Cancel the running actions if needed
    if (cancelRunningActions)
    {
        for (id<EX2Action> action in actionsToCancel)
        {
            [action cancelAction];
        }
    }
}

- (void)clearQueue
{
    // Reset the queue state
    @synchronized(self.actionQueue)
    {
        self.queueState = EX2ActionQueueState_NotStarted;
    }
    
    // Cancel all the running actions
    for (id<EX2Action> action in self.runningActions)
    {
        [self cancelAction:action];
    }
    
    // Remove the remaining actions
    @synchronized(self.actionQueue)
    {
        for (id<EX2Action> action in self.actions)
        {
            action.actionState = EX2ActionState_Cancelled;
            [_actionQueue removeObjectIdenticalTo:action];
        }
        [_actionQueue removeAllObjects];
    }
}

- (void)queueAction:(id<EX2Action>)action
{
    if (!action)
        return;
    
    @synchronized(self.actionQueue)
    {
        action.actionQueue = self;
        action.actionState = EX2ActionState_Waiting;
        [self.actionQueue addObject:action];
    }
}

// Return value indicates whether the action was cancellable
- (BOOL)cancelAction:(id<EX2Action>)action
{
    @synchronized(self.actionQueue)
    {
        // Set the state
        action.actionState = EX2ActionState_Cancelled;
        action.actionQueue = nil;
        
        // Remove the object from the queue
        if (action)
        {
            [self.actionQueue removeObjectIdenticalTo:action];
        }
        
        // Attempt to cancel the action
        return [action cancelAction];
    }
}

- (void)actionFailed:(id<EX2Action>)action
{
    BOOL fatal = [action respondsToSelector:@selector(isFailureFatal)] && [action isFailureFatal];
    @synchronized(self.actionQueue)
    {
        // Set the action state to failed
        action.actionState = EX2ActionState_Failed;
        action.actionQueue = nil;
        
        // For now just remove from the queue and start the next action, later we'll add automatic retrying
        if (action)
        {
            [self.actionQueue removeObjectIdenticalTo:action];
        }
    }
    if (fatal) {
        [self clearQueue];
    }
    // Run the next actions if needed
    [self runNextActions];
}

- (void)actionFinished:(id<EX2Action>)action
{
    if (!action)
        return;
    
    @synchronized(self.actionQueue)
    {
        // Set the action state to completed
        action.actionState = EX2ActionState_Completed;
        action.actionQueue = nil;
        
        // Remove from the queue and start the next action
        [self.actionQueue removeObjectIdenticalTo:action];
    }
    
    // Run the next actions if needed
    [self runNextActions];
}

- (NSString *)getTagFromAction:(NSObject *)action
{
    @synchronized (self.actionQueue) {
        NSString * KEY = @"action_queue_id";
        NSString * actionId = [action ex2CustomObjectForKey:KEY];
        if (!actionId) {
            actionId = @(self.absoluteActionCount++).stringValue;
            [action ex2SetCustomObject:actionId forKey:KEY];
        }
        return actionId;
    }
}

- (void)runNextActions
{
    // Run the next action if needed
    if (self.queueState == EX2ActionQueueState_Started)
    {
        NSMutableArray *nextActions = [NSMutableArray arrayWithCapacity:self.numberOfConcurrentActions];
        @synchronized(self.actionQueue)
        {
            //DDLogVerbose(@"[EX2ActionQueue] runNextActions, queue: %@", self.actionQueue);
            
            NSUInteger numberOfRunningActions = self.runningActions.count;
            if (numberOfRunningActions < self.numberOfConcurrentActions)
            {
                NSMutableSet * seen = [[NSMutableSet alloc] init];
                for (id<EX2Action> action in self.actionQueue)
                {
                    [seen addObject:[self getTagFromAction:action]];
                    if ([action respondsToSelector:@selector(blockedBy)]) {
                        BOOL blocked = NO;
                        for (id<EX2Action> blocker in action.blockedBy) {
                            NSString * tag = [self getTagFromAction:blocker];
                            if ([seen containsObject:tag]) {
                                blocked = YES;
                                break;
                            }
                        }
                        if (blocked) {
                            continue;
                        }
                    }
                    if (action.actionState == EX2ActionState_Waiting)
                    {
                        [nextActions addObject:action];
                    }
                    
                    if (nextActions.count + numberOfRunningActions >= self.numberOfConcurrentActions)
                    {
                        break;
                    }
                }
            }            
        }
        // Start the actions
        for (id<EX2Action> action in nextActions)
        {
            action.actionState = EX2ActionState_Running;
            [EX2Dispatch runInMainThreadAfterDelay:self.delayBetweenActions block:^{
                [action runAction];
            }];
        }
        
        @synchronized(self.actionQueue)
        {
            if (nextActions.count == 0 && self.runningActions.count == 0)
            {
                // We're done, so set the state
                self.queueState = EX2ActionQueueState_Finished;
            }
        }
    }
}

@end
