//
//  BZAVAudioEngine.m
//  BZAvAudioEngine
//
//  Created by Monkey on 2020/11/5.
//

#import "BZAVAudioEngine.h"

#import "BZAvAudioEngine-Swift.h"

@interface BZAVAudioEngine ()

@property(nonatomic,strong)AVAudioTime *currentAudioTime;

@property(nonatomic,assign)double sampleRate;
@property(nonatomic,strong)AVAudioFile *audioFile;
@property (nonatomic, assign, getter=isPlaying) BOOL playing;
@property(nonatomic,assign)AVAudioFramePosition lastStartFramePosition;
@property(nonatomic,strong)RealTimeAnalyzer *realTimeData;

@end

static BZAVAudioEngine *bzAudioEngine;

@implementation BZAVAudioEngine

+ (BZAVAudioEngine *)shareAudioEngine
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        bzAudioEngine = [[BZAVAudioEngine alloc]init];
    });
    return bzAudioEngine;
}

- (void)initAudioEngine
{
    //耳返
//    [self.audioEngine connect:self.audioEngine.inputNode to:self.audioEngine.outputNode format:[self.audioEngine.inputNode inputFormatForBus:AVAudioPlayerNodeBufferLoops]];
    ///防止录音后播放声音变小
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [session setActive:YES error:nil];
    
    [self playStopAudioEngine];
    
    ///存文件
    [self loadEngineData];
}

///开始录音
- (void)startRecord
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.audioEngine prepare];
        NSError *error;
        if ([self.audioEngine startAndReturnError:&error]) {
            //错误
            return;
        }
    });
    
}

- (void)stopAudioEngine
{
    //此处需要恢复设置回放标志，否则会导致其它播放声音也会变小
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayback error:nil];
    [session setActive:YES error:nil];
    
    if (self.audioEngine.isRunning) {
        [self.mixerNode removeTapOnBus:0];
        [self.audioEngine stop];
    }
    if (self.playerNode.isPlaying) {
        [self.playerNode removeTapOnBus:0];
        [self.playerNode stop];
    }
    NSError *error;
    self.audioFile = [[AVAudioFile alloc] initForReading:self.musicUrl error:&error];
    ///获取总时长
    AVAudioFrameCount frameCount = (AVAudioFrameCount)self.audioFile.length;
    self.sampleRate = self.audioFile.processingFormat.sampleRate;
    if (self.sampleRate != 0) {
        self.musicTotalTime = frameCount / self.sampleRate;
        NSLog(@"%f\n",self.musicTotalTime);
    }
}

- (void)loadEngineData
{
    NSDictionary *settings = [[NSDictionary alloc] initWithObjectsAndKeys:
                                  [NSNumber numberWithFloat:44100.0],AVSampleRateKey ,    //采样率 8000/44100/96000
                                  [NSNumber numberWithInt:kAudioFormatMPEG4AAC],AVFormatIDKey,  //录音格式
                                  [NSNumber numberWithInt:16],AVLinearPCMBitDepthKey,   //线性采样位数  8、16、24、32
                                  [NSNumber numberWithInt:2],AVNumberOfChannelsKey,      //声道 1，2
                                  [NSNumber numberWithInt:AVAudioQualityMedium],AVEncoderAudioQualityKey, //录音质量
                                  nil];
    AVAudioFile *file = [[AVAudioFile alloc] initForWriting:self.musicUrl
                                                       settings:settings
                                                          error:nil];
    [self.audioEngine attachNode:self.mixerNode];
    [self.audioEngine connect:self.audioEngine.inputNode to:self.mixerNode format:nil];
    
    [self.mixerNode removeTapOnBus:0];
    if (self.playerNode.isPlaying) {
        [self.playerNode removeTapOnBus:0];
    }
    
    [self.mixerNode installTapOnBus:0 bufferSize:1024 format:nil  block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
        [file writeFromBuffer:buffer error:nil];
        ///获取音量大小做动画
        float *buffdata = buffer.floatChannelData[0];
        for (int i = 0; i < buffer.frameLength; i++) {
            self.currentVolume = fabs(buffdata[i]);
        }
    }];
}

