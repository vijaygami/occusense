//  // draw body direction
//  getBodyDirection(userId,bodyCenter,bodyDir);
//  
//  bodyDir.mult(200);  // 200mm length
//  bodyDir.add(bodyCenter);
//  
//  stroke(255,200,200);
//  line(bodyCenter.x,bodyCenter.y,bodyCenter.z,
//       bodyDir.x ,bodyDir.y,bodyDir.z);
//
//  strokeWeight(1);
////------------------------------------  
//  if(calclength)calclength = false;

void drawJointOrientation(int userId,int jointType,PVector pos,float length)
{
  // draw the joint orientation  
  PMatrix3D  orientation = new PMatrix3D();
  float confidence = cam1.getJointOrientationSkeleton(userId,jointType,orientation);
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
  confidence = cam1.getJointPositionSkeleton(userId,SimpleOpenNI.SKEL_LEFT_SHOULDER,jointL);
  confidence = cam1.getJointPositionSkeleton(userId,SimpleOpenNI.SKEL_HEAD,jointH);
  confidence = cam1.getJointPositionSkeleton(userId,SimpleOpenNI.SKEL_RIGHT_SHOULDER,jointR);
  
  // take the neck as the center point
  confidence = cam1.getJointPositionSkeleton(userId,SimpleOpenNI.SKEL_NECK,centerPoint);
  
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
void drawSkeleton(int userId, SimpleOpenNI curr)
{
  strokeWeight(30);
//  if(detectfirst)println(millis()-mm);detectfirst=false;

  // to get the 3d joint data
  drawLimb(userId, SimpleOpenNI.SKEL_HEAD, SimpleOpenNI.SKEL_NECK, curr);

  drawLimb(userId, SimpleOpenNI.SKEL_NECK, SimpleOpenNI.SKEL_LEFT_SHOULDER,curr);
  drawLimb(userId, SimpleOpenNI.SKEL_LEFT_SHOULDER, SimpleOpenNI.SKEL_LEFT_ELBOW,curr);
  drawLimb(userId, SimpleOpenNI.SKEL_LEFT_ELBOW, SimpleOpenNI.SKEL_LEFT_HAND,curr);

  drawLimb(userId, SimpleOpenNI.SKEL_NECK, SimpleOpenNI.SKEL_RIGHT_SHOULDER,curr);
  drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_SHOULDER, SimpleOpenNI.SKEL_RIGHT_ELBOW,curr);
  drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_ELBOW, SimpleOpenNI.SKEL_RIGHT_HAND,curr);

  drawLimb(userId, SimpleOpenNI.SKEL_LEFT_SHOULDER, SimpleOpenNI.SKEL_TORSO,curr);
  drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_SHOULDER, SimpleOpenNI.SKEL_TORSO,curr);

  drawLimb(userId, SimpleOpenNI.SKEL_TORSO, SimpleOpenNI.SKEL_LEFT_HIP,curr);
  drawLimb(userId, SimpleOpenNI.SKEL_LEFT_HIP, SimpleOpenNI.SKEL_LEFT_KNEE,curr);
  drawLimb(userId, SimpleOpenNI.SKEL_LEFT_KNEE, SimpleOpenNI.SKEL_LEFT_FOOT,curr);

  drawLimb(userId, SimpleOpenNI.SKEL_TORSO, SimpleOpenNI.SKEL_RIGHT_HIP,curr);
  drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_HIP, SimpleOpenNI.SKEL_RIGHT_KNEE,curr);
  drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_KNEE, SimpleOpenNI.SKEL_RIGHT_FOOT,curr);   
}

