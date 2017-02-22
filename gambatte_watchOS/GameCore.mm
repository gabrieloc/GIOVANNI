//
//  GameCore.m
//  watchGB
//
//  Created by Gabriel O'Flaherty-Chan on 2017-03-05.
//  Copyright © 2017 Gabrieloc. All rights reserved.
//

#import "GameCore.h"
#include "TimingUtils.h"

#include "gambatte.h"

gambatte::GB gb;

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
	BOOL running;
}

- (instancetype)init
{
	self = [super init];
	if (self) {
		videoBuffer = (uint32_t *)malloc(kScreenWidth * kScreenHeight * 4);
		unusedBuffer = (uint32_t *)malloc(2064 * 2 * 4);
	}
	return self;
}

- (void)dealloc
{
	free(videoBuffer);
	free(unusedBuffer);
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
//	NSTimeInterval interval = 1 / (frameInterval * 0.5);
//	updateTimer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(runGameLoop) userInfo:nil repeats:YES];

	running = YES;
	gameCoreThread = [[NSThread alloc] initWithTarget:self selector:@selector(runGameLoop) object:nil];
	gameCoreThread.name = @"watchGB Game Core";
	gameCoreThread.qualityOfService = NSQualityOfServiceUserInteractive;
	[gameCoreThread start];
}

- (void)runGameLoop
{
	NSTimeInterval realTime, emulatedTime = OEMonotonicTime();
	
	OESetThreadRealtime(1. / (1. * frameInterval), .007, .03);
	
	while (running) {
		@autoreleasepool {
		size_t samples = 2064;
		
		while (gb.runFor((gambatte::uint_least32_t *)videoBuffer, kScreenWidth,
						 (gambatte::uint_least32_t *)unusedBuffer, samples) == -1 && running) {
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
	}
}
}

- (void)stopEmulation
{
	gb.saveSavedata();
	//	[updateTimer invalidate];
	running = NO;
	[gameCoreThread cancel];
}

- (void)resetEmulation
{
	[self stopEmulation];
	
	free(videoBuffer);
	free(unusedBuffer);
	videoBuffer = (uint32_t *)malloc(kScreenWidth * kScreenHeight * 4);
	unusedBuffer = (uint32_t *)malloc(2064 * 2 * 4);
	
	gb.reset();
	[self startEmulation];
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

- (void)saveToSlot:(NSInteger)slot
{
	gb.saveSavedata();
	gb.selectState(slot);
	if (!gb.saveState((gambatte::uint_least32_t *)videoBuffer, kScreenWidth)) {
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
