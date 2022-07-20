//
//  log.m
//  Medinology
//
//  Created by 양현서 on 2022/07/20.
//

#import <Foundation/Foundation.h>
#import "log.h"

void debug(const char *message,...)
{
    va_list args;
    va_start(args, message);
    NSLog(@"%@",[[NSString alloc] initWithFormat:[NSString stringWithUTF8String:message] arguments:args]);
    va_end(args);
}