void drawLimb(int userId,int jointType1,int jointType2, SimpleOpenNI currcam)
{
  PVector jointPos1 = new PVector();
  PVector jointPos2 = new PVector();
  float  confidence;
  
  // draw the joint position
  confidence = currcam.getJointPositionSkeleton(userId,jointType1,jointPos1);
  confidence = currcam.getJointPositionSkeleton(userId,jointType2,jointPos2);

//  stroke(255,0,0,confidence * 200 + 155);
//  stroke(255,0,0,map(confidence,0,1,0,255));
  if(confidence==1)stroke(255,255,0,255);
  else if(confidence>0.6)stroke(255,0,0,255);
  line(jointPos1.x,jointPos1.y,jointPos1.z,
       jointPos2.x,jointPos2.y,jointPos2.z);
  
//  drawJointOrientation(userId,jointType1,jointPos1,50);
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

//void stop(){
//  socket.stop();
//}
//void websocketOnMessage(WebSocketConnection con, String msg){
//  println(msg);
//}
//void websocketOnOpen(WebSocketConnection con){
//  println("A client joined");
//}
//void websocketOnClosed(WebSocketConnection con){
//  println("A client left");
//}

//////------------------RE-IDENTIFY USERS (TBC:USING DIRECTED ACYCLIC GRAPH COMPARISONS??)-------------------------------------    
//        int closestID = 0;        
//        float[] distance = new float[data.length];
//        for(int k=0;k<data.length;k++){
//          distance[k] += 0*abs(unidentified[i][0]-data[k][0]);
//          distance[k] += 0.2*abs(unidentified[i][1]-data[k][1]);
//          distance[k] += 0*abs(unidentified[i][2]-data[k][2]);
//          distance[k] += 0.5*abs(unidentified[i][3]-data[k][3]);
//          distance[k] += 0.7*abs(unidentified[i][4]-data[k][4]);
//          distance[k] += 0.4*abs(unidentified[i][5]-data[k][5]);
//          distance[k] += 0.2*abs(unidentified[i][6]-data[k][6]);
//          distance[k] += 0.8*abs(unidentified[i][7]-data[k][7]);
//          if(k!=0 && distance[k]<distance[closestID]) closestID = k;
////          println("Error with "+names[k]+" is "+distance[k]);
//        }
////Now we know which user he/she is closest to
//        println("User "+userList[i]+" is "+names[closestID]);
//        identityfound[i] = closestID+1;  //index+1, see above

//        switch(svmresult){
//          case 1 : println("Augustine");break;
//          case 2 : println("Tim");break;
//          case 3 : println("Tommy");break;
//          case 4 : println("Shuo Yan");break;
//          case 5 : println("Jeremy");break;
//        }

//  case ' ':
////---For each unidentified user--------------
//    for(int i=0;i<userList.length;i++){
//      int ii = userList[i]-1;
//      boolean withinthreshold = true;
//      if(cam1.isTrackingSkeleton(userList[i])&&userconfidence[i]>0.6){ //if(idguess[userId-1][idcount]!=0)
////-------------------USING SVM TO RE-IDENTIFY---------------------------------  
//        for(int j=0;j<mean.length;j++){
//          copyunidentified[i][j] += unidentified[i][j];               //Copy unidentified matrix for Threshold Comparison (Not part of SVM)
//          unidentified[i][j] = (unidentified[i][j]-mean[j])/std[j];   //Normalize by subtracting mean and dividing by standard deviation
//        } 
//        idguess[ii][idguessindex[ii]] = (int)model.test(unidentified[i]);
//        if(idguessindex[ii]==idcount){
//          idguessindex[ii] = mode(idguess[ii]);               //Calculate mode of all estimates, assign to idguessindex as final identity
//          if(!idused[idguessindex[ii]]){
//            for(int j=0;j<mean.length;j++){                   //Now perform THRESHOLD COMPARISON to cross-check SVM's result
//              if((copyunidentified[i][j]/(idcount+1))-means[idguessindex[ii]-1][j]>0.3*stds[idguessindex[ii]-1][j])withinthreshold=false; 
//            }
//            if(withinthreshold){
//            cam1.stopTrackingSkeleton(userList[i]);        //Stop tracking skeleton once final identity confirmed
//            idused[idguessindex[ii]] = true;
//            }else{idguessindex[ii]=0;idguess[ii][idcount]=0;} //Restart id process again, Threshold Comparison failed!!         
//          }else{idguessindex[ii]=0;idguess[ii][idcount]=0;}   //Restart id process again, can't have two people with the same id
//          copyunidentified[i] = new float[mean.length];       //Reset copyunidentified for next id threshold comparison
//        }      
//        else idguessindex[ii]++;                              //Increment idguessindex for id estimation        
//      }
//    }
//    break;
