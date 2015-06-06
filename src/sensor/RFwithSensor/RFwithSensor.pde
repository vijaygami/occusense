 import gab.opencv.*;
import org.opencv.core.Core;
import org.opencv.core.CvType;
import org.opencv.core.Mat;
import org.opencv.core.Scalar;
import org.opencv.core.TermCriteria;
import org.opencv.ml.CvRTParams;
import org.opencv.ml.CvRTrees;

  
import SimpleOpenNI.*;
import java.util.Collections; 
import java.util.Arrays; 
import java.awt.Robot;
import java.awt.AWTException;
import static javax.swing.JOptionPane.*;
import io.socket.IOAcknowledge;   
import io.socket.IOCallback;
import io.socket.SocketIO;
import io.socket.SocketIOException;
import org.json.JSONException;
import org.json.JSONObject;
import java.net.MalformedURLException; 

// SVM model;
float k=0; //smoothing constant
CvRTrees forest;	// forest object
SocketIO socket;
SimpleOpenNI context;

float[][] past = new float[20][13]; //20 users maximum for now.  (stores past frames dimentions used for recursdive smoothing)
ArrayList<cPersonMeans> personMeans = new ArrayList<cPersonMeans>(); //stores persons means along with global ID
float [] means = new float[12];		//used for calculating mean of current user being saved. (only features not confidence stored, hence size 12 not 13)
 

float        zoomF = 0.15f;        // was 0.1
float        rotX = radians(170);  // by default rotate the whole scene 180deg around the x-axis, was 160
                                   // the data from openni comes upside down
float        rotY = radians(0);
boolean      autoCalib=true;

PVector      bodyCenter = new PVector();
PVector      bodyDir = new PVector();
PVector      com = new PVector();                                   
PVector      com2d = new PVector();                                   
color[]      userClr = new color[]{ color(255,0,0),
                                     color(0,255,0),
                                     color(0,0,255),
                                     color(255,255,0),
                                     color(255,0,255),
                                     color(0,255,255)
                                   };
String[] names;
String username = "";
String forestfile = "C:/Users/Vijay/Documents/GitHub/occusense/src/sensor/model.xml";	//change
// Recording data to train  RF
ArrayList<String> textdata = new ArrayList<String>();
ArrayList<String> usertextdata = new ArrayList<String>();  // Contains names
int[] idguessindex = new int[50];
float[] minConfidence = new float[50];
Robot robot;
int mm = 0;                                   //time index p laceholder for robot
boolean togglerobot,togglesave,togglefalldetection;  
int savecounter = 0;
int savesize = 150;
String ipaddress = "1212http://192.168.173.1:52233/";   
boolean onsent,offsent; 
int idcount = 10;
int[][] idguess =   new int[20][idcount+1];     //UserID-1 & Names guessed by re-identification. Last array element is also used to determine if user has been confirmed
boolean[] idused = new boolean[20]; 
int[] counts = new int[5];

void setup()
{ 
  size(1024,640,P3D);  // strange, get drawing error in the cameraFrustum if i use P3D, in opengl there is no problem
  context = new SimpleOpenNI(this);
  if(context.isInit() == false)
  {
     println("Can't init SimpleOpenNI, maybe the camera is not connected!"); 
     exit();
     return;  
  }  
  // disable mirror
  context.setMirror(false); 
  context.enableDepth();
  context.enableUser();
  String[] coordsys = loadStrings("usercoordsys.txt");
  float[] usercoordsys = float(split(coordsys[0],","));
  context.setUserCoordsys(usercoordsys[0],usercoordsys[1], usercoordsys[2],
                          usercoordsys[3], usercoordsys[4], usercoordsys[5],
                          usercoordsys[6], usercoordsys[7], usercoordsys[8]);
                          
  stroke(255,255,255);
  smooth();  
  perspective(radians(60),
              float(width)/float(height),
              10,150000);

  loadData();
  loadUsers();
  loadMeans();

  try{
      robot = new Robot();  
    }
    catch(AWTException e){
      println(e);
    }
  mm = millis();
  OpenCV opencv = new OpenCV(this, "test.jpg");
  forest = new CvRTrees();
//  println("updating model");
//  findmodel();
//1        savemodel(); 
  forest.load(forestfile);  
}

