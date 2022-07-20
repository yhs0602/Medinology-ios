//
//  native_code.hpp
//  Medinology
//
//  Created by 양현서 on 2022/07/20.
//

#ifndef native_code_hpp
#define native_code_hpp
#ifdef __cplusplus
extern "C" {
#endif

void initData(bool _preg,int _age,int _weight,bool * _symptoms, int _symptomlen, int _diseases);
void calcData(void);
int getDisID(int n);
int getProb(int n);
void initWeights(const char * path);
void finalizeNative(void);
#ifdef __cplusplus
}
#endif
#endif /* native_code_hpp */
