/**************************** Imports ********************************/
import gab.opencv.*;
import org.opencv.core.Core;
import org.opencv.core.CvType;
import org.opencv.core.Mat;
import org.opencv.core.Scalar;
import org.opencv.core.TermCriteria;
import org.opencv.ml.CvRTParams;
import org.opencv.ml.CvRTrees;

import java.util.Collections; 
import java.util.Arrays;
import processing.core.*;
import SimpleOpenNI.*;

import org.json.JSONException;
import org.json.JSONObject;
import org.json.JSONArray;
import java.net.MalformedURLException;

import io.socket.IOAcknowledge;
import io.socket.IOCallback;
import io.socket.SocketIO;
import io.socket.SocketIOException;

/********************** Global variables *****************************/

int frameCount = 0;
int numCams = 1;
int lostPersonId, lostCam;
int savecounter = 0;            // Counts number of frames of data currenly saved
int savesize = 150;             // Number of frames of data to collect
boolean lostUser = false;

CvRTrees forest;    // Forest object
String forestfile = "E:/Third Year Project/main/model.xml";

Camera[] cams = new Camera[numCams];      	// An array of camera objects
ArrayList<cPersonIdent> personIdents = new ArrayList<cPersonIdent>();
ArrayList<cPersonMeans> personMeans = new ArrayList<cPersonMeans>(); // Stores persons means along with global ID
ArrayList<String> textdata = new ArrayList<String>();   // Contains saved users feature data in CSV format. Last element is gpersonID.
float [] means = new float[12];             // Used for calculating mean of current user being saved. (only features not confidence stored, hence size 12 not 13)
 
SocketIO socket;
int requestedID=0;                          // ID to be returned by the server once requested. 
JSONArray outgoing = new JSONArray();		// Used to transmit user training data to other nodes
JSONArray recieved = new JSONArray();

boolean enableSave = true;      // Disable saving of new user to prevent acidentally saving users during debuging stages. (until threshold for new user is tuned properly)
boolean saving = false;			// Keeps track of whether or not a new user is currently being saved
boolean dataAvailable = false;	// True when new user data is broadcast from server 

//======================================= gesture global =====================================//
 
int train_index;  // find where global person is in the global array
boolean train_once = true;  // used to find index of globalid in array once
boolean train_gesture = false;  // passed from websocket. Used to initiate training of gesture
float start_gesture_train = 0;  // time when the train gesture function is called
boolean voluntary_start = false;  // used to start voluntary gestures when start pose is recognised
float start_gesture_recog = 0;  // start time for gesture recognition
boolean one = false;  // USED FOR DEBUGGING STARTUP TIME OF ALGORITHM.
float comx_last = 0;  // used for speed of person
float comz_last = 0;  // used for speed of person
int index; //index of person asked to be trained
int globalperson = 0;  // global id of person for who gesture recognition is enabled
int gestureId=0;      // gesture Id to be trained (preceived from server and passed to gesture function)
int globalId=0;       // global Id of person needed training
boolean updateGesture = false;   // save new gesture received from the server

// JSON stuff for server
JSONObject gestureObjectIncoming = new JSONObject();  
JSONArray gestureArray = new JSONArray();
JSONObject gestureObjectOutgoing = new JSONObject();

int numberOfPoses = 10;  // max ten poses

boolean NORMALIZE_SIZE = true;  // normalise size of person to standard person
int framesGestureMax = 30;    // record for 75 frames

boolean normRotation[] = new boolean[numberOfPoses];  // normalise rotation 
int framesGesture[] = new int[numberOfPoses];  // picks last frames of stored gesture

int framesInputMax = 2*framesGestureMax;  // number of input frames 

int counter = 0;  // counter to fill up buffer
int counterEvent = 0;

Pose[][] move;  // Relative Array of objects

int steps[] = new int[10];  // number of steps to minimise cost?
float speed[] = new float[10];  // speed of gesture
float cost[][] = new float[2][10];  // cost matrix
float costLast[][] = new float[2][10];  // last cost matrix
boolean empty[] = new boolean[10];  // check if stored gesture is empty or not

Data data;  // data type to load and save to file
RingBuffer[] ringbuffer;  // ringbuffer to store gestures in and calculate path cost

//===========================================================================//

/********************************************************************/

