/**************************** Imports ********************************/
import java.util.Arrays;
import processing.core.*;
import SimpleOpenNI.*;

/********************** Global variables *****************************/

int frameCount = 0;
int numCams = 1;
int lostPersonId, lostCam;
boolean lostUser = false;

Camera[] cams = new Camera[numCams];      // An array of camera objects
ArrayList<cPersonIdent> personIdents = new ArrayList<cPersonIdent>();
ArrayList<cPersonInfo> personInfos = new ArrayList<cPersonInfo>();

/********************************************************************/

public void setup() {
    size(1280,480, P3D); 
    frameRate(20);
    
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
        
        // The last two points are the coordinates of the calibration point 
        // relative to the 0,0 location of the floorplan. Required for a universal
        // coordinate system
        if(usercoordsys.length > 9){
            
        }
    }                     
}

public void draw() {
    // Update the cams
    SimpleOpenNI.updateAll();
    
    println("Frame:" + frameCount);
    
    // Draw depth image
    image(cams[0].depthImage(), 0, 0);
    //image(cams[1].depthImage(), 640, 0);
    
    // Find confidence and prioritise camera for feature dimensions extraction
    if (numCams > 1){
        multicam();
    }
    else {
        singlecam();
    }

    // If user lost, delete from global arrays here instead of in onLostUser()
    // This is due to the callback being called in the middle of other functions.
    if (lostUser) deleteUser();

    debug();

    frameCount = frameCount + 1;
    println("\n");
}

public void debug(){
    println("personIdents: " + personIdents.size());

    for(cPersonIdent p : personIdents){
        println("ID: " + p.personId);
        println("camID: " + p.camId);
        println("FeatDim: " + Arrays.toString(p.featDim));
        println("Identified: " + p.identified + "\n");
    }
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

public int findPersonIdent(int camId, int personId){
    /* Returns the index if person exists in global array. Returns -1 if not found. */
    
    for (int i=0; i<personIdents.size(); i++){
        if (camId == personIdents.get(i).camId){
            if (personId == personIdents.get(i).personId){
                return i;       // Return index of object
            }
        }
    }

    return -1;                  //  Not found so return -1
} 

public void singlecam(){
    /* Fills the personIdent global array if only one camera is connected */

    int inPerson;
    int[] userList;
    float[][] features;
    PVector com = new PVector();                // Centre of mass
    cPersonIdent personIdent;

    userList = cams[0].getUsers();

    // Get feature dimensions for all users
    features = joints(cams[0], userList);

    for (int i=0; i<userList.length; i++){
        personIdent = new cPersonIdent();

        personIdent.personId = userList[i];
        personIdent.camId = 0;
        personIdent.featDim = features[i];

        inPerson = findPersonIdent(0, userList[i]);     // Check if person already exists in personIdents

        if (inPerson != -1){
            // If person already exists in global array then replace him/her
            personIdent.identified = personIdents.get(inPerson).identified;
            personIdents.remove(inPerson);
        }

        personIdents.add(personIdent);          // Add obkect to global array
    }
}

public void multicam(){
    /* Fills a global array with each users' feature dimensions based on confidence of all cameras */

    int personId, inPerson;
    int[] userList;
    float threshold = 400;
    float eucDist;
    float minConf;                                              // Minimum confidence
    float[][] features;
    PVector com0 = new PVector();                               // Centre of mass 1
    PVector com1 = new PVector();                               // Centre of mass 2
    cSingleCam[] singleCam;
    cSingleCam[][] singleCams = new cSingleCam[numCams][];      // Array to hold users in all camera
    cPersonIdent personIdent;

    for(int i=0; i<numCams;i++){
        // For each camera, get all users' COMs and confidences
        userList = cams[i].getUsers();
        
        //println("Cam: " + i + "\t Users: " + Arrays.toString(userList));
        
        if (userList.length > 0){
            // Array to hold all users for one camera
            singleCam = new cSingleCam[userList.length];
             
            // Get feature dimensions for all users
            features = joints(cams[i], userList);
            
            for(int j=0; j<userList.length; j++){
                // For each user get centre of mass and confidence
                personId = userList[j];
                cams[i].getCoM(userList[j], com0);
                
                singleCam[j] = new cSingleCam(personId, com0, features[j]);
            }
        }
        else {
            // No users so move to next camera
            singleCam = new cSingleCam[0];      // To avoid null pointer exception
        }

        // Add user array for one camera to array for all cameras
        singleCams[i] = singleCam;  
    }

    // Prioritse camera according to confidence level
    for(cSingleCam c0 : singleCams[0]){
        inPerson = findPersonIdent(0, c0.personId);

        // Assign default values
        personIdent = new cPersonIdent();         // Create new object, add to global array later
        personIdent.personId = c0.personId;
        personIdent.camId = 0;
        personIdent.featDim = c0.featDim;

        com0 = c0.com;      // Get COM of person

        // For every user in the first camera, compare to users in the second camera
        for(cSingleCam c1 : singleCams[1]){
            if (c1.personId != -1){
                // Find euclidean distance
                com1 = c1.com;
                eucDist = dist(com0.x,com0.y,com0.z,com1.x,com1.y,com1.z);

                if (eucDist < threshold){
                    if(inPerson == -1) inPerson = findPersonIdent(1, c1.personId);

                    // Same person so compare confidence and add only one copy to global array
                    if(c0.featDim[7] < c1.featDim[7]){
                        personIdent.personId = c1.personId;
                        personIdent.camId = 1;
                        personIdent.featDim = c1.featDim;
                    }

                    c1.personId = -1;       // Set personId=-1 to skip person
                    break;                  // Move to next user in c0
                }
            }
        }

        if (inPerson != -1){
            // If person already exists in global array then replace him/her
            personIdent.identified = personIdents.get(inPerson).identified;
            personIdents.remove(inPerson);
        }

        personIdents.add(personIdent);      // Add object to global array
    }

    // Add left over users in c1 to global array i.e personId != -1
    for (cSingleCam c1 : singleCams[1]){
        if (c1.personId != -1){
            personIdent = new cPersonIdent();               // Create new object, add to global array later

            personIdent.personId = c1.personId;
            personIdent.camId = 1;
            personIdent.featDim = c1.featDim;

            inPerson = findPersonIdent(1, c1.personId);     // Check if person already exists in personIdents

            if (inPerson != -1){
                // If person already exists in global array then replace him/her
                personIdent.identified = personIdents.get(inPerson).identified;
                personIdents.remove(inPerson);
            }

            personIdents.add(personIdent);                  // Add object to global array
        }
    }
    
}   // End of multicam()

public void identify(){
    /* ADD SVM CODE HERE */
}

public void onNewUser(SimpleOpenNI context,int userId){
    // Called when new user detected
    println("New User:" + userId);
    context.startTrackingSkeleton(userId);
}

public void onLostUser(SimpleOpenNI context,int userId) {
    /* Called 10 seconds after losing user */

    // Find camera ID
    for (int i=0; i<cams.length; i++){
        if(context == cams[i]){
            lostCam = i;
            break;
        }
    }

    println("Lost User: " + userId + "\tCamera: " + lostCam);
    context.stopTrackingSkeleton(userId);           // Stop tracking user
    println("Skeleton tracking stopped for user: " + userId);


    lostPersonId = userId;
    lostUser = true;
}

public void deleteUser(){
    /* Delete person from global array personIdents */

    for (cPersonIdent p : personIdents){
        if(p.personId == lostPersonId && p.camId == lostCam){
            personIdents.remove(p);
            break;
        }
    }

    lostUser = false;
}
  
