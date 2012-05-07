//
//  ML.m
//  ML
//
//  Created by xulin on 02/24/2012.
//  Copyright (c) 2012 XingCloud. All rights reserved.
//

#import "ML.h"
#import "SBJson.h"
#import <CommonCrypto/CommonDigest.h>

@interface ML()

@property (strong, nonatomic) id internal;

@end

@implementation ML

@synthesize internal = __internal;

- (id)init
{
    self = [super init];
    if (self)
    {
        self.internal = [[NSMutableDictionary alloc] init];
    }
    return self;
}

static ML *ml;

- (void)dealloc
{
    [super dealloc];
}

+ (ML *)sharedML
{
    if (ml == nil)
    {
        ml = [[ML alloc] init];
    }
    
    return ml;
}

static NSString * genMD5(const char *cStr)
{
    unsigned char result[32];
    CC_MD5(cStr, strlen(cStr), result); // This is the md5 call
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]];  
}

static NSString * genTimeStamp()
{
    NSDate *data = [NSDate dateWithTimeIntervalSinceNow:0];
    NSTimeInterval interval = [data timeIntervalSince1970] * 1000;
    return [NSString stringWithFormat:@"%.0f", interval];
}

+ (void)init:(NSString *)serviceName 
      apiKey:(NSString *)apiKey
  sourceLang:(NSString *)sourceLang
  targetLang:(NSString *)targetLang
autoUpdateFile:(NSString *)autoUpdateFile
autoAddTrans:(NSString *)autoAddTrans;
{
    ///////////////////////////////////////////////////////////////////////////////
    // 构建数据
    if ([targetLang isEqualToString:@"zh-Hans"])
    {
        targetLang = @"cn";
    }
    else if ([targetLang isEqualToString:@"zh-Hant"]) 
    {
        targetLang = @"tw";
    }
    
    if (![sourceLang isEqualToString:targetLang]) 
    {
        NSMutableDictionary *internal = (NSMutableDictionary *)[[ML sharedML] internal];
        
        [internal setObject:serviceName forKey:@"serviceName"];
        [internal setObject:apiKey forKey:@"apiKey"];
        [internal setObject:sourceLang forKey:@"sourceLang"];
        [internal setObject:targetLang forKey:@"targetLang"];
        [internal setObject:autoUpdateFile forKey:@"autoUpdateFile"];
        [internal setObject:autoAddTrans forKey:@"autoAddTrans"];
        [internal setObject:@"i.xingcloud.com" forKey:@"serverAddr"];
        //[internal setObject:@"10.1.4.199:2012" forKey:@"serverAddr"];
        ///////////////////////////////////////////////////////////////////////////////
        
        NSError *error;
        NSString *defaultFileName = @"xc_words.json";
        NSString *cacheFileName = [NSString stringWithFormat:@"xc_words_%@.json", targetLang];
        SBJsonParser *parser = [[SBJsonParser alloc] init];
        
        ///////////////////////////////////////////////////////////////////////////////
        // 读取本地文件
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *fileName = [documentsDirectory stringByAppendingPathComponent:cacheFileName];
        NSData *fileData = [[[NSData alloc] initWithContentsOfFile:fileName] autorelease];
        ///////////////////////////////////////////////////////////////////////////////
        
        if ([autoUpdateFile isEqualToString:@"ON"])
        {
            ///////////////////////////////////////////////////////////////////////////////
            // 获取服务器端的文件信息
            /*
            NSString *urlString = [NSString stringWithFormat:@"http://%@/api/v1/file/info", 
                                   [internal objectForKey:@"serverAddr"]];
            NSString *timeStamp = genTimeStamp();
            NSString *hash = genMD5([[timeStamp stringByAppendingString:apiKey] UTF8String]);
            NSString *bodyString = [NSString stringWithFormat:@"service_name=%@&locale=%@&file_path=%@&timestamp=%@&hash=%@",
                                    serviceName, targetLang, defaultFileName, timeStamp, hash];
            NSMutableURLRequest *postRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
            [postRequest setHTTPBody:[bodyString dataUsingEncoding:NSUTF8StringEncoding]];
            [postRequest setHTTPMethod:@"GET"];
            
            NSData *resultData;
            NSURLResponse *response;
            resultData = [NSURLConnection sendSynchronousRequest:postRequest 
                                                       returningResponse:&response 
                                                                   error:&error];
            */
            
            NSURLRequest *getRequest;
            NSURL *url;
            
            NSString *timeStamp = genTimeStamp();
            NSString *hash = genMD5([[timeStamp stringByAppendingString:apiKey] UTF8String]);
            url = [NSURL URLWithString:[[NSString alloc] initWithFormat:@"http://%@/api/v1/file/info?service_name=%@&locale=%@&file_path=%@&timestamp=%@&hash=%@", [internal objectForKey:@"serverAddr"], serviceName, targetLang, defaultFileName, timeStamp, hash]];
            getRequest = [NSURLRequest requestWithURL:url
                                          cachePolicy:NSURLRequestUseProtocolCachePolicy
                                      timeoutInterval:10.0];
            
            NSData *resultData;
            resultData = [NSURLConnection sendSynchronousRequest:getRequest
                                               returningResponse:nil
                                                           error:&error];
            
            NSString *requestAddress = nil;
            NSString *md5 = nil;
            if (resultData != nil)
            {
                NSString *fileInfoString = [[NSString alloc] initWithData:resultData encoding:NSUTF8StringEncoding];
                NSDictionary *fileInfo = [parser objectWithString:fileInfoString error:&error];
                requestAddress = [[fileInfo objectForKey:@"data"] objectForKey:@"request_address"];
                md5 = [[fileInfo objectForKey:@"data"] objectForKey:@"md5"];
            }
            ///////////////////////////////////////////////////////////////////////////////
            
            ///////////////////////////////////////////////////////////////////////////////
            // 判断文件是否存在或是否发生变化
            if (fileData != nil)
            {
                NSString *nowMD5 = genMD5((const char *)[fileData bytes]);
                
                if (md5 != nil && ![nowMD5 isEqualToString:md5]) 
                {
                    fileData = nil;
                }
            }
            ///////////////////////////////////////////////////////////////////////////////
            
            ///////////////////////////////////////////////////////////////////////////////
            // 下载文件
            if (fileData == nil && [requestAddress length] != 0)
            {
                url = [NSURL URLWithString:[[NSString alloc] initWithFormat:requestAddress]];
                getRequest = [NSURLRequest requestWithURL:url
                                              cachePolicy:NSURLRequestUseProtocolCachePolicy
                                          timeoutInterval:10.0]; 
                fileData = [NSURLConnection sendSynchronousRequest:getRequest 
                                                   returningResponse:nil
                                                               error:&error];
                [fileData writeToFile:fileName atomically:YES];
            }
            ///////////////////////////////////////////////////////////////////////////////
        }
        
        ///////////////////////////////////////////////////////////////////////////////
        // 解析文件至内存Hash
        if (fileData != nil)
        {            
            NSString *fileInfoString = [[NSString alloc] initWithData:fileData encoding:NSUTF8StringEncoding];
            NSDictionary *stringHash = [parser objectWithString:fileInfoString error:&error];
            [internal setObject:stringHash forKey:@"stringHash"];
            [stringHash release];
        }
        ///////////////////////////////////////////////////////////////////////////////
    }
}

