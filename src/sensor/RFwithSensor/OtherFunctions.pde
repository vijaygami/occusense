
//*******************vijay added functions for RF***********************//
class cPersonMeans {
  /* Contains means of features for people already stored on database, hence global id exists */

  public int gpersonId;      // Global person ID
  public float[] featMean = new float[12];  // Feature dimensions with higher   

  // Constructor
  //public cPersonIdent(int gpersonId, float[] featMean) {
  public cPersonMeans() {
    this.gpersonId = gpersonId;
    this.featMean = featMean;
  }
}

float [] lookupMean (int gpersonId, ArrayList<cPersonMeans> personMeans){
  /* Returns means from global Arraylist <cPersonMeans> by looking up the gpersonId */

    for (int i=0; i<personMeans.size(); i++){
        if (gpersonId == personMeans.get(i).gpersonId){
          return (personMeans.get(i).featMean);
        }
    }
    
    return (null);                  //  Not found so return null. (should never occur)
}

float MSE (float[] feat1, float[] feat2){
  /* Returns MSE for features. (ensure both input arrays to be same size) */
  
  float MSE=0;
  for(int i=0; i<feat1.length; i++){
    MSE += (feat1[i]-feat2[i])*(feat1[i]-feat2[i]);
  }
  MSE=MSE/feat1.length;
  
  return (MSE);
} 


void saveMeans(ArrayList<cPersonMeans> personMeans){
  //saves means of the 12 features for all users in the structure 'personMeans' as comma separated values
  //first value is the global user ID.
  
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
  //loads means of the 12 features for all users into the global arrayList 'personMeans'.
  
  ArrayList<String> meandata = new ArrayList<String>();
  Collections.addAll(meandata, loadStrings("data/mean.txt"));
  
  //clear the list then fill with contents of the file
  personMeans.clear();  
  
  for(int i=0; i<meandata.size(); i++){
     cPersonMeans temp = new cPersonMeans();     //for some reason this needs to be inside loop, 
                                                 //otherwise the arraylist 'personMeans' gets filled 
                                                 //up with only copies of the last line in the text file
    
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
     
     personMeans.add(temp);
  }
}
























//---Find Mode of an int array----------------------------------------------------
int mode(int[] array) {             
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






void drawJointOrientation(int userId,int jointType,PVector pos,float length)
{
  // draw the joint orientation  
  PMatrix3D  orientation = new PMatrix3D();
  float confidence = context.getJointOrientationSkeleton(userId,jointType,orientation);
  if(confidence < 0.001f) 
    // nothing to draw, orientation data is useless
    return;
    
  pushMatrix();
    translate(pos.x,pos.y,pos.z);
    
    // set the local coordsys
    applyMatrix(orientation);
    
    // coordsys lines are 100mm long
    // x - r
    stroke(255,0,0,confidence * 200 + 55);
    line(0,0,0,
         length,0,0);
    // y - g
    stroke(0,255,0,confidence * 200 + 55);
    line(0,0,0,
         0,length,0);
    // z - b    
    stroke(0,0,255,confidence * 200 + 55);
    line(0,0,0,
         0,0,length);
  popMatrix();
}


void getBodyDirection(int userId,PVector centerPoint,PVector dir)
{
  PVector jointL = new PVector();
  PVector jointH = new PVector();
  PVector jointR = new PVector();
  float  confidence;
  
  // draw the joint position
  confidence = context.getJointPositionSkeleton(userId,SimpleOpenNI.SKEL_LEFT_SHOULDER,jointL);
  confidence = context.getJointPositionSkeleton(userId,SimpleOpenNI.SKEL_HEAD,jointH);
  confidence = context.getJointPositionSkeleton(userId,SimpleOpenNI.SKEL_RIGHT_SHOULDER,jointR);
  
  // take the neck as the center point
  confidence = context.getJointPositionSkeleton(userId,SimpleOpenNI.SKEL_NECK,centerPoint);
  
  /*  // manually calc the centerPoint
  PVector shoulderDist = PVector.sub(jointL,jointR);
  centerPoint.set(PVector.mult(shoulderDist,.5));
  centerPoint.add(jointR);
  */
  
  PVector up = PVector.sub(jointH,centerPoint);
  PVector left = PVector.sub(jointR,centerPoint);
    
  dir.set(up.cross(left));
  dir.normalize();
}

// draw the skeleton with the selected joints
void drawSkeleton(int userId)
{
  strokeWeight(30);
//  if(detectfirst)println(millis()-mm);detectfirst=false;

  // to get the 3d joint data
  drawLimb(userId, SimpleOpenNI.SKEL_HEAD, SimpleOpenNI.SKEL_NECK);

  drawLimb(userId, SimpleOpenNI.SKEL_NECK, SimpleOpenNI.SKEL_LEFT_SHOULDER);
  drawLimb(userId, SimpleOpenNI.SKEL_LEFT_SHOULDER, SimpleOpenNI.SKEL_LEFT_ELBOW);
  drawLimb(userId, SimpleOpenNI.SKEL_LEFT_ELBOW, SimpleOpenNI.SKEL_LEFT_HAND);

  drawLimb(userId, SimpleOpenNI.SKEL_NECK, SimpleOpenNI.SKEL_RIGHT_SHOULDER);
  drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_SHOULDER, SimpleOpenNI.SKEL_RIGHT_ELBOW);
  drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_ELBOW, SimpleOpenNI.SKEL_RIGHT_HAND);

  drawLimb(userId, SimpleOpenNI.SKEL_LEFT_SHOULDER, SimpleOpenNI.SKEL_TORSO);
  drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_SHOULDER, SimpleOpenNI.SKEL_TORSO);

  drawLimb(userId, SimpleOpenNI.SKEL_TORSO, SimpleOpenNI.SKEL_LEFT_HIP);
  drawLimb(userId, SimpleOpenNI.SKEL_LEFT_HIP, SimpleOpenNI.SKEL_LEFT_KNEE);
  drawLimb(userId, SimpleOpenNI.SKEL_LEFT_KNEE, SimpleOpenNI.SKEL_LEFT_FOOT);

  drawLimb(userId, SimpleOpenNI.SKEL_TORSO, SimpleOpenNI.SKEL_RIGHT_HIP);
  drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_HIP, SimpleOpenNI.SKEL_RIGHT_KNEE);
  drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_KNEE, SimpleOpenNI.SKEL_RIGHT_FOOT);   
}

void drawLimb(int userId,int jointType1,int jointType2)
{
  PVector jointPos1 = new PVector();
  PVector jointPos2 = new PVector();
  float  confidence;
  
  // draw the joint position
  confidence = context.getJointPositionSkeleton(userId,jointType1,jointPos1);
  confidence = context.getJointPositionSkeleton(userId,jointType2,jointPos2);

//  stroke(255,0,0,confidence * 200 + 155);
//  stroke(255,0,0,map(confidence,0,1,0,255));
  if(confidence==1)stroke(255,255,0,255);
  else if(confidence>0.6)stroke(255,0,0,255);
  line(jointPos1.x,jointPos1.y,jointPos1.z,
       jointPos2.x,jointPos2.y,jointPos2.z);
  
//  drawJointOrientation(userId,jointType1,jointPos1,50);
}