void draw()
{
  // update the cam
  context.update();

  background(0,0,0);
  
  // set the scene pos
  translate(width/2, height/2, 0);
  rotateX(rotX);
  rotateY(rotY);
  scale(zoomF);
  
  int[]   depthMap = context.depthMap();
  int[]   userMap = context.userMap();
  int     steps   = 10;  // to speed up the drawing, draw every third point
  int     index;
  PVector realWorldPoint;

  // draw the pointcloud
 beginShape(POINTS);
 for(int y=0;y < context.depthHeight();y+=steps)
 {
   for(int x=0;x < context.depthWidth();x+=steps)
   {
     index = x + y * context.depthWidth();
     if(depthMap[index] > 0)
     { 
       // draw the projected point
       realWorldPoint = context.depthMapRealWorld()[index];
       if(userMap[index] == 0)
         stroke(200); 
       else{ 
         stroke(userClr[ (userMap[index] - 1) % userClr.length ]);  
       }    
       point(realWorldPoint.x,realWorldPoint.y,realWorldPoint.z);
     }
   } 
 } 
 endShape();
  
  // draw the skeleton if it's available
  int[] userList = context.getUsers();
  boolean lights=false;
  for(int i=0;i<userList.length;i++)
  {
    int ii = userList[i]-1;
    if(context.isTrackingSkeleton(userList[i]))
      drawSkeleton(userList[i]);
    
    // draw the center of mass
    if(context.getCoM(userList[i],com))
    {
      stroke(100,255,0);
      strokeWeight(1);
      beginShape(LINES);
        vertex(com.x - 15,com.y,com.z); 
        vertex(com.x + 15,com.y,com.z);        
        vertex(com.x,com.y - 15,com.z);
        vertex(com.x,com.y + 15,com.z);
        vertex(com.x,com.y,com.z - 15);
        vertex(com.x,com.y,com.z + 15);
      endShape();
      
      fill(255,255,255);textSize(200);rotateX(-rotX);
      if(idguess[ii][idcount]==0)text(Integer.toString(userList[i]),com.x,-com.y,-com.z);
      else text(names[idguessindex[ii]-1],com.x,-com.y,-com.z); //text(names[identityfound[i]-1],com.x,-com.y,-com.z);
      }
      rotateX(rotX);
    }
    
  


  if(millis()-mm>10){ // 50ms between presses
    if(togglesave){
      robot.keyPress('1'); 
      robot.keyRelease('1');
//      robot.keyPress('2'); 
//      robot.keyRelease('2');
    }else if(togglerobot){
      robot.keyPress(' ');
      robot.keyRelease(' ');
//      robot.keyPress('0');
//      robot.keyRelease('0');
    }
    mm = millis();
  }
}

// -----------------------------------------------------------------
// Keyboard events

