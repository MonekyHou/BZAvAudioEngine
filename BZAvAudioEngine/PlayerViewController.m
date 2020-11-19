//
//  PlayerViewController.m
//  BZAvAudioEngine
//
//  Created by 侯宝华 on 2020/11/16.
//

#import "PlayerViewController.h"

#define TimeFrequency 0.1

//#define TimeFrequency 0.1

#define ToRadian(radian)            (radian*(M_PI/180.0))
#define radius4 150

#define layerLineMinHeight .5

//弧度转角度
#define RADIANS_TO_DEGREES(radians) ((radians) * (180.0 / M_PI))

//角度转弧度
#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)

@interface PlayerViewController ()
{
    CGFloat angle;//总弧度
    CGFloat perAngle;
}

@property(nonatomic,strong)UISlider *timeSlider;
@property(nonatomic,strong)UILabel *currentTimeLabel;
@property(nonatomic,strong)UILabel *totalTimeLabel;
@property(nonatomic,strong)UIButton *stopBtn;

@property(nonatomic,assign)CGFloat seconde;
@property(nonatomic,assign)CGFloat minute;
@property(nonatomic,assign)CGFloat timeCount;

@property(nonatomic,strong)dispatch_source_t timer;

///是否播放完全
@property(nonatomic,assign)BOOL didDown;
///当前播放状态
@property(nonatomic,assign)BOOL didIsPlay;

@property(nonatomic,strong)UIView *animationBgView;

//开始弧度
@property (nonatomic,assign)CGFloat start;

@end

@implementation PlayerViewController

- (void)dealloc
{
    if (_timer != nil) {
        dispatch_resume(_timer);
        dispatch_source_cancel(_timer);
        _timer = nil; // OK
    }
}


#pragma mark - initViews
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor grayColor];
    [self.view addSubview:self.animationBgView];
    [self.animationBgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.top.width.equalTo(self.view);
        make.bottom.equalTo(self.view.mas_centerY);
    }];
    
    [self.view addSubview:self.timeSlider];
    [self.timeSlider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(30);
        make.right.equalTo(self.view).offset(-30);
        make.top.equalTo(self.view.mas_centerY);
        make.height.mas_equalTo(40);
    }];
    
    [self.view addSubview:self.currentTimeLabel];
    [self.currentTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.timeSlider.mas_left);
        make.top.equalTo(self.timeSlider.mas_bottom);
    }];
    
    [self.view addSubview:self.totalTimeLabel];
    [self.totalTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.timeSlider.mas_right);
        make.top.equalTo(self.timeSlider.mas_bottom);
    }];
    
    [self.view addSubview:self.stopBtn];
    [self.stopBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(self.currentTimeLabel.mas_bottom).offset(5);
    }];
}

#pragma mark - touchAction

- (void)stopBtnAction:(UIButton *)button
{
    button.selected = !button.selected;
    self.didIsPlay = button.selected;
    if (button.selected) {
        //播放
        if (self.didDown == YES) {
            //重新开始播放
            self.timeCount = 0;
            self.seconde = 0;
            self.minute = 0;
            self.didDown = NO;
            [[BZAVAudioEngine shareAudioEngine]initPlayer];
            [BZAVAudioEngine shareAudioEngine].currentTime = 0;
        }
        if (_timer == nil) {
            [[BZAVAudioEngine shareAudioEngine]initPlayer];
            [BZAVAudioEngine shareAudioEngine].currentTime = 0;
            [self loadTimer];
        }else
        {
            dispatch_resume(self.timer);
        }
        
        [[BZAVAudioEngine shareAudioEngine]playerPlay];
        [self.stopBtn setImage:[UIImage imageNamed:@"HomeEditNameStartImage"] forState:UIControlStateNormal];

    }else
    {
        //暂停
        dispatch_suspend(self.timer);
        if (self.didDown) {
            [[BZAVAudioEngine shareAudioEngine]playStopAudioEngine];
        }else
        {
            [[BZAVAudioEngine shareAudioEngine]playerPause];
        }
        [self.stopBtn setImage:[UIImage imageNamed:@"HomeEditNameStopImage"] forState:UIControlStateNormal];
    }
}

- (void)timeSliderValueChange:(UISlider *)slider
{
    CGFloat resultSeconde = slider.value;
    self.seconde = (int)resultSeconde % 60;
    self.minute = (int)resultSeconde / 60;
    self.currentTimeLabel.text = [NSString stringWithFormat:@"%@:%@",[self intIsLessThanTen:self.minute],[self intIsLessThanTen:self.seconde]];
    if (self.didIsPlay == YES) {
        [[BZAVAudioEngine shareAudioEngine]playerPause];
    }
    if (slider.value != [[BZAVAudioEngine shareAudioEngine]homeMusicTotalTime]) {
        self.didDown = NO;
    }
}

