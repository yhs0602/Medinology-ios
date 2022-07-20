//
//  native_code_wrapper.h
//  Medinology
//
//  Created by 양현서 on 2022/07/20.
//

#ifndef native_code_wrapper_h
#define native_code_wrapper_h

#import <Foundation/Foundation.h>
@interface NativeCodeWrapper : NSObject
- (void) initData:(bool)_preg :(int) _age :(int) _weight :(NSArray*) _symptoms :(int) _diseases;
- (void) calcData;
- (int) getDisID:(int) n;
- (int) getProb: (int) n;
- (void) initWeights;
- (void) finalizeNative;
@end

#endif /* native_code_wrapper_h */
