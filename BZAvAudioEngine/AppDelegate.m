//
//  AppDelegate.m
//  BZAvAudioEngine
//
//  Created by 侯宝华 on 2020/11/5.
//

#import "AppDelegate.h"
#import "ViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    self.window = [[UIWindow alloc]initWithFrame:[UIScreen mainScreen].bounds];
    self.window.rootViewController = [[UINavigationController alloc]initWithRootViewController:[[ViewController alloc]init]];
    [self.window makeKeyAndVisible];
    
    return YES;
}


#pragma mark - UISceneSession lifecycle



@end
