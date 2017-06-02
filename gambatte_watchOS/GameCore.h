//
//  GameCore.h
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

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSInteger, GameInput) {
	GameInputA		= 1 << 0,
	GameInputB		= 1 << 1,
	GameInputSelect	= 1 << 2,
	GameInputStart	= 1 << 3,
	GameInputRight	= 1 << 4,
	GameInputLeft	= 1 << 5,
	GameInputUp		= 1 << 6,
	GameInputDown	= 1 << 7
};

static int const kScreenWidth = 160;
static int const kScreenHeight = 144;

@interface GameCore : NSObject {
	NSInteger frameInterval;
	BOOL isPaused;
}

@property (strong, nonatomic) NSURL *workingDirectory;
@property (nonatomic, strong) void (^didRender)(uint32_t *);
@property (nonatomic) uint32_t *activeInput;
@property (nonatomic) BOOL paused;

@property (nonatomic) BOOL enableFrameSkip;

- (void)startEmulation;
- (void)stopEmulation;
- (void)resetEmulation;

- (void)loadFileAtPath:(NSString *)path success:(void (^_Nullable)(GameCore *))success failure:(void (^_Nullable)(NSError *))failure;
- (oneway void)updateInput:(GameInput)input selected:(BOOL)selected;

- (void)loadFromSlot:(NSInteger)slot;
- (void)saveToSlot:(NSInteger)slot;
- (void)saveSavedata;

- (void)runWhilePaused:(void (^)())block;

@end

NS_ASSUME_NONNULL_END
