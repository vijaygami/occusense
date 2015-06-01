int numCrossValidate = 2;  // Minimum 2, make sure numsamples is divisable by this!!
float[] crossvalidacc = new float[numCrossValidate];
float bestaccuracy, resultaccuracy;

int[] maxdepth = {3, 4, 5, 8, 10, 15, 20, 25};
int[] minsamplecount = { 4, 5, 6, 7};
int[] numtrees = {5, 6, 7, 8, 9, 10, 15, 20, 25 ,30, 40, 60, 80, 100};
int maxCategories=10;
int bestmincount,bestmaxdepth,bestnumtrees;
//float[] priors = {1,1,1,1,1,1,1,1}; //weights of each feature

//Finds the best RF parameters using CrossValidation
void findmodel(){
 
	Table trainingData = loadTable("data.txt","csv"); 		//last column contains answers
  
	Mat trainingTraits = new Mat(	// Mat object (as required by OpenCV) containing training data		
		trainingData.getRowCount()*(numCrossValidate-1)/numCrossValidate,         
		trainingData.getColumnCount() - 1, 
		CvType.CV_32FC1             // 32 bit floating point data tpye      
	);

	Mat trainingAnswers = new Mat(	// Mat object containing training answers
		trainingData.getRowCount()*(numCrossValidate-1)/numCrossValidate,         
		1,                                  
		CvType.CV_32FC1                     
	);

	Mat testTraits = new Mat(		// test 
		trainingData.getRowCount()/numCrossValidate,         
		trainingData.getColumnCount() - 1, 
		CvType.CV_32FC1                   
	);

	Mat testAnswers = new Mat(		// test answers
		trainingData.getRowCount()/numCrossValidate,         
		1,                                  
		CvType.CV_32FC1                     
	);

	//Fill in the Mat objects with data from data.txt
	int trainingid=0,testid=0;
	for(int row = 0; row < trainingData.getRowCount(); row++){          //Converting CSV to Mats for RF
		for(int col = 0; col < trainingData.getColumnCount(); col++){
			if (row%numCrossValidate!=0){                        		//every odd row is training data
				if (col < trainingData.getColumnCount() - 1){
					trainingTraits.put(trainingid, col, trainingData.getFloat(row, col)); //0 to 7th column stored in training traits
				}  
				else{
					trainingAnswers.put(trainingid, 0, trainingData.getInt(row, col));  //8th which is the user id is the training answer
					trainingid++;                             			//counter for filling in the next row of the Mat object
				}
			}
			else{                                   					//even row is test data
				if (col < trainingData.getColumnCount() - 1){  
					testTraits.put(testid, col, trainingData.getFloat(row, col));
				}
				else{                                           
					testAnswers.put(testid, 0, trainingData.getInt(row, col));
					testid++;                                  			//counter for filling in the next row of the Mat object
				}
			}
		}
	}
  
  for(int x=0;x<minsamplecount.length;x++){
  for(int y=0;y<numtrees.length;y++){
  for(int z=0;z<maxdepth.length;z++){		//various combinations of paramters tried to find best accuracy
  
    for(int i=0; i<numCrossValidate;i++){	//not really needed, currently all it does is repeat the process with exact same test & train data, but since model may vary, results vary a bit and average is taken.	
	  //setting the variable types for the algorithm by passing a same sized Mat object with set to CV_VAR_NUMERICAL.(dimention is: (feature num + 1) x 1)
      Mat varType = new Mat(trainingData.getColumnCount(), 1, CvType.CV_8U );	 
      varType.setTo(new Scalar(0)); // 0 = CV_VAR_NUMERICAL.
	  
      //clasification problem so set last elemnt whihc is the answers position to CV_VAR_CATEGORICAL
	  varType.put(trainingData.getColumnCount() - 1, 0, 1); // 1 = CV_VAR_CATEGORICAL;
      
      //CvRTParams params = new CvRTParams();					//this object allows the setting of parameters for the algorithm
      forest.setMaxDepth(maxdepth[z]);					//max depth of tree
      forest.setMinSampleCount(minsamplecount[x]);		//min number of samples before splitting the tree
      //params.set_regression_accuracy(0);					//predicting clasifications rather than regressions
      //params.set_use_surrogates(false);						//we have a full data set
      //params.set_max_categories(maxCategories);
	//not exist??  params.set_priorities(priors); // should set priorities
      forest.setCalculateVarImportance(true);
      forest.setActiveVarCount(0);							//zero to automatically set
      forest.setTermCriteria(new TermCriteria(TermCriteria.MAX_ITER + TermCriteria.EPS,numtrees[y],0.0f));
    
      //Train the random forest object
      forest.clear();
      forest.train(trainingTraits, 0, trainingAnswers); // 0 = CV_ROW_SAMPLE
      
      // Now test against current test set
      int correctAnswers = 0;
      for(int j = 0; j < trainingData.getRowCount()/numCrossValidate; j++){
        if((int)forest.predict(testTraits.row(j)) == (int)testAnswers.get(j, 0)[0]){						//check prediction against actual answer
		  correctAnswers++;
		}	
      }
      crossvalidacc[i] = (float) correctAnswers*100/(trainingData.getRowCount()/numCrossValidate);
      println("cross valid acc is: " + crossvalidacc[i] + " for i " + i);
    }
	
    //Average accuracies for each cross-validated set at current parameters
    float sum = 0;
    for (int k=0; k<crossvalidacc.length; k++){
      sum += crossvalidacc[k];
    }
	resultaccuracy = sum/crossvalidacc.length;
	
	//save parameters if model is good
    if(resultaccuracy>bestaccuracy){		
      bestaccuracy=resultaccuracy;
      bestmincount = minsamplecount[x];
      bestnumtrees = numtrees[y];
      bestmaxdepth = maxdepth[z]; 
    }
  }	
  }
  }
  
  //print best combination of parameters
  println("Min Samples = "+bestmincount);
  println("Max Depth = "+bestmaxdepth);
  println("Num Trees = "+bestnumtrees);
  println("Best Accuracy = " +bestaccuracy+ " %");
}