///播放整个文件
- (void)playAudioEngine
{
    NSError *error;
    self.audioFile = [[AVAudioFile alloc] initForReading:self.musicUrl error:&error];
    [self.audioEngine attachNode:self.playerNode];
    [self.audioEngine connect:self.playerNode to:self.audioEngine.mainMixerNode format:self.audioFile.processingFormat];
    [self.playerNode scheduleFile:self.audioFile atTime:nil completionHandler:^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (self.audioEngine.isRunning) {
                [self.audioEngine stop];
            }
        });
    }];
    [self.audioEngine prepare];
    [self.audioEngine startAndReturnError:&error];
    if (error) {
        NSLog(@"%@", [error localizedDescription]);
    }
    [self.playerNode play];
}

///开始播放buffer
- (void)playBufferAudioEngine
{
    NSError *error;
    AVAudioFile *file = [[AVAudioFile alloc] initForReading:self.musicUrl error:&error];
    if (error) {
        NSLog(@"%@", [error localizedDescription]);
        return;
    }
    
    AVAudioPCMBuffer *totalBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:file.processingFormat
                                                             frameCapacity:(AVAudioFrameCount)(file.length)];
    [file readIntoBuffer:totalBuffer error:&error];
    if (error) {
        NSLog(@"%@", [error localizedDescription]);
        return;
    }
    [self.audioEngine attachNode:self.playerNode];
    [self.audioEngine connect:self.playerNode to:self.audioEngine.mainMixerNode format:file.processingFormat];
    [self.playerNode scheduleBuffer:totalBuffer completionHandler:^{
        
    }];
    [self.audioEngine.mainMixerNode installTapOnBus:0 bufferSize:1024 format:nil block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
        
    }];
    
    [self.audioEngine prepare];
    [self.audioEngine startAndReturnError:&error];
    
    [self.playerNode play];
}

///初始化播放
- (void)initPlayer
{
    NSError *error;
    self.audioFile = [[AVAudioFile alloc] initForReading:self.musicUrl error:&error];
    if (error) {
        NSLog(@"%@", [error localizedDescription]);
        return;
    }
    
    AVAudioPCMBuffer *totalBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:self.audioFile.processingFormat
                                                             frameCapacity:(AVAudioFrameCount)(self.audioFile.length)];
    [self.audioFile readIntoBuffer:totalBuffer error:&error];
    if (error) {
        NSLog(@"%@", [error localizedDescription]);
        return;
    }
    [self.audioEngine attachNode:self.playerNode];
    
    [self.audioEngine connect:self.playerNode to:self.audioEngine.mainMixerNode format:self.audioFile.processingFormat];
    
    [self.audioEngine prepare];
    [self.audioEngine startAndReturnError:&error];
    
}

- (void)catchCurrentTime
{
    if (self.isPlaying) {
        AVAudioTime *playerTime = [self.playerNode playerTimeForNodeTime:self.playerNode.lastRenderTime];
        _currentTime = (self.lastStartFramePosition + playerTime.sampleTime) / playerTime.sampleRate;
    }
    if (self.currentTime > self.musicTotalTime) {
        [self playStopAudioEngine];
        //播放完毕
    }
}

///暂停播放
- (void)playerPause
{
    ///这里要stop  不然先播放后录制会有erro
    [self.audioEngine stop];
    [self.playerNode pause];
}

///开始播放
- (void)playerPlay{
    if (!self.audioEngine.isRunning) {
        [self.audioEngine prepare];
        [self.audioEngine startAndReturnError:nil];
    }
    
    [self.playerNode play];
    [self.playerNode removeTapOnBus:0];
    @weakify(self);
    [self.playerNode installTapOnBus:0 bufferSize:1024 format:nil block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
        @strongify(self);
        NSArray *amplitudes =  [self.realTimeData loadanalyseWith:buffer];
        self.leftChannelArray = [NSMutableArray arrayWithArray:amplitudes[0]];
        if (amplitudes.count >= 2) {
            self.rightChannelArray = [NSMutableArray arrayWithArray:amplitudes[1]];
        }
    }];
}


