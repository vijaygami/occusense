/**************************** Imports ********************************/
import org.opencv.core.*;
import org.opencv.ml.*;

import java.util.Collections; 
import java.util.Arrays;
import processing.core.*;
import SimpleOpenNI.*;

/********************** Global variables *****************************/

int frameCount = 0;
int numCams = 1;
int lostPersonId, lostCam;
int savecounter = 0;            // Counts number of frames of data currenly saved
int savesize = 150;             // Number of frames of data to collect
boolean lostUser = false;
boolean enableSave = false;      // Disable saving of new user to prevent acidentally saving users during debuging stages. (until threshold for new user is tuned properly)

RTrees forest;    // Forest object
String forestfile = "/home/rishi/repos/occusense/src/sensor/main/model.xml";

Camera[] cams = new Camera[numCams];      // An array of camera objects
ArrayList<cPersonIdent> personIdents = new ArrayList<cPersonIdent>();
ArrayList<cPersonMeans> personMeans = new ArrayList<cPersonMeans>(); // Stores persons means along with global ID
ArrayList<String> textdata = new ArrayList<String>();   // Contains saved users feature data in CSV format. Last element is gpersonID.
float [] means = new float[12];             // Used for calculating mean of current user being saved. (only features not confidence stored, hence size 12 not 13)
 
/********************************************************************/