- (void)timeSliderDidEnd:(UISlider *)slider
{
    [BZAVAudioEngine shareAudioEngine].currentTime = self.minute * 60 + self.seconde;
    if (self.didIsPlay) {
        [[BZAVAudioEngine shareAudioEngine]playerPlay];
    }
}



- (void)loadTimer
{
    dispatch_queue_t queuet = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queuet);
    dispatch_source_set_timer(self.timer, dispatch_walltime(NULL, 0), TimeFrequency * NSEC_PER_SEC, 0);
    @weakify(self);
    dispatch_source_set_event_handler(self.timer, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            @strongify(self);
            [[BZAVAudioEngine shareAudioEngine]catchCurrentTime];
            if (self.didHaveAnimation) {
                [self removeOutputScreenLayer:self.animationBgView.layer.sublayers];
                [self creatAnimationLayer];
            }
            self.timeCount = self.timeCount + TimeFrequency;
            self.seconde = self.seconde + TimeFrequency;
            if (self.seconde >= 60) {
                self.minute = self.minute + 1;
                self.seconde = 0;
            }
            self.currentTimeLabel.text = [NSString stringWithFormat:@"%@:%@",[self intIsLessThanTen:self.minute],[self intIsLessThanTen:self.seconde]];
            
            if (self.timeCount >= 1) {
                self.timeSlider.value = (self.minute * 60 + self.seconde);
                self.timeCount = 0;
            }
            
            if (self.minute * 60 + self.seconde >= [BZAVAudioEngine shareAudioEngine].musicTotalTime) {
                //播放完毕
                self.didDown = YES;
                [self stopBtnAction:self.stopBtn];
                self.timeSlider.value = [BZAVAudioEngine shareAudioEngine].musicTotalTime;
            }
            
        });
        
    });
    dispatch_resume(self.timer);
    
}

- (NSString *)intIsLessThanTen:(int)little
{
    NSString *resultString = @"";
    if (little < 10) {
        resultString = [NSString stringWithFormat:@"0%d",little];
    }else
    {
        resultString = [NSString stringWithFormat:@"%d",little];
    }
    return resultString;
}

#pragma mark - delegate dataSource
      

#pragma mark - get set

- (void)setDidHaveAnimation:(BOOL)didHaveAnimation
{
    _didHaveAnimation = didHaveAnimation;
    NSURL *resultUrl;

    if (didHaveAnimation == YES) {
        [self.view layoutIfNeeded];
        [self creatAnimationLayer];
        NSString *str = [[NSBundle mainBundle] pathForResource:@"music" ofType:@"mp3"];
        resultUrl = [NSURL fileURLWithPath:str];
    }else
    {
        NSFileManager *fm = [NSFileManager defaultManager];
        NSURL *doc = [fm URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];
        resultUrl = [doc URLByAppendingPathComponent:@"录音.aac" isDirectory:NO];
    }
    [BZAVAudioEngine shareAudioEngine].musicUrl = resultUrl;
    
    [[BZAVAudioEngine shareAudioEngine]initPlayer];
    
    [[BZAVAudioEngine shareAudioEngine]homeMusicTotalTime];

    self.timeSlider.maximumValue = [BZAVAudioEngine shareAudioEngine].musicTotalTime;
    self.totalTimeLabel.text = [self getMMSSFromSS:[NSString stringWithFormat:@"%f",[BZAVAudioEngine shareAudioEngine].musicTotalTime]];
    
    
}

- (UISlider *)timeSlider
{
    if (!_timeSlider) {
        _timeSlider = [[UISlider alloc]init];
        _timeSlider.thumbTintColor = [UIColor whiteColor];
        _timeSlider.minimumValue = 0;
        _timeSlider.maximumValue = 1;
        _timeSlider.minimumTrackTintColor = kBZSetColor(111, 20, 208, 1);
        _timeSlider.maximumTrackTintColor = [UIColor grayColor];
        [_timeSlider setThumbImage:[UIImage imageNamed:@"HomeSliderThumbImageV"] forState:UIControlStateNormal];
        [_timeSlider setThumbImage:[UIImage imageNamed:@"HomeSliderThumbImageV"] forState:UIControlStateHighlighted];
        [_timeSlider addTarget:self action:@selector(timeSliderValueChange:) forControlEvents:UIControlEventValueChanged];
        [_timeSlider addTarget:self action:@selector(timeSliderDidEnd:) forControlEvents:UIControlEventTouchUpInside];

    }
    return _timeSlider;
}

