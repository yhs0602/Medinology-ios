//
//  native_code.hpp
//  Medinology
//
//  Created by 양현서 on 2022/07/20.
//

#ifndef native_code_hpp
#define native_code_hpp


void initData(bool _preg,int _age,int _weight,bool * _symptoms, int symptomlen, int _diseases);
void calcData(void);
int getDisID(int n);
int getProb(int n);
void initWeights(void);
void finalizeNative(void);

#endif /* native_code_hpp */
