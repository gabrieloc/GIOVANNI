//
//  GameCore.m
//  GIOVANNI
//
//  Copyright (c) <2017>, Gabriel O'Flaherty-Chan
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//  1. Redistributions of source code must retain the above copyright
//  notice, this list of conditions and the following disclaimer.
//  2. Redistributions in binary form must reproduce the above copyright
//  notice, this list of conditions and the following disclaimer in the
//  documentation and/or other materials provided with the distribution.
//  3. All advertising materials mentioning features or use of this software
//  must display the following acknowledgement:
//  This product includes software developed by skysent.
//  4. Neither the name of the skysent nor the
//  names of its contributors may be used to endorse or promote products
//  derived from this software without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY skysent ''AS IS'' AND ANY
//  EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL skysent BE LIABLE FOR ANY
//  DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import "GameCore.h"
#include "OETimingUtils.h"

#include "gambatte.h"

uint32_t activeInput[8];

class GetInput : public gambatte::InputGetter
{
public:
	unsigned operator()()
	{
		return activeInput[0];
	}
} static GetInput;

@implementation GameCore {
	NSThread *gameCoreThread;
	uint32_t *videoBuffer;
	uint32_t *unusedBuffer;
	NSTimer *updateTimer;
	gambatte::GB gb;
}

- (void)dealloc
{
	[self stopEmulation];
}

- (void)loadFileAtPath:(NSString *)path success:(void (^)(GameCore * _Nonnull))success failure:(void (^)(NSError * _Nonnull))failure
{
	memset(activeInput, 0, sizeof(uint32_t) * 8);
	
	double fps = 4194304.0 / 70224.0; // ~60fps
	frameInterval = fps;
	
	NSURL *batterySavesDirectory = _workingDirectory;
	
	[[NSFileManager defaultManager] createDirectoryAtURL:batterySavesDirectory withIntermediateDirectories:YES attributes:nil error:nil];
	gb.setSaveDir([[batterySavesDirectory path] UTF8String]);
	gb.setInputGetter(&GetInput);
	if (gb.load([path UTF8String]) != 0) {
		NSMutableDictionary *errorUserInfo = [NSMutableDictionary dictionary];
		NSString *errorMessage = [NSString stringWithFormat:@"Error loading at %@", path];
		errorUserInfo[NSLocalizedDescriptionKey] = errorMessage;
		NSError *error = [NSError errorWithDomain:@"GameCore" code:9999 userInfo:errorUserInfo];
		failure(error);
	} else {
		success(self);
	}
}

- (void)startEmulation
{
	// Using a Timer instead to trigger the game loop is slower, but ensures all frames are rendered
	// TODO use enableFrameSkip property to switch betwen timer and NSThread
//	NSTimeInterval interval = 1 / (frameInterval * 0.5);
//	updateTimer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(runGameLoop) userInfo:nil repeats:YES];

	videoBuffer = (uint32_t *)malloc(kScreenWidth * kScreenHeight * 4);
	unusedBuffer = (uint32_t *)malloc(2064 * 2 * 4);
	
	_paused = NO;
	gameCoreThread = [[NSThread alloc] initWithTarget:self selector:@selector(runGameLoop) object:nil];
	gameCoreThread.name = @"Giovanni Game Core";
	gameCoreThread.qualityOfService = NSQualityOfServiceUserInteractive;
	[gameCoreThread start];
}

- (void)runGameLoop
{
	NSTimeInterval realTime, emulatedTime = OEMonotonicTime();
	
	OESetThreadRealtime(1. / (1. * frameInterval), .007, .03);
	
	while (!gameCoreThread.isCancelled) { @autoreleasepool {
		if (!gameCoreThread) {
			return;
		}

		size_t samples = 2064;

		while (gb.runFor((gambatte::uint_least32_t *)videoBuffer, kScreenWidth,
						 (gambatte::uint_least32_t *)unusedBuffer, samples) == -1 && !_paused) {
			
		}
		
		NSTimeInterval advance = 1.0 / (1. * frameInterval);
		
		emulatedTime += advance;
		realTime = OEMonotonicTime();
		
		if(realTime - emulatedTime > 1.0) {
			NSLog(@"Synchronizing because we are %g seconds behind", realTime - emulatedTime);
			emulatedTime = realTime;
		}
		OEWaitUntil(emulatedTime);
		CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0, 0);
		
		
		if (_didRender != nil) {
			_didRender(videoBuffer);
		}
	}}
}

- (void)stopEmulation
{
	if (gameCoreThread == nil) {
		return;
	}
	
	gb.saveSavedata();
	_paused = YES;
	[gameCoreThread cancel];
	gameCoreThread = nil;

	free(videoBuffer);
	free(unusedBuffer);

	videoBuffer = nil;
	unusedBuffer = nil;
}

- (void)resetEmulation
{
	[self stopEmulation];
	gb.reset();
	[self startEmulation];
}

- (void)saveSavedata
{
	gb.saveSavedata();
}

- (void)runWhilePaused:(void (^)())block
{
	self.paused = true;
	block();
	self.paused = false;
}

#pragma mark - Input

- (oneway void)updateInput:(GameInput)input selected:(BOOL)selected
{
	if (selected) {
		activeInput[0] |= input;
	} else {
		activeInput[0] &= ~input;
	}
}

#pragma mark - Save

- (uint32_t *)activeInput
{
	return activeInput;
}

- (void)saveData
{
	gb.saveSavedata();
}

- (void)saveToSlot:(NSInteger)slot
{
	gb.saveSavedata();
	gb.selectState(slot);
	int saved = gb.saveState(0, 0);
	if (saved != 1) {
		NSLog(@"Error saving to slot %@", @(slot));
	}
}

- (void)loadFromSlot:(NSInteger)slot
{
	gb.selectState(slot);
	if (!gb.loadState()) {
		NSLog(@"Error loading from slot %@", @(slot));
	}
}

@end