- (UILabel *)currentTimeLabel
{
    if (!_currentTimeLabel) {
        _currentTimeLabel = [[UILabel alloc]init];
        _currentTimeLabel.text = @"00:00";
        _currentTimeLabel.font = [UIFont systemFontOfSize:15];
        _currentTimeLabel.textColor = [UIColor whiteColor];
        _currentTimeLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _currentTimeLabel;
}

- (UILabel *)totalTimeLabel
{
    if (!_totalTimeLabel) {
        _totalTimeLabel = [[UILabel alloc]init];
        _totalTimeLabel.text = @"00:00";
        _totalTimeLabel.font = [UIFont systemFontOfSize:15];
        _totalTimeLabel.textColor = [UIColor whiteColor];
        _totalTimeLabel.textAlignment = NSTextAlignmentRight;
    }
    return _totalTimeLabel;
}

- (UIButton *)stopBtn
{
    if (!_stopBtn) {
        _stopBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_stopBtn setImage:[UIImage imageNamed:@"HomeEditNameStopImage"] forState:UIControlStateNormal];
        [_stopBtn addTarget:self action:@selector(stopBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _stopBtn;
}

- (UIView *)animationBgView
{
    if (!_animationBgView) {
        _animationBgView = [[UIView alloc]init];
        _animationBgView.backgroundColor = [UIColor whiteColor];
    }
    return _animationBgView;
}


#pragma mark - SEL

- (NSString *)getMMSSFromSS:(NSString *)totalTime{
    NSInteger seconds = [totalTime integerValue];
    NSString *str_minute = [NSString stringWithFormat:@"%@",[self intIsLessThanTen:(int)seconds / 60]];
    NSString *str_second = [NSString stringWithFormat:@"%@",[self intIsLessThanTen:(int)seconds % 60]];
    NSString *format_time = [NSString stringWithFormat:@"%@:%@",str_minute,str_second];
    return format_time;
}

- (void)creatAnimationLayer
{
    _start = 0;
    angle = M_PI * 2;
    perAngle = angle / (number - 1);
    for (int i = 0 ; i <number; i++) {
        CGFloat lineHeight = layerLineMinHeight;
        if ([BZAVAudioEngine shareAudioEngine].leftChannelArray.count > i) {
            lineHeight  = [([BZAVAudioEngine shareAudioEngine].leftChannelArray)[i] floatValue] * 100;
        }
        CGFloat startAngel;
        CGPoint center = CGPointMake(KSreenWidth / 2.0,64 + ( KSreenHeight / 2.0 - 64) / 2.0);
        startAngel = _start+perAngle*i;
        UIBezierPath *path = [UIBezierPath bezierPath];
        CGPoint firstPoint = [self calcCircleCoordinateWithCenter:center andWithAngle:RADIANS_TO_DEGREES(startAngel) andWithRadius:100];
        [path moveToPoint:firstPoint];
        [path addLineToPoint:[self calcCircleCoordinateWithCenter:center andWithAngle:RADIANS_TO_DEGREES(startAngel) andWithRadius:100 + lineHeight]];
        path.lineCapStyle = kCGLineCapRound;
        path.lineJoinStyle = kCGLineJoinRound;
        CAShapeLayer *lineLayer = [CAShapeLayer layer];
        lineLayer.lineWidth = 3;
        lineLayer.strokeColor = kBZSetColor(183, 55, 252, 1).CGColor;
        lineLayer.path = path.CGPath;
        lineLayer.fillColor = nil;
        lineLayer.lineJoin = kCALineJoinRound;
        lineLayer.lineCap = kCALineCapRound;
        [self.animationBgView.layer addSublayer:lineLayer];
        
    }
}

///获取圆上任一点的坐标
- (CGPoint) calcCircleCoordinateWithCenter:(CGPoint) center  andWithAngle : (CGFloat) angle andWithRadius: (CGFloat) radius{
    CGFloat x2 = radius*cosf(angle*M_PI/180);
    CGFloat y2 = radius*sinf(angle*M_PI/180);
    return CGPointMake(center.x+x2, center.y-y2);
}

- (void)removeOutputScreenLayer:(NSArray *)sublayers
{
    NSArray<CALayer *> *removedLayers = [sublayers filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id  _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        return [evaluatedObject isKindOfClass:[CAShapeLayer class]];
    }]];
    [removedLayers enumerateObjectsUsingBlock:^(CALayer * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeFromSuperlayer];
        
    }];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
