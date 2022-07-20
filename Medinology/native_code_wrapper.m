//
//  native_code_wrapper.m
//  Medinology
//
//  Created by 양현서 on 2022/07/20.
//

#import <Foundation/Foundation.h>
#include <CoreFoundation/CFBundle.h>
#import "native_code_wrapper.h"
#import "native_code.hpp"
@implementation NativeCodeWrapper

- (void) initData:(bool)_preg :(int) _age :(int) _weight :(NSArray *) _symptoms :(int) _diseases {
    int count = (int) [_symptoms count];
    bool * cArray = malloc(count * sizeof(bool));
    for (int i = 0; i < count; ++i) {
        cArray[i] = [[_symptoms objectAtIndex:i] boolValue];
    }
    NSLog(@"symptoms length: %i", count);
    initData(_preg, _age, _weight, cArray, count, _diseases);
    free(cArray);
}
- (void) calcData {
    calcData();
}
- (int) getDisID:(int) n {
    return getDisID(n);
}
- (int) getProb: (int) n {
    return getProb(n);
}
- (void) initWeights {
    NSString* manifest_string = [[NSBundle mainBundle] pathForResource:@"weights"
                                                                ofType:@"txt"];
    const char* manifest_path = [manifest_string fileSystemRepresentation];
    initWeights(manifest_path);
}
- (void) finalizeNative {
    finalizeNative();
}
@end
