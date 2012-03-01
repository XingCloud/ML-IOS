//
//  ML.m
//  ML
//
//  Created by xulin on 02/24/2012.
//  Copyright (c) 2012 XingCloud. All rights reserved.
//

#import "ML.h"
#import "SBJson.h"
#import <libxml/tree.h>
#import <CommonCrypto/CommonDigest.h>

/////////////////////////////////////////////////////////////////////////////////////////////
@interface BaseXmlParser : NSObject 
{
}

- (void)startElementLocalName:(const xmlChar *)localname  
                       prefix:(const xmlChar *)prefix  
                          URI:(const xmlChar *)URI  
                nb_namespaces:(int)nb_namespaces  
                   namespaces:(const xmlChar **)namespaces  
                nb_attributes:(int)nb_attributes  
                 nb_defaulted:(int)nb_defaultedslo  
                   attributes:(const xmlChar **)attributes;

- (void)endElementLocalName:(const xmlChar *)localname  
                     prefix:(const xmlChar *)prefix 
                        URI:(const xmlChar *)URI; 

- (void)charactersFound:(const xmlChar *)ch  
                    len:(int)len; 

@end

@interface DefaultFileParser : BaseXmlParser 
{      
    int flag;
    NSMutableDictionary *_stringHash;
    NSString *_curSource;
}

- (id)init:(NSMutableDictionary *)stringHash;

- (void)startElementLocalName:(const xmlChar *)localname  
                       prefix:(const xmlChar *)prefix  
                          URI:(const xmlChar *)URI  
                nb_namespaces:(int)nb_namespaces  
                   namespaces:(const xmlChar **)namespaces  
                nb_attributes:(int)nb_attributes  
                 nb_defaulted:(int)nb_defaultedslo  
                   attributes:(const xmlChar **)attributes;

- (void)endElementLocalName:(const xmlChar *)localname  
                     prefix:(const xmlChar *)prefix 
                        URI:(const xmlChar *)URI; 

- (void)charactersFound:(const xmlChar *)ch  
                    len:(int)len; 

@end

@interface ML()

@property (strong, nonatomic) id internal;

@end
/////////////////////////////////////////////////////////////////////////////////////////////

@implementation ML

@synthesize internal = __internal;

//3个静态方法的实现，其实是调用了参数ctx的成员方法， ctx在_parserContext初始化时传入  
static void startElementHandler(void *ctx,  
                                const xmlChar *localname,  
                                const xmlChar *prefix,  
                                const xmlChar *URI,  
                                int nb_namespaces,  
                                const xmlChar **namespaces,  
                                int nb_attributes,  
                                int nb_defaulted,  
                                const xmlChar **attributes)  
{  
    [(BaseXmlParser *)ctx startElementLocalName:localname 
                                        prefix:prefix URI:URI  
                                 nb_namespaces:nb_namespaces  
                                    namespaces:namespaces  
                                 nb_attributes:nb_attributes  
                                  nb_defaulted:nb_defaulted  
                                    attributes:attributes];  
}

static void endElementHandler(void *ctx,  
                              const xmlChar *localname,  
                              const xmlChar *prefix,  
                              const xmlChar *URI)  

{  
    [(BaseXmlParser *)ctx endElementLocalName:localname 
                                      prefix:prefix
                                         URI:URI];  
}

static void charactersFoundHandler(void *ctx,  
                                   const xmlChar *ch,  
                                   int len)  
{  
    [(BaseXmlParser*)ctx  
     charactersFound:ch len:len];  
} 

static xmlSAXHandler _saxHandlerStruct = {  
    NULL,             
    NULL,            
    NULL,             
    NULL,             
    NULL,             
    NULL,             
    NULL,             
    NULL,             
    NULL,             
    NULL,             
    NULL,             
    NULL,             
    NULL,             
    NULL,             
    NULL,             
    NULL,             
    NULL,             
    charactersFoundHandler,  
    NULL,             
    NULL,             
    NULL,             
    NULL,             
    NULL,             
    NULL,             
    NULL,             
    NULL,             
    NULL,             
    XML_SAX2_MAGIC,   
    NULL,             
    startElementHandler,     
    endElementHandler,       
    NULL,             
};

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
    NSTimeInterval interval = [data timeIntervalSince1970];
    return [NSString stringWithFormat:@"%.0f", interval];
}

+ (void)init:(NSString *)serviceName 
      apiKey:(NSString *)apiKey
  sourceLang:(NSString *)sourceLang
  targetLang:(NSString *)targetLang