+ (NSString *)trans:(NSString *)source
{
    NSMutableDictionary *internal = (NSMutableDictionary *)[[ML sharedML] internal];
    NSString *targetLang = [internal objectForKey:@"targetLang"];
    NSString *autoAddTrans = [internal objectForKey:@"autoAddTrans"];
    
    if (source == targetLang)
    {
        return source;
    }
    
    NSMutableDictionary *stringHash = [internal objectForKey:@"stringHash"];
    NSString *serviceName = [internal objectForKey:@"serviceName"];
    NSString *apiKey = [internal objectForKey:@"apiKey"];
    NSError *error;
    NSData *resultData;
    
    NSString *target = [stringHash objectForKey:source];
    
    if (target == nil)
    {
        if ([autoAddTrans isEqualToString:@"ON"])
        {
            NSString *urlString = [NSString stringWithFormat:@"http://%@/api/v1/string/add", 
                                   [internal objectForKey:@"serverAddr"]];
            NSString *timeStamp = genTimeStamp();
            NSString *hash = genMD5([[timeStamp stringByAppendingString:apiKey] UTF8String]);
            NSString *bodyString = [NSString stringWithFormat:@"service_name=%@&data=%@&timestamp=%@&hash=%@",
                                    serviceName, source, timeStamp, hash];
            NSMutableURLRequest *postRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
            [postRequest setHTTPBody:[bodyString dataUsingEncoding:NSUTF8StringEncoding]];
            [postRequest setHTTPMethod:@"POST"];
            
            NSURLResponse *response;
            resultData = [NSURLConnection sendSynchronousRequest:postRequest 
                                               returningResponse:&response 
                                                           error:&error];
        }
        return source;
    }
    
    return target;
}

@end




