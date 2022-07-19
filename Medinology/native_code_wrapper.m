//
//  native_code_wrapper.m
//  Medinology
//
//  Created by 양현서 on 2022/07/20.
//

#import <Foundation/Foundation.h>
#import "native_code_wrapper.h"
#import "native_code.hpp"
@implementation NativeCodeWrapper

- (void) initData:(bool)_preg :(int) _age :(int) _weight :(NSArray *) _symptoms :(int) symptomlen :(int) _diseases {
    int count = (int) [_symptoms count];
    bool * cArray = malloc(count * sizeof(bool));
    for (int i = 0; i < count; ++i) {
        cArray[i] = [[_symptoms objectAtIndex:i] boolValue];
    }
    initData(_preg, _age, _weight, cArray, symptomlen, _diseases);
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
    initWeights();
}
- (void) finalizeNative {
    finalizeNative();
}
@end
