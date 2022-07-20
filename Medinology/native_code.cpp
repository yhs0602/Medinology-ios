//
//  native_code.cpp
//  Medinology
//
//  Created by 양현서 on 2022/07/20.
//

#include "native_code.hpp"

#include <string.h>
#include <iostream>
#include <fstream>
#include "eigen/Eigen/Dense"
extern "C" {
#include "log.h"
}
#include<stdio.h>
using namespace Eigen;
using namespace std;
//ofstream logger("/sdcard/predictlog.txt");

static void Do();
double identity_function(double x);
double step_function(double x);
double sigmoid(double x);
double sigmoid_grad(double x);
double relu(double x);
double expfunc(double x);
//FIXME!!!!!!!!!!!!!!!!!!!!!!!!!!
double relu_grad(double x);
MatrixXd identityFunction(MatrixXd x);
MatrixXd stepFunction(MatrixXd x);
MatrixXd Sigmoid(MatrixXd x);
MatrixXd Sigmoid_Grad(MatrixXd x);
MatrixXd Softmax(MatrixXd x);
void buildNormalDist(MatrixXd dest,int sx,int sy);

void LoadWeights(const char *filename);



double identity_function(double x)
{
    return x;
}

double step_function(double x)
{
    if(x>0)
        return 1;
    return 0;
}

double sigmoid(double x)
{
    return 1.0/(1.0+exp(-x));
}

double sigmoid_grad(double x)
{
    double s=sigmoid(x);
    return (1.0-s)*s;
}

double relu(double x)
{
    if(x>0)return x;
    return 0.0;
}

//FIXME!!!!!!!!!!!!!!!!!!!!!!!!!!
double relu_grad(double x)
{
    return relu(x);
}

double expfunc(double x)
{
    return exp(x);
}

MatrixXd IdentityFunction(MatrixXd x)
{
    return x;
}

MatrixXd StepFunction(MatrixXd x)
{
    MatrixXd m=x;
    m.unaryExpr(&step_function);
    return m;
}

MatrixXd Sigmoid(MatrixXd x)
{
    MatrixXd m=x;
    m.unaryExpr(&sigmoid);
    return m;
}

MatrixXd Sigmoid_Grad(MatrixXd x)
{
    MatrixXd m=x;
    m.unaryExpr(&sigmoid_grad);
    return m;
}

MatrixXd Relu(MatrixXd x)
{
    MatrixXd m=x;
    m.unaryExpr(&relu);
    return m;
}
/*
 MatrixXd Relu_grad()
 {
 MatrixXd m=MatrixXf::Zero();
 m.unaryExpr(&relu);
 return m;
 }
 */
MatrixXd Softmax(MatrixXd x)
{
    MatrixXd y=x.array()-x.maxCoeff();
    y.unaryExpr(&expfunc);
    double s=y.sum();
    return y/s;
}

float cross_entropy_error(MatrixXd y,MatrixXd t)
{
    int i,j;
    t.maxCoeff(&i,&j);
    return -log(y(0,j));
}

class Layer
{
public:
    virtual MatrixXd forward(MatrixXd x)=0;
    virtual MatrixXd backward(MatrixXd dout)=0;
};
class SigmoidLayer:public Layer
{
public:
    MatrixXd forward(MatrixXd x)
    {
        out=Sigmoid(x);
        return out;
    }
    MatrixXd backward(MatrixXd dout)
    {
        MatrixXd dx=Sigmoid_Grad(out);
        dx*=dout(0,0);
        return dx;
    }
    MatrixXd out;
};

/*
 class Sigmoid:
 def __init__(self):
 self.out = None
 
 def forward(self, x):
 out = sigmoid(x)
 self.out = out
 return out
 
 def backward(self, dout):
 dx = dout * (1.0 - self.out) * self.out
 
 return dx
 */