void keyPressed()
{
  //OBTAIN USER FEATURES--------------------------------------------
  int[] userList = context.getUsers();
  float[][] unidentified = new float[userList.length][13];
  if (key != CODED){
    PVector head = new PVector();
    PVector neck = new PVector();
    PVector leftshoulder = new PVector();
    PVector rightshoulder = new PVector();
    PVector lefthip = new PVector();
	PVector righthip = new PVector();
    PVector leftknee = new PVector();
	PVector rightknee = new PVector();
    PVector rightelbow = new PVector();
	PVector leftelbow = new PVector();
    PVector righthand = new PVector();
	PVector lefthand = new PVector();
	PVector torso = new PVector();
	
    float[] confidence = new float[13];
    context.update();
    for(int i=0;i<userList.length;i++){
      if(context.isTrackingSkeleton(userList[i])){
        confidence[0] = context.getJointPositionSkeleton(userList[i],SimpleOpenNI.SKEL_HEAD,head);
        confidence[1] = context.getJointPositionSkeleton(userList[i],SimpleOpenNI.SKEL_NECK,neck);
        confidence[2] = context.getJointPositionSkeleton(userList[i],SimpleOpenNI.SKEL_LEFT_SHOULDER,leftshoulder);
        confidence[3] = context.getJointPositionSkeleton(userList[i],SimpleOpenNI.SKEL_RIGHT_SHOULDER,rightshoulder);
        confidence[4] = context.getJointPositionSkeleton(userList[i],SimpleOpenNI.SKEL_LEFT_HIP,lefthip);
		confidence[5] = context.getJointPositionSkeleton(userList[i],SimpleOpenNI.SKEL_RIGHT_HIP,righthip);
		confidence[6] = context.getJointPositionSkeleton(userList[i],SimpleOpenNI.SKEL_RIGHT_ELBOW,rightelbow);
		confidence[7] = context.getJointPositionSkeleton(userList[i],SimpleOpenNI.SKEL_LEFT_ELBOW,leftelbow);		
		confidence[8] = context.getJointPositionSkeleton(userList[i],SimpleOpenNI.SKEL_RIGHT_HAND,righthand);
		confidence[9] = context.getJointPositionSkeleton(userList[i],SimpleOpenNI.SKEL_LEFT_HAND,lefthand);
        confidence[10] = context.getJointPositionSkeleton(userList[i],SimpleOpenNI.SKEL_LEFT_KNEE,leftknee);
		confidence[11] = context.getJointPositionSkeleton(userList[i],SimpleOpenNI.SKEL_RIGHT_KNEE,rightknee);
        confidence[12] = context.getJointPositionSkeleton(userList[i],SimpleOpenNI.SKEL_TORSO,torso);		
		
		minConfidence[i]=min(confidence);
		
        unidentified[i][0] = ((1-k)*(neck.dist(head)) + k*past[i][0]);                              //Cervical Spine
        unidentified[i][1] = ((1-k)*(leftshoulder.dist(rightshoulder)) + k*past[i][1]); 
		unidentified[i][2] = ((1-k)*(torso.dist(neck)) + k*past[i][2]); 
		
		unidentified[i][3] = ((1-k)*(torso.dist(lefthip)+torso.dist(leftshoulder)) + k*past[i][3]); //+torso.dist(leftshoulder)        
        unidentified[i][4] = ((1-k)*(torso.dist(righthip)+torso.dist(rightshoulder)) + k*past[i][4]);
		
		unidentified[i][5] = ((1-k)*(rightshoulder.dist(rightelbow)) + k*past[i][5]);
		unidentified[i][6] = ((1-k)*(leftshoulder.dist(leftelbow)) + k*past[i][6]);
		
		unidentified[i][7] = ((1-k)*(rightelbow.dist(righthand)) + k*past[i][7]); 
		unidentified[i][8] = ((1-k)*(leftelbow.dist(lefthand)) + k*past[i][8]); 
		
		unidentified[i][9] = ((1-k)*(righthip.dist(lefthip)) + k*past[i][9]);
		
		unidentified[i][10] = ((1-k)*(righthip.dist(rightknee)) + k*past[i][10]);
        unidentified[i][11] = ((1-k)*(lefthip.dist(leftknee)) + k*past[i][11]);

		unidentified[i][12] = (1-k)*minConfidence[i] + k*past[i][12];

		
		past[i][0]=unidentified[i][0];
		past[i][1]=unidentified[i][1];
		past[i][2]=unidentified[i][2];
		past[i][3]=unidentified[i][3];
		past[i][4]=unidentified[i][4];
		past[i][5]=unidentified[i][5];
		past[i][6]=unidentified[i][6];
		past[i][7]=unidentified[i][7];
		past[i][8]=unidentified[i][8];
		past[i][9]=unidentified[i][9];
		past[i][10]=unidentified[i][10]; 
		past[i][11]=unidentified[i][11]; 
		past[i][12]=unidentified[i][12]; 
		
	  }
    }
  }
  
  switch(key)
  {
  case ' ':
//---For each unidentified user--------------
    for(int i=0;i<userList.length;i++){
      if(context.isTrackingSkeleton(userList[i])&&minConfidence[i]==1){ //if(idguess[userId-1][idcount]!=0)
//-------------------USING RANDOMFOREST TO RE-IDENTIFY---------------------------------  
        Mat testRow =  new Mat(1, 13, CvType.CV_32FC1);
        int ii = userList[i]-1;
        
        for(int col = 0; col < unidentified[i].length; col++){		  //copy into Mat structure as required by OpenCV
          testRow.put(0,col,unidentified[i][col]);
        }
        
		int  currentguess = int(forest.predict(testRow)+1);           //Prediction ID +1 because 0 is being used for unidentified persons
                
        if(idguessindex[ii]==idcount){
			idguess[ii][idguessindex[ii]] = currentguess;
			idguessindex[ii] = mode(idguess[ii]);             			//Calculate mode of all estimates, assign to idguessindex as final identity
          
			//cross check
			float mse = MSE(lookupMean (idguessindex[ii]-1 , personMeans), Arrays.copyOfRange(unidentified[i], 0, 12));  
			println("MSE");
			println(mse);
           
			if((mse < 550)){	  
				if(!idused[idguessindex[ii]]){         //Stop tracking skeleton once final identity confirmed      
				  context.stopTrackingSkeleton(userList[i]); 
				  println(counts);          
				  idused[idguessindex[ii]] =  true;
				}
				else{									//Restart id process again, can't have two people with the same id
				idguessindex[ii]=0;
				idguess[ii][idcount]=0;
				} 	 
			}
			else{
				idguessindex[ii]=0;
				idguess[ii][idcount]=0;
				println("unknown user detected");
			}
		}			
		else{
			idguess[ii][idguessindex[ii]] = currentguess;
			idguessindex[ii]++;                                                     //Increment idguessindex for id estimation    
			println((ii+1)+" "+names[currentguess-1]+" "+idguessindex[ii]);
			counts[currentguess-1]++;
		}
        
      }
	}
  
    break;                                                                                                                                         
//-----------------SAVE USER FEATURES, ADD NAME (TBC: AVERAGING, NAME INPUT)-----------------------------
    case '1':if(context.isTrackingSkeleton(1)&&minConfidence[0]==1)saveUser(unidentified[0]);
    break;
  }
    
  switch(keyCode)
  {
    case LEFT:
      rotY += 0.1f;
      break;
    case RIGHT:
      // zoom out
      rotY -= 0.1f;
      break;
    case UP:
      if(keyEvent.isShiftDown())
        zoomF += 0.01f;
      else
        rotX += 0.1f;
      break;
    case DOWN:
      if(keyEvent.isShiftDown())
      {
        zoomF -= 0.01f;
        if(zoomF < 0.01)
          zoomF = 0.01;
      }
      else
        rotX -= 0.1f;
      break;
      case ENTER:
          togglerobot=!togglerobot;
          if(togglerobot)println("Robot On");
          else println("Robot Off");
//        context.setMirror(!context.mirror());
      break;
      case BACKSPACE:
          if(!togglesave){
            username = showInputDialog("Please enter new ID");
            if (username == null)   exit();
            else if ("".equals(username))
              showMessageDialog(null, "Empty ID Input!!!", 
              "Alert", ERROR_MESSAGE);
            else {
              showMessageDialog(null, "Saving data for \"" + username + "\"... Please wait until console message appears!!!", 
              "Info", INFORMATION_MESSAGE);
              togglesave=true;
            }
          }
      break;
  }
}