public void setup() {
    size(1280,480, P3D); 
    frameRate(25);
    	
    socket = new SocketIO();
    try{socket.connect("http://172.20.10.8:3000/nodes", new IOCallback(){
		public void onMessage(JSONObject json, IOAcknowledge ack){println("Server sent JSON");}
		public void onMessage(String data, IOAcknowledge ack) {println("Server sent Data",data);}
		public void onError(SocketIOException socketIOException) {println("Error Occurred");socketIOException.printStackTrace();}
		public void onDisconnect() {println("Connection terminated.");}
		public void onConnect() {println("Connection established");}
		public void on(String event, IOAcknowledge ack, Object... args) {

		  if(event.equals("res_new_ID")){
			requestedID=(Integer)args[0];      // Set the global ID
		  }
		  
		  if(event.equals("res_data")){
			recieved = (JSONArray)args[0];
			dataAvailable=true;			
		  }

                  if(event.equals("ges_train")){
                       gestureId = (Integer)args[0];
                       globalId= (Integer)args[1];
                      train_gesture=true;      
                    }
                    
                  if(event.equals("ges_res")){
                       gestureObjectIncoming = new JSONObject();
                       gestureObjectIncoming = (JSONObject)args[0];
                       gestureId = (Integer)args[1];
                       updateGesture = true;
                    }
		  
	}});
	}catch(MalformedURLException e1){e1.printStackTrace();}
    
	
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
    OpenCV opencv = new OpenCV(this, "test.jpg");
    forest = new CvRTrees();
    forest.load(forestfile);       
    
    //======================= FOR GESTURES ===========================

  for (int i = 0; i<numberOfPoses; i++){
    framesGesture[i] = framesGestureMax;  // framesGestureMax initialised to 30 fps
    normRotation[i] = true;  // normalise rotation
  }
  
  move = new Pose[10][framesGestureMax];  // store stored gestures in this array

    ringbuffer = new RingBuffer[2];  // initialise ring buffer
    for (int i = 0; i < 2; i++) {
        ringbuffer[i] = new RingBuffer();
    }
   
    data = new Data();
  
  // create move array of type pose to store 10 gestures in
    for(int i = 0; i <= 9; i++) {
        for(int j = 0; j < framesGestureMax; j++){
      move[i][j] = new Pose();
    }
    }
  
    // load the stored data
    for (int i = 0; i <= 9; i++) {
        String str = Integer.toString(i);          
        empty[i] = false;
      
        File f = new File(dataPath("pose" + str + ".data"));      
        if (!f.exists()) {
            println("File " + dataPath("pose" + str + ".data") + " does not exist");
            for (int p=0; p<2; p++)
            {
                cost[0][i] = 10000.0;
            }
        } else { 
            loadData(i);
        }
    }

  //===========================================================
  
}