class AffineLayer:public Layer
{
public:
    MatrixXd forward(MatrixXd px)
    {
        x=px;
        MatrixXd out=x*W+b;
        return out;
    }
    MatrixXd backward(MatrixXd dout)
    {
        MatrixXd dx=dout*(W.transpose());
        dW=(x.transpose())*dout;
        //    db=dout.sum();
        return dx;
    }
    AffineLayer(MatrixXd pW,MatrixXd pb)
    {
        W=pW;
        b=pb;
    }
    MatrixXd x,W,b,dW,db;
};
/*
 
 class Affine:
 def __init__(self, W, b):
 self.W = W
 self.b = b
 
 self.x = None
 self.original_x_shape = None
 # 가중치와 편향 매개변수의 미분
 self.dW = None
 self.db = None
 
 def forward(self, x):
 # 텐서 대응
 self.original_x_shape = x.shape
 x = x.reshape(x.shape[0], -1)
 self.x = x
 
 out = np.dot(self.x, self.W) + self.b
 
 return out
 
 def backward(self, dout):
 dx = np.dot(dout, self.W.T)
 self.dW = np.dot(self.x.T, dout)
 self.db = np.sum(dout, axis=0)
 
 dx = dx.reshape(*self.original_x_shape)  # 입력 데이터 모양 변경(텐서 대응)
 return dx
 */
class SoftmaxWithLossLayer:public Layer
{
public:
    MatrixXd forward(MatrixXd x,MatrixXd pt)
    {
        t=pt;
        y=Softmax(x);
        loss=MatrixXd::Constant(1,1,cross_entropy_error(y,t));
        return loss;
    }
    MatrixXd backward(MatrixXd dout)
    {
        MatrixXd dx=y.array()-t.array();
        return dx;
    }
    SoftmaxWithLossLayer()
    {
        
    }
    MatrixXd forward(MatrixXd x){
        return y; // TODO
    }
    MatrixXd y,t,loss;
};
/*
 
 class SoftmaxWithLoss:
 def __init__(self):
 self.loss = None # 손실함수
 self.y = None    # softmax의 출력
 self.t = None    # 정답 레이블(원-핫 인코딩 형태)
 
 def forward(self, x, t):
 self.t = t
 self.y = softmax(x)
 self.loss = cross_entropy_error(self.y, self.t)
 
 return self.loss
 
 def backward(self, dout=1):
 batch_size = self.t.shape[0]
 if self.t.size == self.y.size: # 정답 레이블이 원-핫 인코딩 형태일 때
 dx = (self.y - self.t) / batch_size
 else:
 dx = self.y.copy()
 dx[np.arange(batch_size), self.t] -= 1
 dx = dx / batch_size
 
 return dx
 
 */

