class myData {
  public float[][] data;
  public int[] names;
  public myData(){
    this.data = data;
    this.names = names;
  }
}
myData fulldata = new myData();
myData trainingdata = new myData();
myData testdata = new myData();
float[] svmmean = new float[8];
float[] svmstd = new float[8];
int[] Cpow = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25};
int[] Gpow = {0};
float gamma,bestgamma,bestaccuracy;
int c,bestc;
float[][] resultaccuracy;

void findmodel()
{
  bestaccuracy = 0;
  resultaccuracy = new float[Gpow.length][Cpow.length];
  for(int k=0;k<Gpow.length;k++){
    for(int i=0;i<Cpow.length;i++){
      c = (int)pow(2, Cpow[i]);
      gamma = pow(2, Gpow[k]);
      model.setKernelParameters(0,2,1,gamma,c);
      SVMProblem problem = new SVMProblem();
      problem.setNumFeatures(8);
      problem.setSampleData(trainingdata.names, trainingdata.data);
      model.train(problem);
      resultaccuracy[k][i] = testModel(testdata);
      if(resultaccuracy[k][i]>bestaccuracy){bestgamma=Gpow[k]; bestc=Cpow[i]; bestaccuracy=resultaccuracy[k][i];}
    }
  }
  for(int k=0;k<Gpow.length;k++){
    for(int i=0;i<Cpow.length;i++){
      println(resultaccuracy[k][i]+"%");
    }
  }
  println("Best order Gamma: "+bestgamma+" & Best C: 2^"+bestc); 
  println("Best Acc: "+bestaccuracy);
}

void savemodel()
{
  for(int k=0;k<Gpow.length;k++){
    for(int i=0;i<Cpow.length;i++){
//      c = (int)pow(2, Cpow[i]);
//      gamma = pow(2, Gpow[k]);
      model.setKernelParameters(0,2,1,bestgamma,bestc);
      SVMProblem problem = new SVMProblem();
      problem.setNumFeatures(8);
      problem.setSampleData(fulldata.names, fulldata.data);
      model.train(problem);
      model.saveModel("model.txt");
    }
  }
  println("Best order Gamma: "+bestgamma+" & Best C: 2^"+bestc); 
  println("Best Acc: "+bestaccuracy);
}

void svmLoadData(String filename, myData data)
{  
  String[] textdata = loadStrings(filename); 
  data.data = new float[textdata.length/2][8]; 
  data.names = new int[textdata.length/2];
  for (int i=0; i<textdata.length; i++) {
  // 0.2.4.6.8th... lines are Names, 1.3.5.7.9th.. lines are Data
    if(i%2==0)data.names[i/2] = int(textdata[i]);
    else{
  // Each line is split into an array of floating point numbers.
      float[] values = float(split(textdata[i], "," )); 
      data.data[(i-1)/2][0] = values[0];  
      data.data[(i-1)/2][1] = values[1];
      data.data[(i-1)/2][2] = values[2];  
      data.data[(i-1)/2][3] = values[3];  
      data.data[(i-1)/2][4] = values[4];  
      data.data[(i-1)/2][5] = values[5]; 
      data.data[(i-1)/2][6] = values[6];  
      data.data[(i-1)/2][7] = values[7];   
    }
  }
}

void normData(myData data, boolean savenormdata)//Subtract by Minimum, Divide by Standard Deviation(To be Added : Remove frames with more than 2 STD deviation)
{
  float sumcolumn = 0;
  float squareddifference = 0;
  for(int i=0;i<8;i++){
    
    if(savenormdata){
      sumcolumn = 0;
      squareddifference = 0;
      for(int k=0;k<data.names.length;k++){
        sumcolumn += data.data[k][i]; //+= to sum for calculation of mean 
      }  
      mean[i] = sumcolumn/data.names.length;  //Actually Mean
      for(int jj=0;jj<data.names.length;jj++){
        squareddifference += (data.data[jj][i]-mean[i])*(data.data[jj][i]-mean[i]);
      }
      std[i] = sqrt(squareddifference/data.names.length); //Actually Standard Deviation
      
      String[] scalestring = {mean[0]+","+mean[1]+","+
      mean[2]+","+mean[3]+","+mean[4]+","+mean[5]+","+mean[6]+","+mean[7],
      std[0]+","+std[1]+","+std[2]+","+std[3]+","+std[4]+","+std[5]+","+
      std[6]+","+std[7]};
      saveStrings("../DepthIdentification/scaling.txt", scalestring);
    }
    for(int j=0;j<data.names.length;j++){
      data.data[j][i] = (data.data[j][i]-mean[i])/std[i];   //Subtract Mean and divide by Standard Deviation
    }
  }
}

float testModel(myData data)
{
  int[] results = new int[data.names.length];
  float accuracy = 0;
  for (int i=0; i<data.names.length; i++) {
    results[i] = (int)model.test(data.data[i]);
    if(results[i]==data.names[i]){
      accuracy+=1;
    }
  }
//  println("Accuracy for C(exp) "+Cpow+" and Gamma(exp) " +Gpow+" is "+(accuracy/data.names.length*100 +" %!"));
  float xx = accuracy/data.names.length*100;
  return xx;
}

void splitData(myData full, myData training, myData test)
{
  training.data = new float[full.names.length/2][8]; 
  training.names = new int[full.names.length/2];
  test.data = new float[full.names.length/2][8]; 
  test.names = new int[full.names.length/2];
  for(int i=0;i<full.names.length;i++){
    if(i%2==1){
      training.data[(i-1)/2] = full.data[i-1];
      test.data[(i-1)/2] = full.data[i];
      training.names[(i-1)/2] = full.names[i-1];
      test.names[(i-1)/2] = full.names[i];
    }
  }
}