public void setup() {
    size(1280,480, P3D); 
    frameRate(25);
    
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

    // Load data from files into arrays
    loadMeans();    

    // Create new tree object and load random forest model
    String path = "C:/Users/jeremy/Desktop/occusense/src/sensor/main/code";
    String originalPath = System.getProperty("java.library.path");
    System.setProperty("java.library.path", originalPath +System.getProperty("path.separator")+ path);
    System.loadLibrary("opencv_java300");
    forest = RTrees.create();
    //forest.load(forestfile);               
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
    
    // Identify unidentified people
    identify();
    
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

float[][] joints(SimpleOpenNI context, int[] userList, PVector[][] pos){ 
    /* Returns the feature dimensions for each user in the provided context */

    PVector head = new PVector();
    PVector neck = new PVector();
    PVector leftshoulder = new PVector();
    PVector rightshoulder = new PVector();
    PVector lefthip = new PVector();
    PVector righthip = new PVector();
    PVector leftknee = new PVector();
    PVector rightknee = new PVector();
    PVector torso = new PVector();
    PVector rightelbow = new PVector();
    PVector leftelbow = new PVector();
    PVector righthand = new PVector();
    PVector lefthand = new PVector();
    PVector leftfoot = new PVector();
    PVector rightfoot = new PVector();

    float[] confidence = new float[15];
    float[][] features = new float[userList.length][13];        // Last element is minimum confidence
    
    for(int i=0;i<userList.length;i++){
        if(context.isTrackingSkeleton(userList[i])){
            confidence[0] = context.getJointPositionSkeleton(userList[i],SimpleOpenNI.SKEL_HEAD,head);
            confidence[1] = context.getJointPositionSkeleton(userList[i],SimpleOpenNI.SKEL_NECK,neck);
            confidence[2] = context.getJointPositionSkeleton(userList[i],SimpleOpenNI.SKEL_LEFT_SHOULDER,leftshoulder);
            confidence[3] = context.getJointPositionSkeleton(userList[i],SimpleOpenNI.SKEL_RIGHT_SHOULDER,rightshoulder);
            confidence[4] = context.getJointPositionSkeleton(userList[i],SimpleOpenNI.SKEL_LEFT_HIP,lefthip);
            confidence[5] = context.getJointPositionSkeleton(userList[i],SimpleOpenNI.SKEL_RIGHT_HIP,righthip);
            confidence[6] = context.getJointPositionSkeleton(userList[i],SimpleOpenNI.SKEL_LEFT_KNEE,leftknee);
            confidence[7] = context.getJointPositionSkeleton(userList[i],SimpleOpenNI.SKEL_RIGHT_KNEE,rightknee);
            confidence[8] = context.getJointPositionSkeleton(userList[i],SimpleOpenNI.SKEL_TORSO,torso);
            confidence[9] = context.getJointPositionSkeleton(userList[i],SimpleOpenNI.SKEL_LEFT_ELBOW,leftelbow);
            confidence[10] = context.getJointPositionSkeleton(userList[i],SimpleOpenNI.SKEL_RIGHT_ELBOW,rightelbow);
            confidence[11] = context.getJointPositionSkeleton(userList[i],SimpleOpenNI.SKEL_RIGHT_HAND,righthand);
            confidence[12] = context.getJointPositionSkeleton(userList[i],SimpleOpenNI.SKEL_LEFT_HAND,lefthand);
            confidence[13] = context.getJointPositionSkeleton(userList[i],SimpleOpenNI.SKEL_LEFT_FOOT,leftfoot);
            confidence[14] = context.getJointPositionSkeleton(userList[i],SimpleOpenNI.SKEL_RIGHT_FOOT,rightfoot);
            
            features[i][0] = (neck.dist(head));
            features[i][1] = (leftshoulder.dist(rightshoulder)); 
            features[i][2] = (torso.dist(neck)); 
            features[i][3] = (torso.dist(lefthip)+torso.dist(leftshoulder));       
            features[i][4] = (torso.dist(righthip)+torso.dist(rightshoulder));
            features[i][5] = (rightshoulder.dist(rightelbow));
            features[i][6] = (leftshoulder.dist(leftelbow));
            features[i][7] = (rightelbow.dist(righthand)); 
            features[i][8] = (leftelbow.dist(lefthand)); 
            features[i][9] = (righthip.dist(lefthip));
            features[i][10] = (righthip.dist(rightknee));
            features[i][11] = (lefthip.dist(leftknee));
            features[i][12] = min(confidence);

            pos[i][0] = head;
            pos[i][1] = neck;
            pos[i][2] = leftshoulder;
            pos[i][3] = rightshoulder;
            pos[i][4] = lefthip;
            pos[i][5] = righthip;
            pos[i][6] = leftknee;
            pos[i][7] = rightknee;
            pos[i][8] = rightelbow;
            pos[i][9] = leftelbow;
            pos[i][10] = righthand;
            pos[i][11] = lefthand;
            pos[i][12] = torso;
            pos[i][13] = leftfoot;
            pos[i][14] = rightfoot;

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
    PVector[][] jointPos;
    PVector com = new PVector();                // Centre of mass
    cPersonIdent personIdent;

    userList = cams[0].getUsers();
    
    jointPos = new PVector[userList.length][15];

    // Get feature dimensions for all users
    features = joints(cams[0], userList, jointPos);

    for (int i=0; i<userList.length; i++){
        cams[0].getCoM(userList[i], com);

        personIdent = new cPersonIdent();

        personIdent.personId = userList[i];
        personIdent.camId = 0;
        personIdent.com = com;
        personIdent.featDim = features[i];
        personIdent.jointPos = jointPos[i];

        inPerson = findPersonIdent(0, userList[i]);     // Check if person already exists in personIdents

        if (inPerson != -1){
            // If person already exists in global array then replace him/her
            personIdent.gpersonId = personIdents.get(inPerson).gpersonId;
            personIdent.guesses = personIdents.get(inPerson).guesses;
            personIdent.identified = personIdents.get(inPerson).identified;
            personIdent.guessIndex = personIdents.get(inPerson).guessIndex;
            personIdents.remove(inPerson);
        }

        personIdents.add(personIdent);          // Add object to global array
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
    PVector[][] jointPos;
    PVector com0 = new PVector();                               // Centre of mass 1
    PVector com1 = new PVector();                               // Centre of mass 2
    cSingleCam[] singleCam;
    cSingleCam[][] singleCams = new cSingleCam[numCams][];      // Array to hold users in all camera
    cPersonIdent personIdent;

    for(int i=0; i<numCams;i++){
        // For each camera, get all users' COMs and confidences
        userList = cams[i].getUsers();
        
        println("Cam: " + i + "\t Users: " + Arrays.toString(userList));
        
        if (userList.length > 0){
            // Array to hold all users for one camera
            singleCam = new cSingleCam[userList.length];
             
            jointPos = new PVector[userList.length][15]; 
            
            // Get feature dimensions for all users
            features = joints(cams[i], userList, jointPos);
            
            for(int j=0; j<userList.length; j++){
                // For each user get centre of mass and confidence
                personId = userList[j];
                cams[i].getCoM(userList[j], com0);
                
                singleCam[j] = new cSingleCam(personId, com0, features[j], jointPos[j]);
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
        personIdent.com = c0.com;
        personIdent.featDim = c0.featDim;
        personIdent.jointPos = c0.jointPos;

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
                    if(c0.featDim[12] < c1.featDim[12]){
                        personIdent.personId = c1.personId;
                        personIdent.camId = 1;
                        personIdent.com = c1.com;
                        personIdent.featDim = c1.featDim;
                        personIdent.jointPos = c1.jointPos;
                    }

                    c1.personId = -1;       // Set personId=-1 to skip person
                    break;                  // Move to next user in c0
                }
            }
        }

        if (inPerson != -1){
            // If person already exists in global array then replace him/her
            personIdent.gpersonId = personIdents.get(inPerson).gpersonId;
            personIdent.guesses = personIdents.get(inPerson).guesses;
            personIdent.identified = personIdents.get(inPerson).identified;
            personIdent.guessIndex = personIdents.get(inPerson).guessIndex;
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
            personIdent.com = c1.com;
            personIdent.featDim = c1.featDim;
            personIdent.jointPos = c1.jointPos;

            inPerson = findPersonIdent(1, c1.personId);     // Check if person already exists in personIdents

            if (inPerson != -1){
                // If person already exists in global array then replace him/her
                personIdent.gpersonId = personIdents.get(inPerson).gpersonId;
                personIdent.guesses = personIdents.get(inPerson).guesses;
                personIdent.identified = personIdents.get(inPerson).identified;
                personIdent.guessIndex = personIdents.get(inPerson).guessIndex;
                personIdents.remove(inPerson);
            }

            personIdents.add(personIdent);                  // Add object to global array
        }
    }
    
}   // End of multicam()

public void identify(){
    /* Identifies unidentified people using random forest. Guesses a person 10 times and confirms 
        the identity using mode */

    int pIndex;
    float mse;
    float mseThresh = 550;
    
    for(cPersonIdent p : personIdents){
        if(p.featDim[12]==1){

            if(p.identified == 0){ 
                // If person is unidentified, then identify using random forest

                Mat testRow =  new Mat(1, 13, CvType.CV_32FC1);           // Floating point type Mat object
                Mat results = new Mat();
                int[] votes = new int[50];
                
                for(int col = 0; col < p.featDim.length; col++){          // Copy into Mat structure as required by OpenCV
                    testRow.put(0, col, p.featDim[col]);
                }
                        
                if(p.guessIndex < 10){
                    p.guesses[p.guessIndex] = int(forest.predict(testRow,results,-1));   // Set flag to -1 to obtain votesarray in 'results'
                    results.get(0,0,votes);    //You can now use votes to 
                    p.guessIndex = p.guessIndex + 1;
                    println("guess index: " + p.guessIndex);
                    println("Guesses: " + Arrays.toString(p.guesses));
                }
                else {
                    // Find the mode (most frequent) guess
                    p.guesses[p.guessIndex] = mode(Arrays.copyOfRange(p.guesses, 0, 10));

                    // Find MSE (mean squared error)
                    mse = MSE(lookupMean (p.guesses[p.guessIndex] , personMeans), Arrays.copyOfRange(p.featDim, 0, 12));

                    println("MSE: " + mse);

                    if (mse < mseThresh){
                        // Person succesfully identified
                        p.identified = 1;
                        p.gpersonId = p.guesses[p.guessIndex];      // Set global person ID
                        println("User detected: " + p.gpersonId);
                    }
                    else {
                        // New user identified. Request new global person ID from server
                        p.gpersonId = newPersonId();

                        // loads Random Forest data used for training into arrayList 'textdata'
                        loadData(); 
                        p.identified = 2;
                    }
                }
            }

            if(p.identified == 2 && enableSave){
                // If person is new then save his features according to global variable, savesize
                if(savecounter==savesize){  
                    // If enough data has been collected, store means and global ID in global arraylist
                    // and save into text file 'mean.txt' for future use.
                    cPersonMeans temp = new cPersonMeans();
                    temp.gpersonId = p.gpersonId;           
                    
                    for(int i=0; i<12; i++){
                        // Compute and add the feature means to the object   
                        temp.featMean[i] = means[i]/savesize; 
                    }                       

                    personMeans.add(temp);
                    saveMeans();                     // Write the means to file 
         
                    // Write new training data to file
                    saveStrings("data/data.txt", textdata.toArray(new String[textdata.size()]));
         
                    // Training Random Forests
                    findmodel();
                    savemodel();
         
                    // Reset temporary mean storage and data counter ready for saving the next user
                    savecounter=0;
                    
                    for(int i=0; i<12; i++){
                        means[i] = 0;
                    }
                     
                    p.identified = 1;                // Now user is saved and identified.
                     
                    uploadUser();                   // Upload new person's features to server to broadcast to other nodes
                }
         
                else{                               //else collect more data and add to ArrayList 'textdata'
                    addData(p.gpersonId, p.featDim); 
                    savecounter++;                  //counter for number of frames of data saved
                    for(int i=0;i<12;i++){ means[i] += p.featDim[i]; }       // Accumulate data to calculate the mean once 'savesize' number of frames are saved
                }                
            }

            pIndex = personIdents.indexOf(p);
            personIdents.set(pIndex, p);     // Replace personIdent record with changed values
        }
    }

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
  

public int newPersonId(){
    // Add code to request new id from server here
    return 0;
}

public void uploadUser(){
    
}
