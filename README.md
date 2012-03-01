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

### init

在AppDelegate.m或其View中使用init初始化SDK

#### 参数说明

* serviceName  服务名称
* apiKey  API Key
* sourceLang  源语言
* targetLang  目标语言
* autoDownloadFile  是否自动下载语言包，值为@"ON"或@"OFF"。当值为@"ON"时，本地语言包不存在或与服务器端不一致时会自动更新
* autoAddString  是否自动添加翻译词条，值为@"ON"或@"OFF"。当值为@"ON"时，无法在本地语言包中找到翻译内容时会自动向服务器添加词条

#### 调用实例

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
	      targetLang:preferredLang
	autoDownloadFile:@"ON"
	   autoAddString:@"ON"];
		///////////////////////////////////////////////////////////////////////////////
		
		...
		
		return YES;
	}

### TRANS

使用TRANS对字符串进行国际化

#### 参数说明

* key  需要翻译的词条

#### 调用实例

	#import "ML.h"
	
	[label1 setText:TRANS(@"多语言")];
    [label2 setText:TRANS(@"测试")];
    [label3 setText:TRANS(@"应用")];


