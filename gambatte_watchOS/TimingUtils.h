//
//  TimingUtils.h
//  watchGB
//
//  Created by Gabriel O'Flaherty-Chan on 2017-03-06.
//  Copyright © 2017 Gabrieloc. All rights reserved.
//

#import <Foundation/Foundation.h>

__BEGIN_DECLS

NSTimeInterval OEMonotonicTime(void);
void OEWaitUntil(NSTimeInterval time);
BOOL OESetThreadRealtime(NSTimeInterval period, NSTimeInterval computation, NSTimeInterval constraint);

__END_DECLS