///停止播放
- (void)playStopAudioEngine
{
    if (self.playerNode.isPlaying) {
        [self.playerNode removeTapOnBus:0];
        [self.playerNode stop];
    }
    if (self.audioEngine.isRunning) {
        [self.audioEngine stop];
    }
}

- (AVAudioEngine *)audioEngine
{
    if (!_audioEngine) {
        _audioEngine = [[AVAudioEngine alloc]init];
    }
    return _audioEngine;
}

- (AVAudioPlayerNode *)playerNode
{
    if (!_playerNode) {
        _playerNode = [[AVAudioPlayerNode alloc]init];
    }
    return _playerNode;
}

- (AVAudioMixerNode *)mixerNode
{
    if (!_mixerNode) {
        _mixerNode = [[AVAudioMixerNode alloc]init];
        _mixerNode.volume = 1;
        _mixerNode.outputVolume = 1;
    }
    return _mixerNode;
}

- (NSMutableArray *)leftChannelArray
{
    if (!_leftChannelArray) {
        _leftChannelArray = [NSMutableArray array];
    }
    return _leftChannelArray;
}

- (NSMutableArray *)rightChannelArray
{
    if (!_rightChannelArray) {
        _rightChannelArray = [NSMutableArray array];
    }
    return _rightChannelArray;
}

- (void)setCurrentTime:(NSTimeInterval)currentTime
{
    _currentTime = currentTime;
    [self.playerNode stop];
    AVAudioFramePosition startingFrame = currentTime * self.audioFile.processingFormat.sampleRate;
    // 要根据总时长和当前进度，找出起始的frame位置和剩余的frame数量
    AVAudioFrameCount frameCount = (AVAudioFrameCount)(self.audioFile.length - startingFrame);
    NSLog(@"%lld==%u\n",startingFrame,frameCount);
    if (frameCount > 0) { // 当剩余数量小于0时会crash
        self.lastStartFramePosition = startingFrame;
        [self.playerNode scheduleSegment:self.audioFile startingFrame:startingFrame frameCount:frameCount atTime:nil completionHandler:^{
            [self didFinishPlay];
        }];
    }
    if (self.isPlaying) {
        [self.playerNode play];
    }
}


//- (NSURL *)musicUrl
//{
//    NSFileManager *fm = [NSFileManager defaultManager];
//    NSURL *doc = [fm URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];
//    _musicUrl = [doc URLByAppendingPathComponent:@"录音.aac" isDirectory:NO];
//    return _musicUrl;
//}

- (void)setMusicUrl:(NSURL *)musicUrl
{
    _musicUrl = musicUrl;
}

- (BOOL)isPlaying {
    return self.playerNode.isPlaying;
}

- (CGFloat)musicTotalTime
{
    if (_musicTotalTime == 0) {
        AVAudioFrameCount frameCount = (AVAudioFrameCount)self.audioFile.length;
        self.sampleRate = self.audioFile.processingFormat.sampleRate;
        if (self.sampleRate != 0) {
            _musicTotalTime = frameCount / self.sampleRate;
         // NSLog(@"%f\n",self.musicTotalTime);
        }
    }
    return _musicTotalTime;
}

- (void)didFinishPlay {
    
}


///获取首页音频的总时长
- (CGFloat)homeMusicTotalTime
{
    NSError *error;
    self.audioFile = [[AVAudioFile alloc] initForReading:self.musicUrl error:&error];
    AVAudioFrameCount frameCount = (AVAudioFrameCount)self.audioFile.length;
    self.sampleRate = self.audioFile.processingFormat.sampleRate;
    if (self.sampleRate != 0) {
        self.musicTotalTime = frameCount / self.sampleRate;
        NSLog(@"%f\n",self.musicTotalTime);
    }
    return self.musicTotalTime;
}

#pragma mark fft 函数 数据处理
- (RealTimeAnalyzer *)realTimeData
{
    if (!_realTimeData) {
        _realTimeData = [[RealTimeAnalyzer alloc]initWithFftSize:1024];
    }
    return _realTimeData;
}


@end
