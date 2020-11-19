//
//  RecordViewController.m
//  BZAvAudioEngine
//
//  Created by 侯宝华 on 2020/11/16.
//

#import "RecordViewController.h"

#define animationDistance 3
#define animationLineWidth 2.5
#define layerCounts (KSreenWidth - animationDistance) / (animationLineWidth + animationDistance)

#define animationTime 0.05

@interface RecordViewController ()

@property(nonatomic,strong)BZAVAudioEngine *engine;

@property(nonatomic,assign)CGFloat seconde;
@property(nonatomic,assign)CGFloat minute;
@property(nonatomic,assign)CGFloat timeCount;
@property(nonatomic,strong)dispatch_source_t timer;
@property(nonatomic,strong)UIButton *stopBtn;
@property(nonatomic,assign)CGFloat currentDistance;
@property(nonatomic,strong)UIScrollView *animationScrollView;
@property(nonatomic,assign)BOOL needRemove;
@property(nonatomic,assign)CGFloat screenX;
@property(nonatomic,strong)UILabel *timeLabel;


@end

@implementation RecordViewController

- (void)dealloc
{
    dispatch_source_cancel(_timer);
    _timer = nil; //OK
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationController.title = @"录制";
    [self initViews];
}

#pragma mark - initViews
- (void)initViews
{
    self.view.backgroundColor = [UIColor whiteColor];
    self.currentDistance = KSreenWidth;
    self.screenX = 0;
    
    [self.view addSubview:self.timeLabel];
    [self.timeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.centerY.equalTo(self.view.mas_centerY).offset(-50);
    }];
    
    [self.view addSubview:self.stopBtn];
    [self.stopBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view).offset(-15);
        make.centerX.equalTo(self.view);
    }];
    
    [self.view addSubview:self.animationScrollView];
    [self.animationScrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.top.equalTo(self.timeLabel.mas_bottom);
        make.bottom.equalTo(self.stopBtn.mas_top);
    }];
    
    [self.view layoutIfNeeded];
    
    [[BZAVAudioEngine shareAudioEngine]initAudioEngine];
    [[BZAVAudioEngine shareAudioEngine]startRecord];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(),^{
        @weakify(self);
        dispatch_queue_t queuet = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queuet);
        dispatch_source_set_timer(self.timer, dispatch_walltime(NULL, 0), animationTime * NSEC_PER_SEC, 0);
        dispatch_source_set_event_handler(self.timer, ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                @strongify(self);
                self.timeCount = self.timeCount + animationTime;
                self.seconde = self.seconde + animationTime;
                if (self.seconde >= 60) {
                    self.minute = self.minute + 1;
                    self.seconde = 0;
                }
                self.timeLabel.text = [NSString stringWithFormat:@"%@:%@",[self intIsLessThanTen:self.minute],[self intIsLessThanTen:self.seconde]];
                
                CGFloat height = 30 * [BZAVAudioEngine shareAudioEngine].currentVolume * 5;
                if (height < 5) {
                    height = 5;
                }
                if (height > 30) {
                    height = 30;
                }
                UIBezierPath *path = [UIBezierPath bezierPath];
                [path moveToPoint:CGPointMake(self.currentDistance, self.animationScrollView.frame.size.height / 2.0 + height / 2.0)];
                [path addLineToPoint:CGPointMake(self.currentDistance, self.animationScrollView.frame.size.height  / 2.0 - height / 2.0)];
                path.lineCapStyle = kCGLineCapRound; //线条拐角
                path.lineJoinStyle = kCGLineJoinRound; //终点处理
                CAShapeLayer *lineLayer = [CAShapeLayer layer];
                lineLayer.lineWidth = animationLineWidth;
                lineLayer.strokeColor = kBZSetColor(111, 20, 208, 1).CGColor;
                lineLayer.path = path.CGPath;
                lineLayer.fillColor = nil; 
                lineLayer.lineJoin = kCALineJoinRound;//线拐点的类型
                lineLayer.lineCap = kCALineCapRound;
                [self.animationScrollView.layer addSublayer:lineLayer];
                self.currentDistance = self.currentDistance + animationLineWidth + animationDistance;
                [UIView animateWithDuration:0.35 animations:^{
                    [self.animationScrollView setContentOffset:CGPointMake(self.currentDistance - KSreenWidth, 0)];
                }];
                NSArray<CALayer *> *subLayers = self.animationScrollView.layer.sublayers;
                if (subLayers.count > layerCounts + 100) {
                    self.needRemove = YES;
                    [self removeOutputScreenLayer:subLayers];
                }
            });
        });
        dispatch_resume(self.timer);
    });
    
    
}
#pragma mark - touchAction
- (void)stopBtnAction:(UIButton *)button
{
    [[BZAVAudioEngine shareAudioEngine]stopAudioEngine];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)removeOutputScreenLayer:(NSArray *)sublayers
{
    if (self.needRemove == YES) {
        NSArray<CALayer *> *removedLayers = [sublayers filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id  _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
            return [evaluatedObject isKindOfClass:[CAShapeLayer class]];
        }]];
        [removedLayers enumerateObjectsUsingBlock:^(CALayer * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (idx < layerCounts) {
                [obj removeFromSuperlayer];
            }
        }];
    }
    self.needRemove = NO;
    
}


#pragma mark - delegate dataSource

#pragma mark - get set

- (UILabel *)timeLabel
{
    if (!_timeLabel) {
        _timeLabel = [[UILabel alloc]init];
        _timeLabel.text = @"00:00";
        _timeLabel.font = [UIFont systemFontOfSize:15];
        _timeLabel.textAlignment = NSTextAlignmentCenter;
        _timeLabel.textColor = [UIColor blackColor];
    }
    return _timeLabel;
}

- (UIButton *)stopBtn
{
    if (!_stopBtn) {
        _stopBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_stopBtn setImage:[UIImage imageNamed:@"HomeRecordingStopImageV"]  forState:UIControlStateNormal];
        [_stopBtn addTarget:self action:@selector(stopBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _stopBtn;
}

- (UIScrollView *)animationScrollView
{
    if (!_animationScrollView) {
        _animationScrollView = [[UIScrollView alloc]init];
        _animationScrollView.contentSize = CGSizeMake(MAXFLOAT, 0);
        _animationScrollView.scrollEnabled = NO;
    }
    return _animationScrollView;
}


#pragma mark - SEL
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
@end
