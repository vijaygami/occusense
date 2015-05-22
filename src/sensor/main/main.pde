// Imports 
import processing.core.*;
import SimpleOpenNI.*;

//  An array of camera objects
int numCams = 2;
Camera[] cams = new Camera[numCams];

public void setup() {
    size(1280,480, P3D); 
    frameRate(30);
    
    // Load the library
    SimpleOpenNI.start();
    
    // Initialize and calibtrate all cams
    for (int i = 0; i < cams.length; i++) {
        cams[i] = new Camera(this, i);
        
        // Calibrate camera
        String[] coordsys = loadStrings("usercoordsys"+i+".txt");
        float[] usercoordsys = float(split(coordsys[0],","));
        cams[i].setUserCoordsys(usercoordsys[0],usercoordsys[1], usercoordsys[2],
                          usercoordsys[3], usercoordsys[4], usercoordsys[5],
                          usercoordsys[6], usercoordsys[7], usercoordsys[8]);
    }                     
}

public void draw() {
    // Update the cams
    SimpleOpenNI.updateAll();
    
    // Draw depth image
    image(cams[0].depthImage(), 0, 0);
    image(cams[1].depthImage(), 640, 0);
    
    // Find confidence and prioritise camera for feature dimensions extraction
    multicam();
    
}

public void debug(){
  /* ADD DEBUG CODE HERE */
}

float[][] joints(SimpleOpenNI context, int[] userList){ 
    /* Returns the feature dimensions for each user in the provided context */

    PVector head = new PVector();
    PVector neck = new PVector();
    PVector leftshoulder = new PVector();
    PVector rightshoulder = new PVector();
    PVector lefthip = new PVector();
    PVector leftknee = new PVector();
    PVector torso = new PVector();
    PVector rightelbow = new PVector();
    PVector righthand = new PVector();
    float[] confidence = new float[9];
    float[][] features = new float[userList.length][8];
    
    for(int i=0;i<userList.length;i++){
        if(context.isTrackingSkeleton(userList[i])){
            confidence[0] = context.getJointPositionSkeleton(userList[i],SimpleOpenNI.SKEL_HEAD,head);
            confidence[1] = context.getJointPositionSkeleton(userList[i],SimpleOpenNI.SKEL_NECK,neck);
            confidence[2] = context.getJointPositionSkeleton(userList[i],SimpleOpenNI.SKEL_LEFT_SHOULDER,leftshoulder);
            confidence[3] = context.getJointPositionSkeleton(userList[i],SimpleOpenNI.SKEL_RIGHT_SHOULDER,rightshoulder);
            confidence[4] = context.getJointPositionSkeleton(userList[i],SimpleOpenNI.SKEL_LEFT_HIP,lefthip);
            confidence[5] = context.getJointPositionSkeleton(userList[i],SimpleOpenNI.SKEL_LEFT_KNEE,leftknee);
            confidence[6] = context.getJointPositionSkeleton(userList[i],SimpleOpenNI.SKEL_TORSO,torso);
            confidence[7] = context.getJointPositionSkeleton(userList[i],SimpleOpenNI.SKEL_RIGHT_ELBOW,rightelbow);
            confidence[8] = context.getJointPositionSkeleton(userList[i],SimpleOpenNI.SKEL_RIGHT_HAND,righthand);
            
            features[i][0] = neck.dist(head);                          
            features[i][1] = leftshoulder.dist(rightshoulder); 
            features[i][2] = torso.dist(neck); 
            features[i][3] = neck.dist(head)+leftshoulder.dist(lefthip)+lefthip.dist(leftknee);
            features[i][4] = torso.dist(lefthip)+torso.dist(leftshoulder);   
            features[i][5] = rightshoulder.dist(rightelbow);
            features[i][6] = rightelbow.dist(righthand); 
            features[i][7] = min(confidence);       
        }
    }

    return features;
}

public void multicam(){
    /* Fills a global array with each users' feature dimensions based on confidence of all cameras */
    int personId;
    float minConf;                                                  // Minimum confidence
    PVector com = new PVector();                                    // Centre of mass
    cSingleCam[] singleCam;
    cSingleCam[][] singleCams = new cSingleCam[numCams][];          // Array to hold users in all camera

    for(int i=0; i<numCams;i++){
        // For each camera, get all users' COMs and confidences
        int[] userList = cams[i].getUsers();
        
        if (userList.length > 0){
            // Array to hold all users for one camera
            singleCam = new cSingleCam[userList.length];
             
            // Get feature dimensions for all users
            float[][] features = joints(cams[0], userList);
            
            for(int j=0; j<userList.length; j++){
                // For each user get centre of mass and confidence

                personId = userList[j];
                cams[i].getCoM(userList[j], com);
                minConf = features[j][7];           // Last element of features is confidence
                
                singleCam[j] = new cSingleCam(personId, com, minConf);
            }
        }
        else {
            // No users so move to next camera
            singleCam = new cSingleCam[0];      // To avoid null pointer exception
        }
        
        // Add user array for one camera to array for all cameras
        singleCams[i] = singleCam;  
    }

    
    for(int i=0; i<numCams; i++){
        for (int j=0; j<singleCams[i].length; j++){

        }
    }
    
}   // End of multicam()

public void identify(){
  /* ADD SVM CODE HERE */
}

public void onNewUser(SimpleOpenNI context,int userId){
  // Called when new user detected
  
  context.startTrackingSkeleton(userId);
}

public void onLostUser(SimpleOpenNI context,int userId) {
  // Called 10 seconds after losing user
  
  context.stopTrackingSkeleton(userId);
}

public void onVisibleUser(SimpleOpenNI curcams,int userId){

}