public void draw() {
    // Update the cams
    SimpleOpenNI.updateAll();
    //println("Frame:" + frameCount);
    
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
    
      // if (command from websocket = train gesture) 
      // set train_gesture as true
  
  // Train/Track Gestures
    gesture();  // takes globalID & gestureID
    
    updateTrainedGesture();  // saves gesture file sent from server
    
    // If user lost, delete from global arrays here instead of in onLostUser()
    // This is due to the callback being called in the middle of other functions.
    if (lostUser) deleteUser();

    //debug();
	
	// If new user data available from server, and not currently saving a new user on this node, then update Random Forest Model
    if(dataAvailable && !saving){		
      newUserRecieved(recieved);	// Process the received JSONArray, and update Random Forest Model
      println("finished processing received data");
	  dataAvailable=false;
      recieved = new JSONArray();	// Clear array
    }

    frameCount = frameCount + 1;
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

    float[] confidence = new float[15];
    float[][] features = new float[userList.length][13];        // Last element is minimum confidence
    
    for(int i=0;i<userList.length;i++){
        if(context.isTrackingSkeleton(userList[i])){
          
            PVector head = new PVector();      // needs to be inside for loop as we need to allocate new memory each time
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

public int findLocalIdent(int globalID){
    /* Returns the local id of a person from global id. Returns -1 if not found. */
    
    for (int i=0; i<personIdents.size(); i++){
        if (globalID == personIdents.get(i).gpersonId){
             return i;       // Return index of object
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
    cPersonIdent personIdent;

    userList = cams[0].getUsers();
    
    jointPos = new PVector[userList.length][15];

    // Get feature dimensions for all users
    features = joints(cams[0], userList, jointPos);

    for (int i=0; i<userList.length; i++){
        PVector com = new PVector();                // Centre of mass    // inside for loop to avoid overwritting old values

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
    float mseThresh = 100000000;
    
    for(cPersonIdent p : personIdents){
        if(p.featDim[12]==1){

            if(p.identified == 0){ 
                // If person is unidentified, then identify using random forest

                Mat testRow =  new Mat(1, 13, CvType.CV_32FC1);           // Floating point type Mat object
                
                for(int col = 0; col < p.featDim.length; col++){          // Copy into Mat structure as required by OpenCV
                    testRow.put(0, col, p.featDim[col]);
                }
                        
                if(p.guessIndex < 10){
                    p.guesses[p.guessIndex] = int(forest.predict(testRow));   // Guess person using random forrest model     
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
						socket.emit("identified" , p.gpersonId);
						
                    }
                    else {
                        // New user identified. Request new global person ID from server
                        socket.emit("req_new_ID");
                        println("requested ID");
                        while (requestedID == 0){}    	// Wait here while ID arrives (Server returns a non zero ID)
                        p.gpersonId = (int)requestedID;
                        println("recieved ID: " + requestedID);
                        requestedID = 0;	      		// Set to zero so stay in while loop		
						println("\n");
						println("saving new user");
                        // loads Random Forest data used for training into arrayList 'textdata'
                        loadData(); 
                        p.identified = 2;
						saving = true;
						outgoing = new JSONArray();	// New JSON array. (only way to clear array)						
                    }
                }
            }

            if(p.identified == 2 && enableSave){
                // If person is new then save his features according to global variable, savesize
                if(savecounter == savesize){  
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
                     
                    p.identified = 1;               // Now user is saved and identified.
					saving = false; 
					println("sent JSON Array");
                    socket.emit("rec_data", outgoing);
                }
         
                else{                               // Else collect more data and add to ArrayList 'textdata'
                    addData(p.gpersonId, p.featDim); 
                    for(int i=0;i<12;i++){ 
						means[i] += p.featDim[i]; 	// Accumulate data to calculate the mean once 'savesize' number of frames are saved
					}       
					
                    //JSON object filled with new data
					JSONObject temp = new JSONObject();
					try {  
						temp.put("featDim", (float[])p.featDim);
						temp.put("gpersonId", (Integer)p.gpersonId);
					} catch (JSONException e) {}
					
					outgoing.put(temp);
					savecounter++;                  // Counter for number of frames of data saved
					
				}                
            }

            pIndex = personIdents.indexOf(p);
            personIdents.set(pIndex, p);     		// Replace personIdent record with changed values
        }
    }

}

public void gesture(){
 
  if(train_gesture){
      index = findLocalIdent(globalId);  // find index of where the global person is held in the global array
      
    if(index == 0 ){      // for debugging removee
    if(personIdents.get(index).identified == 1){  // for debugging removee
      
    // only find index once at the start of when train gesture is called
    if(train_once){
      // get id of global id then look up in structure to get cam id and local id once
      //index = findLocalIdent(globalID);
      train_once = false;
      start_gesture_train = millis();  // start timer
      println("started training");
    }
    
    
    // fill buffer i.e call evaluate skeleton function
    evaluateSkeleton(personIdents.get(index).jointPos);
    
    // save pose after 6s
    if (millis() - start_gesture_train > 6000){
      saveGesture(gestureId);
      train_gesture = false;
      train_once = true;
      println("saved pose");
    }
    }
    }
  }
  
  //track the gesture
  for(cPersonIdent p : personIdents){ //all people in cameras view
    if(p.identified == 1){  // only recognise gestures from identified people
   if (p.jointPos[0] != null){
      //right elbow    //righthand          //left elbow         //lefthand
      //println(p.personId + " " + p.com);
      if((p.jointPos[8].y) < (p.jointPos[10].y - 200) && p.jointPos[9].y <  (p.jointPos[11].y - 200) && !train_gesture && !voluntary_start){//starting pose detected and not training gesture){  
        globalperson = p.gpersonId;  // store global id of person
        voluntary_start = true;  // start voluntary gesture detection
        start_gesture_recog = millis();  // used to timeout gesture recognition
        index = findLocalIdent(globalperson);  // store index of global person in the global array
        //index = p.personId - 1;
        println("start gesture detected " + globalperson);
        
   }
 
      // hard coded gestures go here
      
   if(p.com.y<500){
    //println("fall detection " + p.gpersonId); 
    }
//     else if(p.com.y<800){
//       // println("s'h'itting " + p.gpersonId);
//      }
      // speed detection
     else{
        // calculate distance moved from last com of previous frame 
        float speed_xz = dist(comx_last, comz_last, p.com.x, p.com.z);  
        comx_last = p.com.x;
        comz_last = p.com.z;
          //threshold determined by trial in mm
        if(speed_xz < 123 && speed_xz > 40){
            println("walking");
         }
          else if(speed_xz > 250){
            println("running");
          }
     }
     
      } // for null if loop
      
    }
  }
  
  // detect gestures for one person
  if(voluntary_start){
    index = findLocalIdent(globalperson);  // update index of global person in global array
    
    if(cams[0].isTrackingSkeleton(personIdents.get(index).personId)){    // change to get which cam the person is on could be 0 or 1 for two cameras

      evaluateSkeleton(personIdents.get(index).jointPos);  // call evaluate skeleton functions
      evaluateCost();  // work out cost functions

    // reset starting pose detected as false after 5s last gesture performed or 5 seconds after no activity
      if(millis() - start_gesture_recog > 10000){
        voluntary_start = false;
        println("timeout");
      }
    }
    else{
      voluntary_start = false;
      println("timeout user lost");
    }

  }
    
}

// draw the skeleton with the selected joints
// pass the whole array for each user containing the 6 joint positions
public void evaluateSkeleton(PVector jointPos[]){
    Pose pose = new Pose();

    // calculate relative position

  // left shoulder - neck
    pose.jointLeftShoulderRelative.x = jointPos[2].x - jointPos[1].x;
    pose.jointLeftShoulderRelative.y = jointPos[2].y - jointPos[1].y;
    pose.jointLeftShoulderRelative.z = jointPos[2].z - jointPos[1].z;
  // left elbow - neck
    pose.jointLeftElbowRelative.x = jointPos[9].x - jointPos[1].x;
    pose.jointLeftElbowRelative.y = jointPos[9].y - jointPos[1].y;
    pose.jointLeftElbowRelative.z = jointPos[9].z - jointPos[1].z;
  // left hand - neck
    pose.jointLeftHandRelative.x = jointPos[11].x - jointPos[1].x;
    pose.jointLeftHandRelative.y = jointPos[11].y - jointPos[1].y;
    pose.jointLeftHandRelative.z = jointPos[11].z - jointPos[1].z;  
  // right shoulder - neck
    pose.jointRightShoulderRelative.x = jointPos[3].x - jointPos[1].x;
    pose.jointRightShoulderRelative.y = jointPos[3].y - jointPos[1].y;
    pose.jointRightShoulderRelative.z = jointPos[3].z - jointPos[1].z;
  // right elbow - neck
    pose.jointRightElbowRelative.x = jointPos[8].x - jointPos[1].x;
    pose.jointRightElbowRelative.y = jointPos[8].y - jointPos[1].y;
    pose.jointRightElbowRelative.z = jointPos[8].z - jointPos[1].z;
  // right hand - neck
    pose.jointRightHandRelative.x = jointPos[10].x - jointPos[1].x;
    pose.jointRightHandRelative.y = jointPos[10].y - jointPos[1].y;
    pose.jointRightHandRelative.z = jointPos[10].z - jointPos[1].z;

    // add new pose to ringbuffer
  
    if (NORMALIZE_SIZE){
    pose = normalizeSize(pose);
  }
    Pose poseNormalized = normalizeRotation(pose);// can add variable person to increase size of detected users
    ringbuffer[0].fillBuffer( pose );
    ringbuffer[0].fillBufferNormalized( poseNormalized );    

}

// works out cost of performed gesture and attempts to find a match from existing recorded gestures
public void evaluateCost(){
  
  int p = 0;
    for (int gestindex = 0; gestindex <= 9; gestindex++)  // limit = number of poses
    {
        if (!empty[gestindex])
        {
            costLast[p][gestindex] = cost[p][gestindex];
            cost[p][gestindex] = ringbuffer[p].pathcost(gestindex);
            cost[p][gestindex] = (log(cost[p][gestindex]-1.0) - 5.5)/2.0;    /// remove and set cost threshold to 450
           //println(cost[0][gestindex] + " " + gestindex);
           
           if( cost[p][gestindex] > 0 && !one){    // debugging time removeee
            one = true;
           float time_end = millis();
            println(time_end-start_gesture_recog);
           }
       
       // if gesture match found
            if ( ( cost[p][gestindex] < 0.3 ) && ( costLast[p][gestindex] >= 0.3 ) )
            {
                
                 socket.emit("ges_perf",gestindex, globalperson);//found gesture and output to server
                println("found gesture #" + gestindex + " user #" + globalperson);  // found gesture
                start_gesture_recog = millis();  // reset gesture timeout 

            }   
  
        }
    }
  }

//save gestures that have been trained
public void saveGesture(int gestureID){
 if ( (gestureID >= 0) && (gestureID <= 9))
  {
    
      println("POSE " + gestureID + " SAVED");
      ringbuffer[0].copyBuffer(gestureID);
    
      String str = Integer.toString(gestureID);
      saveData(gestureID);
      loadData(gestureID);
      empty[gestureID] = false;
  }

}

public void updateTrainedGesture(){
 if ( updateGesture && !voluntary_start){  // if we recieve new gesture data and we are not detecting gestures then
   String temp = "im here as a placeholder";
   try {     
     temp = (gestureObjectIncoming.get("gesturedata")).toString();  // convert jsonobject to string
   }
 catch (JSONException e) {}
 
 String[] poseData = split(temp.substring(1,temp.length()-1), ',');  // convert to string array
 updateGesture = false;  // no need to update gesture again
 saveStrings("data/pose"+gestureId+".data", poseData);  // save pose data
 println("gesture data updated for gesture id " + gestureId);
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
  
void newUserRecieved(JSONArray recieved){
 /* Called when new user training data is received from other nodes. Add this data to data.txt and re-train the Random Forest model. Compute the feature means for this new user and add to means.txt and the ArrayList 'personMeans'  
 
 CANNOT call this function while a user is already being saved else 'textdata' will be cleared and overwritten
 */
 
  float [] mean = new float[12];	// Used to calculate and write means
  loadData();  						// Loads Random Forest data used for training into arrayList 'textdata'

  
  // Add row of data to 'textdata' and acumulate features' sums for mean calculation
  for(int i=0; i<(recieved.length()); i++){
    try{
  	addData( (Integer)(recieved.getJSONObject(i).get("gpersonId")) , float(split( ((String)(recieved.getJSONObject(i)).getString("featDim")).substring(1, ( (((String)(recieved.getJSONObject(i)).getString("featDim"))).length()-1)) , ','       )) ); // Adds to textdata

	for(int j=0;j<12;j++){ 			//exclude confidence which is 12th element
		mean[j] += (float(split( ((String)(recieved.getJSONObject(i)).getString("featDim")).substring(1, ( (((String)(recieved.getJSONObject(i)).getString("featDim"))).length()-1)) , ','       )))[j];	// Accumulate values; used to compute the mean of each feature
	}
  }
  catch (JSONException e) {}
  }
  
  
  // Write new training data to file
  saveStrings("data/data.txt", textdata.toArray(new String[textdata.size()]));
  
  
	// Add means to ArrayList 'personMeans' and save to text file
	cPersonMeans temp = new cPersonMeans();
     try{
	  temp.gpersonId = (Integer)(recieved.getJSONObject(0).get("gpersonId"));   	// gpersonId should be same for all indexes in the JSON array        
	}
        catch (JSONException e) {}
	for(int i=0; i<12; i++){													// Compute feature means   
		temp.featMean[i] = mean[i]/(recieved.length()); 						// recieved.length() should be equal to 'savesize' if 'savesize' is the same for all machines
	}                       
	personMeans.add(temp);
	saveMeans(); 																// Save ArrayList 'personMeans' to means.txt
  
  //find, save and re-load model
  findmodel();
  savemodel();
  forest.load(forestfile);														// Probably unncecessary to reload since model trained in 'savemodel()'
}

void keyPressed(){
  socket.emit("ges_temp"); 
}
