//
//  ML.h
//  ML
//
//  Created by xulin on 02/24/2012.
//  Copyright (c) 2012 XingCloud. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ML : NSObject
{
    id __internal;
}

+ (void)init:(NSString *)serviceName 
      apiKey:(NSString *)apiKey 
  sourceLang:(NSString *)sourceLang 
  targetLang:(NSString *)targetLang 
autoDownloadFile:(NSString *)autoDownloadFile
autoAddString:(NSString *)autoAddString;

+ (NSString *)trans:(NSString *)source;

#define TRANS(key) [ML trans:(key)]

@end


