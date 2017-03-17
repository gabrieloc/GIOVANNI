/*
 Copyright (c) 2010, OpenEmu Team
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 * Neither the name of the OpenEmu Team nor the
 names of its contributors may be used to endorse or promote products
 derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY OpenEmu Team ''AS IS'' AND ANY
 EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL OpenEmu Team BE LIABLE FOR ANY
 DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "OETimingUtils.h"
#include <mach/mach_time.h>
#include <mach/mach_init.h>
#include <mach/thread_policy.h>
#include <mach/thread_act.h>
#include <pthread.h>

static double mach_to_sec = 0;

static void init_mach_time(void)
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		struct mach_timebase_info base;
		mach_timebase_info(&base);
		mach_to_sec = 1e-9 * (base.numer / (double)base.denom);
	});
}

NSTimeInterval OEMonotonicTime(void)
{
	init_mach_time();
	
	return mach_absolute_time() * mach_to_sec;
}

void OEWaitUntil(NSTimeInterval time)
{
	init_mach_time();
	
	mach_wait_until(time / mach_to_sec);
}

BOOL OESetThreadRealtime(NSTimeInterval period, NSTimeInterval computation, NSTimeInterval constraint)
{
	struct thread_time_constraint_policy ttcpolicy;
	thread_port_t threadport = pthread_mach_thread_np(pthread_self());
	
	init_mach_time();
	
	assert(computation < .05);
	assert(computation < constraint);
	
	ttcpolicy.period      = period / mach_to_sec;
	ttcpolicy.computation = computation / mach_to_sec;
	ttcpolicy.constraint  = constraint / mach_to_sec;
	ttcpolicy.preemptible = 1;
	
	if(thread_policy_set(threadport,
						 THREAD_TIME_CONSTRAINT_POLICY, (thread_policy_t)&ttcpolicy,
						 THREAD_TIME_CONSTRAINT_POLICY_COUNT) != KERN_SUCCESS)
	{
		NSLog(@"OESetThreadRealtime() failed.");
		return NO;
	}
	
	return YES;
}
