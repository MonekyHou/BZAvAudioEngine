//
//  BZAVAudioEngine.h
//  BZAvAudioEngine
//
//  Created by Monkey on 2020/11/5.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BZAVAudioEngine : NSObject

@property(nonatomic,strong)AVAudioEngine *audioEngine;

@property(nonatomic,strong)AVAudioPlayerNode *playerNode;

@property(nonatomic,strong)AVAudioMixerNode *mixerNode;


///音频链接
@property(nonatomic,strong)NSURL *musicUrl;


///总时长
@property(nonatomic,assign)CGFloat musicTotalTime;

///当前播放时间
@property (nonatomic, assign) NSTimeInterval currentTime;

///
@property(nonatomic,assign)float currentVolume;

@property(nonatomic,strong)NSMutableArray *leftChannelArray;
@property(nonatomic,strong)NSMutableArray *rightChannelArray;


+ (BZAVAudioEngine *)shareAudioEngine;

///初始化
- (void)initAudioEngine;

///开始录音
- (void)startRecord;

///停止录音
- (void)stopAudioEngine;

///开始播放文件
- (void)playAudioEngine;

///开始播放buffer
- (void)playBufferAudioEngine;

///停止播放
- (void)playStopAudioEngine;

///初始化播放
- (void)initPlayer;

///暂停播放
- (void)playerPause;

///开始播放
- (void)playerPlay;

///定时器片段播放
- (void)catchCurrentTime;

///获取音频的总时长
- (CGFloat)homeMusicTotalTime;


@end

NS_ASSUME_NONNULL_END