void loadData()
{  
  Collections.addAll(textdata, loadStrings("data/data.txt"));
}

void saveData(int name, float[] savedata)
{
  textdata.add(savedata[0]+","+savedata[1]+","+savedata[2]+","+savedata[3]+","+savedata[4]+","+savedata[5]+","+savedata[6]+","+savedata[7]+","+savedata[8]+","+savedata[9]+","+ savedata[10]+","+savedata[11]+","+savedata[12] + ","+name);
}

void saveUser(float[] savefeature){
 
  if(savecounter==savesize){                //Check if enough rows of data have been collected
	
	//store means and global ID in global arraylist, and save into text file for future use.
    cPersonMeans temp = new cPersonMeans();
	temp.gpersonId = names.length;			//use assigned global ID in final code
	for(int i=0;i<12;i++){ temp.featMean[i] = means[i]/savesize; }
	personMeans.add(temp);
	saveMeans(personMeans);
	
	//write to file the new training data
	saveStrings("data/data.txt", textdata.toArray(new String[textdata.size()]));
    textdata.clear(); //are these two lines still needed?
    loadData();
    
	//Now to save User's Name into "names.txt"
    usertextdata.add(username);
    saveStrings("data/names.txt", usertextdata.toArray(new String[usertextdata.size()]));
    usertextdata.clear();  
    loadUsers();		//needed since we load the names into an array in this function, so names array will be updated.
   
    println("User Saved!");
	
    // Training Random Forests
    findmodel();
    savemodel();
	
	//reset things ready for next user
	savecounter=0;
	for(int i=0;i<12;i++) means[i] = 0;
	togglesave = false;
	
  }else{
    saveData(names.length,savefeature); //Save row of data
    
	for(int i=0;i<12;i++) {means[i] += savefeature[i];}
	
	savecounter++;
    println(" sample number: " + savecounter);
  }
}

void loadUsers()
{ 
  Collections.addAll(usertextdata, loadStrings("data/names.txt")); 
  names = new String[usertextdata.size()];
  for (int i=0; i<usertextdata.size(); i++) {
    names[i] = usertextdata.get(i);
  }
}
 
// -----------------------------------------------------------------
// SimpleOpenNI user events

void onNewUser(SimpleOpenNI curContext,int userId){
  println("New User " + userId);
  context.startTrackingSkeleton(userId);
}

void onLostUser(SimpleOpenNI curContext,int userId){                  //occurs after 10 seconds of losing user?
  println("Lost User " + userId);
  context.stopTrackingSkeleton(userId);
    idguess[userId-1] = new int[idcount+1];                           //Resets all of user's identity estimates to 0
    idused[idguessindex[userId-1]] = false;
      idguessindex[userId-1] = 0;


}

void onVisibleUser(SimpleOpenNI curContext,int userId){
  //println("onVisibleUser - userId: " + userId);
}

//----------------------------------------------------------------
