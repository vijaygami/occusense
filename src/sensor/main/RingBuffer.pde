class RingBuffer
{
    Pose[] poseArray;
    Pose[] poseNormalizedArray;
    int  startOfBuffer = 0;
    Float d[][][] = new Float[10][framesGestureMax][framesInputMax];  // starting point euclidean distance
    int P[][][] = new int[10][framesGestureMax][framesInputMax];  // Cost
    Float D[][] = new Float[framesGestureMax][framesInputMax];  // End point
  
    // constructor
    RingBuffer () {
        poseArray = new Pose[framesInputMax];
        poseNormalizedArray = new Pose[framesInputMax];

        for(int m = 0; m < framesInputMax; m++) 
        {
            poseArray[m] = new Pose();
            poseNormalizedArray[m] = new Pose();            
            for(int n = 0; n < framesGestureMax; n++)
            {
                for(int moveID = 0; moveID < 10; moveID++)
                {
                    d[moveID][n][m] = 0.0;
                }
            }
        }
    }
 
    // a new pose will be saved to the ringbuffer (containing current and previous framesInputMax-1 frames)
    // the ring buffer mechanism uses one pointer: startOfBuffer to determine the current start of a pose
    void fillBuffer(Pose newPose) {
        startOfBuffer = (startOfBuffer + 1) % framesInputMax;
        counter++;
    
        // copy data
        poseArray[startOfBuffer].jointLeftShoulderRelative.x = newPose.jointLeftShoulderRelative.x;
        poseArray[startOfBuffer].jointLeftShoulderRelative.y = newPose.jointLeftShoulderRelative.y;
        poseArray[startOfBuffer].jointLeftShoulderRelative.z = newPose.jointLeftShoulderRelative.z;
        
        poseArray[startOfBuffer].jointLeftElbowRelative.x = newPose.jointLeftElbowRelative.x;
        poseArray[startOfBuffer].jointLeftElbowRelative.y = newPose.jointLeftElbowRelative.y;
        poseArray[startOfBuffer].jointLeftElbowRelative.z = newPose.jointLeftElbowRelative.z;
        
        poseArray[startOfBuffer].jointLeftHandRelative.x = newPose.jointLeftHandRelative.x;
        poseArray[startOfBuffer].jointLeftHandRelative.y = newPose.jointLeftHandRelative.y;
        poseArray[startOfBuffer].jointLeftHandRelative.z = newPose.jointLeftHandRelative.z;

        poseArray[startOfBuffer].jointRightShoulderRelative.x = newPose.jointRightShoulderRelative.x;
        poseArray[startOfBuffer].jointRightShoulderRelative.y = newPose.jointRightShoulderRelative.y;
        poseArray[startOfBuffer].jointRightShoulderRelative.z = newPose.jointRightShoulderRelative.z;
                
        poseArray[startOfBuffer].jointRightElbowRelative.x = newPose.jointRightElbowRelative.x;
        poseArray[startOfBuffer].jointRightElbowRelative.y = newPose.jointRightElbowRelative.y;
        poseArray[startOfBuffer].jointRightElbowRelative.z = newPose.jointRightElbowRelative.z;        
        
        poseArray[startOfBuffer].jointRightHandRelative.x = newPose.jointRightHandRelative.x;
        poseArray[startOfBuffer].jointRightHandRelative.y = newPose.jointRightHandRelative.y;
        poseArray[startOfBuffer].jointRightHandRelative.z = newPose.jointRightHandRelative.z;
    }

    // a new rotation normalized pose will be saved to the ringbuffer (containing current and previous framesInputMax-1 frames)
    // the ring buffer mechanism uses one pointer which is set in fillBufer(), not in this routine
    void fillBufferNormalized(Pose newPose) {    
        // copy data
        poseNormalizedArray[startOfBuffer].jointLeftShoulderRelative.x = newPose.jointLeftShoulderRelative.x;
        poseNormalizedArray[startOfBuffer].jointLeftShoulderRelative.y = newPose.jointLeftShoulderRelative.y;
        poseNormalizedArray[startOfBuffer].jointLeftShoulderRelative.z = newPose.jointLeftShoulderRelative.z;
        
        poseNormalizedArray[startOfBuffer].jointLeftElbowRelative.x = newPose.jointLeftElbowRelative.x;
        poseNormalizedArray[startOfBuffer].jointLeftElbowRelative.y = newPose.jointLeftElbowRelative.y;
        poseNormalizedArray[startOfBuffer].jointLeftElbowRelative.z = newPose.jointLeftElbowRelative.z;
        
        poseNormalizedArray[startOfBuffer].jointLeftHandRelative.x = newPose.jointLeftHandRelative.x;
        poseNormalizedArray[startOfBuffer].jointLeftHandRelative.y = newPose.jointLeftHandRelative.y;
        poseNormalizedArray[startOfBuffer].jointLeftHandRelative.z = newPose.jointLeftHandRelative.z;

        poseNormalizedArray[startOfBuffer].jointRightShoulderRelative.x = newPose.jointRightShoulderRelative.x;
        poseNormalizedArray[startOfBuffer].jointRightShoulderRelative.y = newPose.jointRightShoulderRelative.y;
        poseNormalizedArray[startOfBuffer].jointRightShoulderRelative.z = newPose.jointRightShoulderRelative.z;
                
        poseNormalizedArray[startOfBuffer].jointRightElbowRelative.x = newPose.jointRightElbowRelative.x;
        poseNormalizedArray[startOfBuffer].jointRightElbowRelative.y = newPose.jointRightElbowRelative.y;
        poseNormalizedArray[startOfBuffer].jointRightElbowRelative.z = newPose.jointRightElbowRelative.z;        
        
        poseNormalizedArray[startOfBuffer].jointRightHandRelative.x = newPose.jointRightHandRelative.x;
        poseNormalizedArray[startOfBuffer].jointRightHandRelative.y = newPose.jointRightHandRelative.y;
        poseNormalizedArray[startOfBuffer].jointRightHandRelative.z = newPose.jointRightHandRelative.z;
    }
  
    void copyBuffer(int which) {
        println("copy buffer!");

        for (int i=0; i<framesGestureMax; i++) {
            move[which][i].jointLeftShoulderRelative.x = poseArray[(startOfBuffer + i + framesGestureMax) % framesInputMax].jointLeftShoulderRelative.x;
            move[which][i].jointLeftShoulderRelative.y = poseArray[(startOfBuffer + i + framesGestureMax) % framesInputMax].jointLeftShoulderRelative.y;
            move[which][i].jointLeftShoulderRelative.z = poseArray[(startOfBuffer + i + framesGestureMax) % framesInputMax].jointLeftShoulderRelative.z;            

            move[which][i].jointLeftElbowRelative.x = poseArray[(startOfBuffer + i + framesGestureMax) % framesInputMax].jointLeftElbowRelative.x;
            move[which][i].jointLeftElbowRelative.y = poseArray[(startOfBuffer + i + framesGestureMax) % framesInputMax].jointLeftElbowRelative.y;
            move[which][i].jointLeftElbowRelative.z = poseArray[(startOfBuffer + i + framesGestureMax) % framesInputMax].jointLeftElbowRelative.z;

            move[which][i].jointLeftHandRelative.x = poseArray[(startOfBuffer + i + framesGestureMax) % framesInputMax].jointLeftHandRelative.x;
            move[which][i].jointLeftHandRelative.y = poseArray[(startOfBuffer + i + framesGestureMax) % framesInputMax].jointLeftHandRelative.y;
            move[which][i].jointLeftHandRelative.z = poseArray[(startOfBuffer + i + framesGestureMax) % framesInputMax].jointLeftHandRelative.z;
      
            move[which][i].jointRightShoulderRelative.x = poseArray[(startOfBuffer + i + framesGestureMax) % framesInputMax].jointRightShoulderRelative.x;
            move[which][i].jointRightShoulderRelative.y = poseArray[(startOfBuffer + i + framesGestureMax) % framesInputMax].jointRightShoulderRelative.y;
            move[which][i].jointRightShoulderRelative.z = poseArray[(startOfBuffer + i + framesGestureMax) % framesInputMax].jointRightShoulderRelative.z;            

            move[which][i].jointRightElbowRelative.x = poseArray[(startOfBuffer + i + framesGestureMax) % framesInputMax].jointRightElbowRelative.x;
            move[which][i].jointRightElbowRelative.y = poseArray[(startOfBuffer + i + framesGestureMax) % framesInputMax].jointRightElbowRelative.y;
            move[which][i].jointRightElbowRelative.z = poseArray[(startOfBuffer + i + framesGestureMax) % framesInputMax].jointRightElbowRelative.z;            

            move[which][i].jointRightHandRelative.x = poseArray[(startOfBuffer + i + framesGestureMax) % framesInputMax].jointRightHandRelative.x;
            move[which][i].jointRightHandRelative.y = poseArray[(startOfBuffer + i + framesGestureMax) % framesInputMax].jointRightHandRelative.y;
            move[which][i].jointRightHandRelative.z = poseArray[(startOfBuffer + i + framesGestureMax) % framesInputMax].jointRightHandRelative.z;
        }
    }  
  
    // calculate the cost of one frame
    float cost(int moveID, int j, int i) 
    {

   
    
  float mse = 0.0;
        
        mse +=   sqrt(   pow((move[moveID][j].jointLeftShoulderRelative.x - poseArray[i].jointLeftShoulderRelative.x), 2) 
            +   pow((move[moveID][j].jointLeftShoulderRelative.y - poseArray[i].jointLeftShoulderRelative.y), 2)
            +   pow((move[moveID][j].jointLeftShoulderRelative.z - poseArray[i].jointLeftShoulderRelative.z), 2) );
        mse +=   sqrt(   pow((move[moveID][j].jointLeftElbowRelative.x - poseArray[i].jointLeftElbowRelative.x), 2) 
            +   pow((move[moveID][j].jointLeftElbowRelative.y - poseArray[i].jointLeftElbowRelative.y), 2)
            +   pow((move[moveID][j].jointLeftElbowRelative.z - poseArray[i].jointLeftElbowRelative.z), 2) );
        mse +=   sqrt(   pow((move[moveID][j].jointLeftHandRelative.x - poseArray[i].jointLeftHandRelative.x), 2) 
            +   pow((move[moveID][j].jointLeftHandRelative.y - poseArray[i].jointLeftHandRelative.y), 2)
            +   pow((move[moveID][j].jointLeftHandRelative.z - poseArray[i].jointLeftHandRelative.z), 2) );
        mse +=     sqrt(   pow((move[moveID][j].jointRightShoulderRelative.x - poseArray[i].jointRightShoulderRelative.x), 2) 
            +   pow((move[moveID][j].jointRightShoulderRelative.y - poseArray[i].jointRightShoulderRelative.y), 2)
            +   pow((move[moveID][j].jointRightShoulderRelative.z - poseArray[i].jointRightShoulderRelative.z), 2) );
        mse +=     sqrt(   pow((move[moveID][j].jointRightElbowRelative.x - poseArray[i].jointRightElbowRelative.x), 2) 
            +   pow((move[moveID][j].jointRightElbowRelative.y - poseArray[i].jointRightElbowRelative.y), 2)
            +   pow((move[moveID][j].jointRightElbowRelative.z - poseArray[i].jointRightElbowRelative.z), 2) );
        mse +=     sqrt(   pow((move[moveID][j].jointRightHandRelative.x - poseArray[i].jointRightHandRelative.x), 2) 
            +   pow((move[moveID][j].jointRightHandRelative.y - poseArray[i].jointRightHandRelative.y), 2)
            +   pow((move[moveID][j].jointRightHandRelative.z - poseArray[i].jointRightHandRelative.z), 2) );
 
        return mse;
    }

    // calculate the cost of one rotation normalized frame
    float costNormalized(int moveID, int j, int i) 
    {
 
  float mse = 0.0;
        
        mse +=   sqrt(   pow((move[moveID][j].jointLeftShoulderRelative.x - poseNormalizedArray[i].jointLeftShoulderRelative.x), 2) 
            +   pow((move[moveID][j].jointLeftShoulderRelative.y - poseNormalizedArray[i].jointLeftShoulderRelative.y), 2)
            +   pow((move[moveID][j].jointLeftShoulderRelative.z - poseNormalizedArray[i].jointLeftShoulderRelative.z), 2) );
        mse +=   sqrt(   pow((move[moveID][j].jointLeftElbowRelative.x - poseNormalizedArray[i].jointLeftElbowRelative.x), 2) 
            +   pow((move[moveID][j].jointLeftElbowRelative.y - poseNormalizedArray[i].jointLeftElbowRelative.y), 2)
            +   pow((move[moveID][j].jointLeftElbowRelative.z - poseNormalizedArray[i].jointLeftElbowRelative.z), 2) );
        mse +=   sqrt(   pow((move[moveID][j].jointLeftHandRelative.x - poseNormalizedArray[i].jointLeftHandRelative.x), 2) 
            +   pow((move[moveID][j].jointLeftHandRelative.y - poseNormalizedArray[i].jointLeftHandRelative.y), 2)
            +   pow((move[moveID][j].jointLeftHandRelative.z - poseNormalizedArray[i].jointLeftHandRelative.z), 2) );
        mse +=     sqrt(   pow((move[moveID][j].jointRightShoulderRelative.x - poseNormalizedArray[i].jointRightShoulderRelative.x), 2) 
            +   pow((move[moveID][j].jointRightShoulderRelative.y - poseNormalizedArray[i].jointRightShoulderRelative.y), 2)
            +   pow((move[moveID][j].jointRightShoulderRelative.z - poseNormalizedArray[i].jointRightShoulderRelative.z), 2) );
        mse +=     sqrt(   pow((move[moveID][j].jointRightElbowRelative.x - poseNormalizedArray[i].jointRightElbowRelative.x), 2) 
            +   pow((move[moveID][j].jointRightElbowRelative.y - poseNormalizedArray[i].jointRightElbowRelative.y), 2)
            +   pow((move[moveID][j].jointRightElbowRelative.z - poseNormalizedArray[i].jointRightElbowRelative.z), 2) );
        mse +=     sqrt(   pow((move[moveID][j].jointRightHandRelative.x - poseNormalizedArray[i].jointRightHandRelative.x), 2) 
            +   pow((move[moveID][j].jointRightHandRelative.y - poseNormalizedArray[i].jointRightHandRelative.y), 2)
            +   pow((move[moveID][j].jointRightHandRelative.z - poseNormalizedArray[i].jointRightHandRelative.z), 2) );
 
        return mse;
    }
  
    // calculate the 'cost' of the different moves using DTW
    float pathcost(int moveID)
    {      
        if (normRotation[moveID])
  {
            // evaluate only for framesGesture[moveID] frames (the last frames)
            for(int n=(framesGestureMax-framesGesture[moveID]);n<framesGestureMax;n++)  // framesGesture used in parsexml to load how many frames there are from setupxml
            {
                  d[moveID][n][(startOfBuffer + framesInputMax - 1) % framesInputMax] = costNormalized( moveID, (n+framesGestureMax+1)% framesGestureMax,(0 + startOfBuffer) % framesInputMax);
         // println( d[moveID][n][(startOfBuffer + framesInputMax - 1) % framesInputMax]);
            }
  }
        else
        {
            // evaluate only for framesGesture[moveID] frames (the last frames)
            for(int n=(framesGestureMax-framesGesture[moveID]);n<framesGestureMax;n++)
            {
                  d[moveID][n][(startOfBuffer + framesInputMax - 1) % framesInputMax] = cost( moveID, (n+framesGestureMax+1)% framesGestureMax,(0 + startOfBuffer) % framesInputMax);
            }
        }
              //println("counter " + counter);
              //if(counter == 1){ println(millis());}
        float cost = 0;
        if (counter > framesInputMax+1)
        {
            D[framesGestureMax-framesGesture[moveID]][framesInputMax-2*framesGesture[moveID]] = d[moveID][framesGestureMax-framesGesture[moveID]][(startOfBuffer) % framesInputMax];
      P[moveID][framesGestureMax-framesGesture[moveID]][framesInputMax-2*framesGesture[moveID]] = 0;
    
            // evaluate only for framesGesture[moveID] frames (the last frames)
            for(int n=(framesGestureMax-framesGesture[moveID]+1);n<framesGestureMax;n++)
      {
                D[n][framesInputMax-2*framesGesture[moveID]]=d[moveID][n][(startOfBuffer) % (2*framesGesture[moveID])] + D[n-1][framesInputMax-2*framesGesture[moveID]];
                P[moveID][n][framesInputMax-2*framesGesture[moveID]] = 1;
      }

      for(int m=(framesInputMax-2*framesGesture[moveID])+1;m<framesInputMax;m++)
      {
                D[framesGestureMax-framesGesture[moveID]][m] = d[moveID][0][(m + startOfBuffer) % (2*framesGesture[moveID])];
                P[moveID][framesGestureMax-framesGesture[moveID]][m] = -1;
      }
    
            // evaluate only for framesGesture[moveID] frames (the last frames)
            for(int n=(framesGestureMax-framesGesture[moveID]+1);n<framesGestureMax;n++)
      {
          for(int m=(framesInputMax-2*framesGesture[moveID])+1;m<framesInputMax;m++)
    {
                    D[n][m] = d[moveID][n][(m + startOfBuffer) % framesInputMax] + min( D[n-1][m-1], D[n][m-1], D[n][m-1] );
          //println(D[n][m]);
    }
      }

            float countAdjust = 3.0;
            // evaluate only for framesGesture[moveID] frames (the last frames)
            for(int n=(framesGestureMax-framesGesture[moveID]+1);n<framesGestureMax;n++)
      {
          for(int m=(framesInputMax-2*framesGesture[moveID])+1;m<framesInputMax;m++)  // work out path cost if newer values are bigger than previous
    {
                    P[moveID][n][m] = 0;
                    if (D[n][m-1] < D[n-1][m-1]) P[moveID][n][m] = -1;
                    if (D[n-1][m] < D[n-1][m-1]) 
                    {
                        P[moveID][n][m] = 1;
                        if (D[n][m-1] < D[n-1][m]) P[moveID][n][m] = -1;
                    }
                    // adjust a little here to detect faster events
                    if (P[moveID][n][m] < 0)
                    {
                        D[framesGestureMax-2][framesInputMax-2] -= 0.01/countAdjust*(1.0-(counterEvent/25.0))*D[n][m]; 
                        countAdjust++;
                    }
    }
      }

            int n = framesGestureMax-2;
            int m = framesInputMax-2;   
            speed[moveID] = 0.0;
            float adjust = framesGestureMax;
            for (int i = 0; i < 2*framesInputMax; i++) 
            {
                int tempN = n;
                if (P[moveID][n][m] >= 0) tempN--;
                if (P[moveID][n][m] <= 0) m--;
                n = tempN;  
                
                // average speed values 
                // speed[moveID] -=  m-0.5*framesInputMax-n;
                
                if (n == framesGestureMax-4) 
                {
                    speed[moveID] = m;
                }
                        
                if (n <= framesGestureMax-framesGesture[moveID]) 
                {
                    steps[moveID] = i;
                    adjust = (((float) framesInputMax)-m) / ((float) framesGestureMax);
                    i = 2*framesInputMax;
                }
                if (m < 0) m = 0;                        
            }
            steps[moveID]++;
            speed[moveID] -= m;
            speed[moveID] /= framesGestureMax-4.0;
            // speed[moveID] /= (float) steps[moveID];
           
            // better results by normalizing by framesGestureMax instead of steps
            // cost = D[framesGestureMax-2][framesInputMax-2]/((float) framesGestureMax);
            cost = D[framesGestureMax-2][framesInputMax-2]/steps[moveID];
     // println(cost);
        }
  
  return cost;
    }

}

