//
//  ViewController.m
//  BZAvAudioEngine
//
//  Created by 侯宝华 on 2020/11/5.
//

#import "ViewController.h"
#import "RecordViewController.h"
#import "PlayerViewController.h"

#define KSreenHeight [UIScreen mainScreen].bounds.size.height
#define KSreenWidth [UIScreen mainScreen].bounds.size.width

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>

@property(nonatomic,strong)UITableView *listTableView;
@property(nonatomic,strong)NSArray *nameArray;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    [self initViews];
}

#pragma mark - initViews
- (void)initViews
{
    [self.view addSubview:self.listTableView];
}
#pragma mark - touchAction

- (void)recordBtnAction:(UIButton *)button
{
    
}

#pragma mark - delegate dataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.nameArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"cellId";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    cell.textLabel.text = self.nameArray[indexPath.row];
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    return cell;
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 100;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.row) {
        case 0:
        {
            //录音
            RecordViewController *vC = [[RecordViewController alloc]init];
            [self.navigationController pushViewController:vC animated:YES];
            break;
        }case 1:
        {
            //播放录制的声音
            PlayerViewController *vC = [[PlayerViewController alloc]init];
            vC.didHaveAnimation = NO;
            [self.navigationController pushViewController:vC animated:YES];
            break;
        }case 2:
        {
            //网易云鲸鱼动画
            PlayerViewController *vC = [[PlayerViewController alloc]init];
            vC.didHaveAnimation = YES;
            [self.navigationController pushViewController:vC animated:YES];
            break;
        }
        default:
            break;
    }
}

#pragma mark - get set
- (UITableView *)listTableView
{
    if (!_listTableView) {
        _listTableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 44, KSreenWidth, KSreenHeight - 44) style:UITableViewStylePlain];
        _listTableView.dataSource = self;
        _listTableView.delegate = self;
        _listTableView.rowHeight = 50;
        _listTableView.backgroundColor = [UIColor whiteColor];
        _listTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    }
    return _listTableView;
}

- (NSArray *)nameArray
{
    if (!_nameArray) {
        _nameArray = @[@"录音",@"播放录制的声音",@"网易云鲸鱼动画"];
    }
    return _nameArray;
}

#pragma mark - SEL



@end