class TwoLayerNet
{
public:
    MatrixXd W1,W2,b1,b2;
    MatrixXd gradW1,gradW2,gradb1,gradb2;
    Layer *layers[3];
    Layer *lastLayer;
    TwoLayerNet(int inputsize,int hiddensize,int outputsize)
    {
        W1=MatrixXd(inputsize,hiddensize);
        W2=MatrixXd(hiddensize,outputsize);
        b1=MatrixXd::Zero(1,hiddensize);
        b2=MatrixXd::Zero(1,outputsize);
        //buildNormalDist(W1,inputsize,hiddensize);
        //buildNormalDist(W2,hiddensize,outputsize);
        float scale1=sqrt(1.0/float(inputsize));
        float scale2=sqrt(1.0/float(hiddensize));
        W1*=scale1;
        W2*=scale2;
        layers[0]=new AffineLayer(W1,b1);
        layers[1]=new SigmoidLayer();
        layers[2]=new AffineLayer(W2,b2);
        lastLayer=new SoftmaxWithLossLayer();
        //layers[3]=lastLayer;
    }
    ~TwoLayerNet()
    {
        delete layers[0];
        delete layers[1];
        delete layers[2];
        //delete layers[3];
        delete lastLayer;
    }
    MatrixXd Predict(MatrixXd x)
    {
        for(int i=0;i<3;++i)
        {
            x=layers[i]->forward(x);
        }
        return x;
    }
    MatrixXd Loss(MatrixXd x,MatrixXd t)
    {
        MatrixXd y=Predict(x);
        return ((SoftmaxWithLossLayer*)lastLayer)->forward(y,t);
    }
    void Gradient(MatrixXd x,MatrixXd t)
    {
        Loss(x,t);
        MatrixXd dout=MatrixXd::Constant(1,1,1);
        dout=lastLayer->backward(dout);
        for(int i=0;i<3;++i)
        {
            dout=layers[2-i]->backward(dout);
        }
        gradW1=(((AffineLayer*)layers[0])->dW);
        gradb1=(((AffineLayer*)layers[0])->db);
        gradW2=(((AffineLayer*)layers[2])->dW);
        gradb2=(((AffineLayer*)layers[2])->db);
    }
    void updateLayers()
    {
        ((AffineLayer*)layers[0])->W=W1;
        ((AffineLayer*)layers[0])->b=b1;
        ((AffineLayer*)layers[2])->W=W2;
        ((AffineLayer*)layers[2])->b=b2;
    }
    MatrixXd getGradW1();
    MatrixXd getGradW2();
    MatrixXd getGradb1();
    MatrixXd getGradb2();
};

MatrixXd TwoLayerNet::getGradW1(){return gradW1;}
MatrixXd TwoLayerNet::getGradW2(){return gradW2;}
MatrixXd TwoLayerNet::getGradb1(){return gradb1;}
MatrixXd TwoLayerNet::getGradb2(){return gradb2;}

/*
 표준정규분포 만들기
 */
void buildNormalDist(MatrixXd dest,int sx,int sy)
{
    float * nums=new float[sx*sy];
    double sq2pi=sqrt(2*M_PI);
    sq2pi=1.0/sq2pi;
    float x=-10;
    float dx=20.0/(sx*sy);
    for(int i=0;i<sx*sy;++i)
    {
        nums[i]=sq2pi*exp(-x*x/2);
        x+=dx;
    }
    int nDest,nSour;
    float nTemp;
    srand(time(NULL));
    for(int i=0;i<sx*sy*2;i++)
    {
        nDest = rand()%(sx*sy);
        nSour = rand()%(sx*sy);
        
        nTemp = nums[nDest];
        nums[nDest] = nums[nSour];
        nums[nSour] = nTemp;
    }
    for(int r=0;r<sy;++r)
    {
        for(int c=0;c<sx;++c)
        {
            dest(r,c)=nums[r*sx+c];
        }
    }
    delete[] nums;
}
#define HIDDEN_LAYER 200
TwoLayerNet net(51,HIDDEN_LAYER,/*NUM_Diseases*/31);

