ML IOS SDK
=============

ML IOS SDK可以帮你轻松地完成应用国际化

安装说明
--------

在项目中加入
ML.h
libML.a

使用说明
--------

在AppDelegate.m中

    #import "ML.h"
    
    - (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
	{
		///////////////////////////////////////////////////////////////////////////////
		// 获取系统使用语言
		NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
		NSArray *languages = [defs objectForKey:@"AppleLanguages"];
		NSString *preferredLang = [languages objectAtIndex:0];
		
		// 初始化ML IOS SDK
		[ML init:@"ios_sdk_test" 
		  apiKey:@"2e637ea2964ece61d611a04ea24016eb" 
	  sourceLang:@"cn" 
	  targetLang:preferredLang];
		///////////////////////////////////////////////////////////////////////////////
		
		...
		
		return YES;
	}
	
使用TRANS对字符串进行国际化

	#import "ML.h"
	
	[label1 setText:TRANS(@"多语言")];
    [label2 setText:TRANS(@"测试")];
    [label3 setText:TRANS(@"应用")];


