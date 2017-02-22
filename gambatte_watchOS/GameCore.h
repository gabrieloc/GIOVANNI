//
//  GameCore.h
//  watchGB
//
//  Created by Gabriel O'Flaherty-Chan on 2017-03-05.
//  Copyright © 2017 Gabrieloc. All rights reserved.
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

- (void)startEmulation;
- (void)stopEmulation;
- (void)resetEmulation;

- (void)loadFileAtPath:(NSString *)path success:(void (^_Nullable)(GameCore *))success failure:(void (^_Nullable)(NSError *))failure;
- (oneway void)updateInput:(GameInput)input selected:(BOOL)selected;

- (void)loadFromSlot:(NSInteger)slot;
- (void)saveToSlot:(NSInteger)slot;

@end

NS_ASSUME_NONNULL_END
