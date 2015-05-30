float [] lookupMean (int gpersonId, ArrayList<cPersonMeans> personMeans){
  /* Returns means from global Arraylist <cPersonMeans> by looking up the gpersonId */

    for (int i=0; i<personMeans.size(); i++){
        if (gpersonId == personMeans.get(i).gpersonId){
          return (personMeans.get(i).featMean);
        }
    }
    
    return (null);                  //  Not found so return null. (should never occur)
}

float MSE(float[] feat1, float[] feat2){
  /* Returns MSE for features. (Ensure both input arrays are same size) */
  
  float MSE=0;

  for(int i=0; i<feat1.length; i++){
    MSE += (feat1[i]-feat2[i])*(feat1[i]-feat2[i]);   // Sum of squared error
  }

  MSE = MSE/feat1.length;   // Mean squared error
  
  return (MSE);
} 


void saveMeans(){
  /* Writes global personMeans ArrayList into mean.txt (CSV format). First value is the global user ID. */
  
  ArrayList<String> meandata = new ArrayList<String>();
  
  for(int i=0; i<personMeans.size(); i++){
    meandata.add(
      personMeans.get(i).gpersonId + "," +
      personMeans.get(i).featMean[0] + "," +
      personMeans.get(i).featMean[1] + "," +
      personMeans.get(i).featMean[2] + "," +
      personMeans.get(i).featMean[3] + "," +
      personMeans.get(i).featMean[4] + "," +
      personMeans.get(i).featMean[5] + "," +
      personMeans.get(i).featMean[6] + "," +
      personMeans.get(i).featMean[7] + "," +
      personMeans.get(i).featMean[8] + "," +
      personMeans.get(i).featMean[9] + "," +
      personMeans.get(i).featMean[10] + "," +
      personMeans.get(i).featMean[11]
      );
  }

  saveStrings("data/mean.txt", meandata.toArray(new String[meandata.size()]));
}


void loadMeans(){
  /* Loads means of the 12 features for all users into the global arrayList 'personMeans' */
  
  ArrayList<String> meandata = new ArrayList<String>();
  Collections.addAll(meandata, loadStrings("data/mean.txt"));
  
  // Clear the list then fill with contents of the file
  personMeans.clear();  
  
  for(int i=0; i<meandata.size(); i++){
    cPersonMeans temp = new cPersonMeans();

    float[] values = float(split(meandata.get(i), "," )); 

    temp.gpersonId = (int)values[0];
    temp.featMean[0]=values[1];
    temp.featMean[1]=values[2];
    temp.featMean[2]=values[3];
    temp.featMean[3]=values[4];
    temp.featMean[4]=values[5];
    temp.featMean[5]=values[6];
    temp.featMean[6]=values[7];
    temp.featMean[7]=values[8];
    temp.featMean[8]=values[9];
    temp.featMean[9]=values[10];
    temp.featMean[10]=values[11];
    temp.featMean[11]=values[12];

    personMeans.add(temp);    // Add object to global personMeans ArrayList
  }
}


int mode(int[] array) {
    /* Return mode of a list of numbers */

    int[] modeMap = new int [20];
    int maxEl = array[0];
    int maxCount = 1;

    for (int i = 0; i < array.length; i++) {
        int el = array[i];
        if (modeMap[el] == 0) {
            modeMap[el] = 1;
        }
        else {
            modeMap[el]++;
        }

        if (modeMap[el] > maxCount) {
            maxEl = el;
            maxCount = modeMap[el];
        }
    }
    
    return maxEl;
}