void savemodel(){

  //train model on all available data this time round rather than training on half and testing on half as in 'findModel()'.
  Table trainingData = loadTable("data.txt","csv");
  
  Mat allTraits = new Mat(
    trainingData.getRowCount(),         
    trainingData.getColumnCount() - 1, 
    CvType.CV_32FC1                   
  );
  
  Mat allAnswers = new Mat(
    trainingData.getRowCount(),         
    1,                                  
    CvType.CV_32FC1                     
  );
  
  for(int row = 0; row < trainingData.getRowCount(); row++){	//fill in Mat object
    for(int col = 0; col < trainingData.getColumnCount(); col++){
      if (col < trainingData.getColumnCount() - 1)   
	    allTraits.put(row, col, trainingData.getFloat(row, col)); //features
      else                                           
	    allAnswers.put(row, 0, trainingData.getInt(row, col));	  //answers 	
    }
  }
  
  //Mat varType = new Mat(trainingData.getColumnCount(), 1, CvType.CV_8U );
  //varType.setTo(new Scalar(0)); // 0 = CV_VAR_NUMERICAL.
  //varType.put(trainingData.getColumnCount() - 1, 0, 1); // 1 = CV_VAR_CATEGORICAL;
  //CvRTParams params = new CvRTParams();
  forest.setMaxDepth(bestmaxdepth);
  forest.setMinSampleCount(bestmincount);
  //params.set_regression_accuracy(0);
  //params.set_use_surrogates(false);
  //params.set_max_categories(maxCategories);
  forest.setCalculateVarImportance(true);
  forest.setActiveVarCount(0);
  forest.setTermCriteria(new TermCriteria(TermCriteria.MAX_ITER + TermCriteria.EPS,bestnumtrees,0.0f));

  forest.clear();
  forest.train(allTraits, 0, allAnswers); // 0 = CV_ROW_SAMPLE
  //forest.save(forestfile);
  //println("saved model xml");
}