void LoadWeights(const char *filename)
{
    FILE * input=fopen(filename,"rt");
    if(input==NULL)
    {
        return;
    }
    float data;
    int row,col;
    fscanf(input,"%d %d\n",&row,&col);
    for(int i= 0; i<row;++i)
    {
        for(int j=0;j<col;++j)
        {
            fscanf(input,"%f",&data);
            net.W1(i,j)=data;
        }
    }
    
    fscanf(input,"%d %d\n",&row,&col);
    for(int i= 0; i<row;++i)
    {
        for(int j=0;j<col;++j)
        {
            fscanf(input,"%f",&data);
            //printf("%d %d %f\n",i,j,data);
            net.W2(i,j)=data;
        }
    }/*
      fscanf(input,"%d %d\n",&row,&col);
      for(int i= 0; i<row;++i)
      {
      for(int j=0;j<col;++j)
      {
      fscanf(input,"%f",&data);
      net.W3(i,j)=data;
      }
      }
      fscanf(input,"%d %d\n",&row,&col);
      
      //printf("W2 %d %d",row,col);
      for(int i= 0; i<row;++i)
      {
      for(int j=0;j<col;++j)
      {
      fscanf(input,"%f",&data);
      //printf("%d %d %f\n",i,j,data);
      net.W4(i,j)=data;
      }
      }
      */
    fscanf(input,"%d %d\n",&row,&col);
    //printf("b1 %d %d",row,col);
    for(int i= 0; i<row;++i)
    {
        for(int j=0;j<col;++j)
        {
            fscanf(input,"%f",&data);
            //printf("%d %d %f\n",i,j,data);
            net.b1(i,j)=data;
        }
    }
    
    fscanf(input,"%d %d",&row,&col);
    
    //printf("b2 %d %d",row,col);
    for(int i= 0; i<row;++i)
    {
        for(int j=0;j<col;++j)
        {
            fscanf(input,"%f",&data);
            //printf("%d %d %f\n",i,j,data);
            net.b2(i,j)=data;
        }
    }
    /*
     fscanf(input,"%d %d\n",&row,&col);
     //printf("b1 %d %d",row,col);
     for(int i= 0; i<row;++i)
     {
     for(int j=0;j<col;++j)
     {
     fscanf(input,"%f",&data);
     //printf("%d %d %f\n",i,j,data);
     net.b3(i,j)=data;
     }
     }
     fscanf(input,"%d %d",&row,&col);
     
     //printf("b2 %d %d",row,col);
     for(int i= 0; i<row;++i)
     {
     for(int j=0;j<col;++j)
     {
     fscanf(input,"%f",&data);
     //printf("%d %d %f\n",i,j,data);
     net.b4(i,j)=data;
     }
     }
     */
    fclose(input);
    net.updateLayers();
}

bool preg;
int age;
int weight;
int symptomlen;
float *symptoms;
int disease1,disease2,disease3;
int prob1,prob2,prob3;
int diseasenum;
extern "C" {
void initData(bool _preg,int _age,int _weight,bool * _symptoms, int _symptomlen, int _diseases)
{
    preg=_preg;
    age=_age;
    diseasenum=_diseases;
    symptomlen = _symptomlen;
    symptoms= new float[symptomlen];
    for(int i=0;i<symptomlen;++i)
    {
        symptoms[i]=(float)symptoms[i];
    }
}
void calcData()
{
    MatrixXd x(1,symptomlen);
    for(int i=0;i<symptomlen;++i)
    {
        x(0,i)=symptoms[i];
    }
    MatrixXd result=net.Predict(x);    //1*numsisease
    result=Softmax(result);
    
    int i,j;
    
    float p1 =result.maxCoeff(&i,&j);//*100;
    prob1 = p1 * 100;
    result(i,j) = 0;
    disease1 = j;
    
    float p2 =result.maxCoeff(&i,&j);//*100;
    prob2 = p2 * 100;
    result(i,j)=0;
    disease2=j;
    
    float p3 =result.maxCoeff(&i,&j);//*100;
    prob3 = p3 * 100;
    disease3=j;
    
    debug("prob1...%f %i", p1, prob1);
    debug("prob2...%f %i", p2, prob2);
    debug("prob3...%f %i", p3, prob3);
}
int getDisID(int n)
{
    switch(n)
    {
        case 0:
            return disease1;
            break;
        case 1:
            return disease2;
            break;
        case 2:
            return disease3;
            break;
        default:
            break;
    }
    return 0;
}
int getProb(int n)
{
    switch(n)
    {
        case 0:
            return prob1;
            break;
        case 1:
            return prob2;
            break;
        case 2:
            return prob3;
            break;
        default:
            break;
    }
    return 0;
}

void initWeights(const char * path)
{
    LoadWeights(path);
    //    logger<<"weight successfully loaded"<<endl;
}


void finalizeNative()
{
    delete []symptoms;
    //delete net;
}

}