autoDownloadFile:(NSString *)autoDownloadFile
autoAddString:(NSString *)autoAddString;
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
        [internal setObject:autoDownloadFile forKey:@"autoDownloadFile"];
        [internal setObject:autoAddString forKey:@"autoAddString"];
        //[internal setObject:@"i.xingcloud.com" forKey:@"serverAddr"];
        [internal setObject:@"10.1.4.199:2012" forKey:@"serverAddr"];
        NSMutableDictionary *stringHash = [[NSMutableDictionary alloc] init];
        [internal setObject:stringHash forKey:@"stringHash"];
        [stringHash release];
        ///////////////////////////////////////////////////////////////////////////////
        
        NSError *error;
        NSString *defaultFileName = @"xc_words.xml";
        NSString *cacheFileName = [NSString stringWithFormat:@"xc_words_%@.xml", targetLang];
        
        ///////////////////////////////////////////////////////////////////////////////
        // 读取本地文件
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *fileName = [documentsDirectory stringByAppendingPathComponent:cacheFileName];
        NSData *fileData = [[[NSData alloc] initWithContentsOfFile:fileName] autorelease];
        ///////////////////////////////////////////////////////////////////////////////
        
        if ([autoDownloadFile isEqualToString:@"ON"])
        {
            ///////////////////////////////////////////////////////////////////////////////
            // 获取服务器端的文件信息
            NSString *urlString = [NSString stringWithFormat:@"http://%@/api/v1/file/info", 
                                   [internal objectForKey:@"serverAddr"]];
            NSString *timeStamp = genTimeStamp();
            NSString *hash = genMD5([[timeStamp stringByAppendingString:apiKey] UTF8String]);
            NSString *bodyString = [NSString stringWithFormat:@"service_name=%@&lang=%@&file_path=%@&timestamp=%@&hash=%@",
                                    serviceName, targetLang, defaultFileName, timeStamp, hash];
            NSMutableURLRequest *postRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
            [postRequest setHTTPBody:[bodyString dataUsingEncoding:NSUTF8StringEncoding]];
            [postRequest setHTTPMethod:@"POST"];
            
            NSData *resultData;
            NSURLResponse *response;
            resultData = [NSURLConnection sendSynchronousRequest:postRequest 
                                                       returningResponse:&response 
                                                                   error:&error];
            
            NSString *requestAddress = nil;
            NSString *md5 = nil;
            if (resultData != nil)
            {
                NSString *fileInfoString = [[NSString alloc] initWithData:resultData encoding:NSUTF8StringEncoding];
                SBJsonParser *parser = [[SBJsonParser alloc] init]; 
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
                NSURL *url = [NSURL URLWithString:[[NSString alloc] initWithFormat:requestAddress]];
                NSURLRequest *getRequest = [NSURLRequest requestWithURL:url
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
            DefaultFileParser *defaultFileParser = [[DefaultFileParser alloc] init:[internal objectForKey:@"stringHash"]];
            xmlParserCtxtPtr parserContext = xmlCreatePushParserCtxt(&_saxHandlerStruct, defaultFileParser, NULL, 0, NULL);
            xmlParseChunk(parserContext, (const char *)[fileData bytes], [fileData length], 0);
        }
        ///////////////////////////////////////////////////////////////////////////////
    }
}

+ (NSString *)trans:(NSString *)source
{
    NSMutableDictionary *internal = (NSMutableDictionary *)[[ML sharedML] internal];
    NSString *targetLang = [internal objectForKey:@"targetLang"];
    NSString *autoAddString = [internal objectForKey:@"autoAddString"];
    
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
        if ([autoAddString isEqualToString:@"ON"])
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

@implementation BaseXmlParser

- (id)init
{
    self = [super init];
    return self;  
}  

-(void)dealloc
{  
    [super dealloc];  
}  

#pragma mark -- libxml handler，主要是3个回调方法 --  

// 解析元素开始标记时触发，在这里取元素的属性值  
- (void)startElementLocalName:(const xmlChar *)localname  
                       prefix:(const xmlChar *)prefix  
                          URI:(const xmlChar *)URI  
                nb_namespaces:(int)nb_namespaces  
                   namespaces:(const xmlChar **)namespaces  
                nb_attributes:(int)nb_attributes  
                 nb_defaulted:(int)nb_defaultedslo  
                   attributes:(const xmlChar **)attributes  
{    
}

// 解析元素结束标记时触发  
- (void)endElementLocalName:(const xmlChar *)localname  
                     prefix:(const xmlChar *)prefix 
                        URI:(const xmlChar *)URI  
{  
}

// 解析元素体时触发  
- (void)charactersFound:(const xmlChar *)ch  
                    len:(int)len  
{  
} 

@end

@implementation DefaultFileParser

- (id)init:(NSMutableDictionary *)stringHash
{  
    if (self = [super init])
    {  
        _stringHash = stringHash;
    }
    return self;  
}  

- (void)dealloc
{  
    [super dealloc];  
}   

#pragma mark -- libxml handler，主要是3个回调方法--  

// 解析元素开始标记时触发，在这里取元素的属性值  
- (void)startElementLocalName:(const xmlChar *)localname  
                       prefix:(const xmlChar *)prefix  
                          URI:(const xmlChar *)URI  
                nb_namespaces:(int)nb_namespaces  
                   namespaces:(const xmlChar **)namespaces  
                nb_attributes:(int)nb_attributes  
                 nb_defaulted:(int)nb_defaultedslo  
                   attributes:(const xmlChar **)attributes 
{  
    if (strncmp((char*)localname, "source", sizeof("source")) == 0) 
    {  
        flag = 1;  
        return;  
    }
    
    if (strncmp((char*)localname, "target", sizeof("target")) == 0) 
    {  
        flag = 2;
        return;  
    }  
}

// 解析元素结束标记时触发  
- (void)endElementLocalName:(const xmlChar *)localname  
                     prefix:(const xmlChar *)prefix 
                        URI:(const xmlChar *)URI  
{  
    flag = 0;  // 标志归零  
}

//解析元素体时触发  
- (void)charactersFound:(const xmlChar*)ch  
                    len:(int)len  
{  
    // 取login_status元素体  
    if (flag == 1) 
    {
        _curSource = [[NSString alloc] initWithBytes:ch length:len encoding:NSUTF8StringEncoding];   
    }
    
    if (flag == 2)
    {
        NSString * target = [[NSString alloc] initWithBytes:ch length:len encoding:NSUTF8StringEncoding];
        [_stringHash setObject:target forKey:_curSource];
        [target release];
        [_curSource release];
        _curSource = nil;
    }
}

@end


