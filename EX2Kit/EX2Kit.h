//
//  EX2Kit.h
//  EX2Kit
//
//  Created by Ben Baron on 6/14/12.
//  Copyright (c) 2012 Anghami. All rights reserved.
//

#ifndef EX2Kit_EX2Kit_h
#define EX2Kit_EX2Kit_h

#import "EX2Macros.h"
#import "EX2Categories.h"
#import "EX2Static.h"
#import "EX2Components.h"

#ifdef TVOS
    #import "DDLog.h"
    #import "UIDevice+Hardware.h"
#else
    #ifdef IOS
        #import "EX2UIComponents.h"
        #import "CocoaLumberjack.h"
    #endif
#endif



@interface EX2Kit : NSObject

+ (NSBundle *)resourceBundle;

@end

#endif
