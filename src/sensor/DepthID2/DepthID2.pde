import SimpleOpenNI.*; //<>//
import java.util.Collections; 
import java.awt.Robot;
import java.awt.AWTException;
import psvm.*;
import static javax.swing.JOptionPane.*;
import io.socket.IOAcknowledge;
import io.socket.IOCallback;
import io.socket.SocketIO;
import io.socket.SocketIOException;
import org.json.JSONException;
import org.json.JSONObject;
import java.net.MalformedURLException;

SVM model;
//WebSocketP5 socket;
SocketIO socket;
SimpleOpenNI cam1,cam2;
float        zoomF = 0.14f;        // was 0.1
float        rotX = radians(150);  // by default rotate the whole scene 180deg around the x-axis, was 160
                                   // the data from openni comes upside down
float        rotY = radians(0);
boolean      autoCalib=true;
float      euc_dist;
PVector      bodyCenter = new PVector();
PVector      bodyDir = new PVector();
PVector      com = new PVector();
PVector      com2 = new PVector(); 
//PVector      euc_dist=new PVector();          
PVector      com2d = new PVector();                                   
color[]       userClr = new color[]{ color(255,0,0),
                                     color(0,255,0),
                                     color(0,0,255),
                                     color(255,255,0),
                                     color(255,0,255),
                                     color(0,255,255)
                                   };
String[] names;
String username = "New";
boolean[] idused = new boolean[20];
boolean[] idused2 = new boolean[20];
float[][] means,stds;                                      // Not used in SVM, but used to record data to train SVM
float[] userconfidence = new float[20];
float[] userconfidence2 = new float[20];

ArrayList<String> textdata = new ArrayList<String>();      // Also not used in SVM, but used to record data to train SVM
ArrayList<String> usertextdata = new ArrayList<String>();  // Contains names, users' mean and std
ArrayList<String> svmtextdata = new ArrayList<String>();   // Same as textdata but integers instead of names
Robot robot;
int mm = 0;                                 //time index placeholder for robot
boolean togglerobot,togglesave;
float[] mean,std;                           //Paramters used for Normalisation
int idcount = 10;                           //Number of times before ID is confirmed - 1  
int[][] idguess = new int[20][idcount+1];     //UserID-1 & Names guessed by re-identification. Last array element is also used to determine if user has been confirmed
int[] idguessindex = new int[20];           //Used as array index for idguess and placeholder for Final Identity once finished
int[][] idguess2 = new int[20][idcount+1];     //UserID-1 & Names guessed by re-identification. Last array element is also used to determine if user has been confirmed
int[] idguessindex2 = new int[20];           //Used as array index for idguess and placeholder for Final Identity once finished
int savecounter=0;
ArrayList<float[]> savefeaturelist = new ArrayList<float[]>();

// used for multiple cameras
boolean[] same1 = new boolean[20];           
boolean[] same2 = new boolean[20];           
boolean[] camera1 = new boolean[20];           
boolean[] camera2 = new boolean[20];           

//SimpleOpenNI curContext;


//ArrayList<boolean[]> same1 = new ArrayList<boolean[]>();
//ArrayList<boolean> same2 = new ArrayList<boolean>();
//
//ArrayList<boolean> camera1 = new ArrayList<boolean>();
//ArrayList<boolean> camera2 = new ArrayList<boolean>();


void setup()
{ 
  size(1024,768,P3D);  // strange, get drawing error in the cameraFrustum if i use P3D, in opengl there is no problem
  SimpleOpenNI.start();
  cam1 = new SimpleOpenNI(0,this);
  cam2 = new SimpleOpenNI(1,this);
  
  println(cam1);
  println(cam2);

  
  if(cam1.isInit() == false || cam2.isInit() == false)
  {
     println("Can't init SimpleOpenNI, maybe the camera is not connected!"); 
     exit();
     return;  
  }  
  // disable mirror
  cam1.setMirror(false); 
  cam1.enableDepth();
  cam1.enableUser();
  cam2.enableDepth();
  cam2.enableUser();
  String[] coordsys = loadStrings("usercoordsysdoor.txt");
  float[] usercoordsys = float(split(coordsys[0],","));
  cam1.setUserCoordsys(usercoordsys[0],usercoordsys[1], usercoordsys[2],
                          usercoordsys[3], usercoordsys[4], usercoordsys[5],
                          usercoordsys[6], usercoordsys[7], usercoordsys[8]);
  coordsys = loadStrings("usercoordsyspodium.txt");
  usercoordsys = float(split(coordsys[0],","));
  cam2.setUserCoordsys(usercoordsys[0],usercoordsys[1], usercoordsys[2],
                          usercoordsys[3], usercoordsys[4], usercoordsys[5],
                          usercoordsys[6], usercoordsys[7], usercoordsys[8]);                        
  stroke(255,255,255);
  smooth();  
  perspective(radians(60),
              float(width)/float(height),
              10,150000);
 loadData();  // For Cumulative Matching Curve
 loadUsers();
 loadScalingData();
 
   try{
      robot = new Robot();  
    }
    catch(AWTException e){
      println(e);
    }
  
  mm = millis();
  model = new SVM(this);
  model.loadModel("model.txt",8);
}
  
  void draw()
{
  // update the cam
  SimpleOpenNI.updateAll();
  background(0,0,0);
  
  // set the scene pos
  translate(width/2, height/2, 0);
  rotateX(rotX);
  rotateY(rotY);
  scale(zoomF);
  
  int[]   depthMap = cam1.depthMap();
  int[]   userMap = cam1.userMap();
  int[]   depthMap2 = cam2.depthMap();
  int[]   userMap2 = cam2.userMap();
  int     steps   = 3;  // to speed up the drawing, draw every third point
  int     index;
  PVector realWorldPoint;
 
//  translate(0,0,-1000);  // set the rotation center of the scene 1000 infront of the camera

  // draw the pointcloud
  beginShape(POINTS);
  for(int y=0;y < cam1.depthHeight();y+=steps)
  {
    for(int x=0;x < cam1.depthWidth();x+=steps)
    {
      index = x + y * cam1.depthWidth();
      if(depthMap[index] > 0)
      { 
        // draw the projected point
        realWorldPoint = cam1.depthMapRealWorld()[index];
        if(userMap[index] == 0)
          stroke(100); 
        else{
          stroke(userClr[ (userMap[index] - 1) % userClr.length ]);  
        }    
        point(realWorldPoint.x,realWorldPoint.y,realWorldPoint.z);
      }
      if(depthMap2[index] > 0)
      { 
        // draw the projected point
        realWorldPoint = cam2.depthMapRealWorld()[index];
        if(userMap2[index] == 0)
          stroke(100); 
        else{
          stroke(userClr[ (userMap2[index] - 1) % userClr.length ]);  
        }    
        point(realWorldPoint.x,realWorldPoint.y,realWorldPoint.z);
      }
    } 
  } 
  endShape();
    
  
  // draw the skeleton 1 if it's available
  int[] userList = cam1.getUsers(); //Identifies each user, each user is identified by a number 
  int[] userList2 = cam2.getUsers(); //Identifies each user, each user is identified by a number 
  
  for(int i=0;i<userList.length;i++)
  {
    int ii = userList[i]-1;
    if(cam1.isTrackingSkeleton(userList[i]))
      drawSkeleton(userList[i],cam1);
    
    // draw the center of mass
    if(cam1.getCoM(userList[i],com))
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
  // println("Center of mass of user viewed by cam1:" +com.x+","+com.y+","+com.z) ;
  for(int i=0;i<userList2.length;i++)
  {
    int ii = userList2[i]-1;
    if(cam2.isTrackingSkeleton(userList2[i]))
      drawSkeleton(userList2[i],cam2);
    
    // draw the center of mass
    if(cam2.getCoM(userList2[i],com2))
    { 
      stroke(100,255,0);
      strokeWeight(1);
      beginShape(LINES);
        vertex(com2.x - 15,com2.y,com2.z); 
        vertex(com2.x + 15,com2.y,com2.z);     
        vertex(com2.x,com2.y - 15,com2.z);
        vertex(com2.x,com2.y + 15,com2.z);
        vertex(com2.x,com2.y,com2.z - 15);
        vertex(com2.x,com2.y,com2.z + 15);
      endShape();
      
      fill(255,255,255);textSize(200);rotateX(-rotX);
                if(idguess2[ii][idcount]==0)text(Integer.toString(userList2[i]),com.x,-com.y,-com.z);
      else text(names[idguessindex2[ii]-1],com.x,-com.y,-com.z); //text(names[identityfound[i]-1],com.x,-com.y,-com.z);

      
      }
      rotateX(rotX);
    }
    // println("Center of mass of user viewed by cam2: " +com2.x+","+com2.y+","+com2.z);  
    if(millis()-mm>35){ // 50ms between presses
    if(togglesave){
      robot.keyPress('1'); 
      robot.keyRelease('1');
      robot.keyPress('2'); 
      robot.keyRelease('2');
    }else if(togglerobot){
      robot.keyPress(' ');
      robot.keyRelease(' ');
      robot.keyPress('0');
      robot.keyRelease('0');
    }
    mm = millis();
  } 
    
 }
  
  void keyPressed()
{
  int[] userList = cam1.getUsers();
  int[] userList2 = cam2.getUsers();
  int threshold = 500;  // MISSING!!!!!!
      // In that two cameras track
      float[][] unidentified = new float[userList.length][8];
      float[][] copyunidentified = new float[userList.length][8];
      
    float[][] unidentified2 = new float[userList2.length][8];
    float[][] copyunidentified2 = new float[userList2.length][8];
       
  // CALCULATING THE DISTANCE BETWEEN TWO POINTS
//    euc_dist.x = Math.abs (com.x - com2.x);
//    euc_dist.y = Math.abs (com.y - com2.y);    
//    euc_dist.z = Math.abs (com.z - com2.z);
//    euc_dist.distance = Math.sqrt((euc_dist.y)*(euc_dist.y) +(euc_dist.x)*(euc_dist.x)+(euc_dist.z)*(euc_dist.z));
    
  
  if (key != CODED){
    PVector head = new PVector();
    PVector neck = new PVector();
    PVector leftshoulder = new PVector();
    PVector rightshoulder = new PVector();
    PVector lefthip = new PVector();
    PVector leftknee = new PVector();
    PVector torso = new PVector();
    PVector rightelbow = new PVector();
    PVector righthand = new PVector();
  //    PVector belly = new PVector();
    float[] confidence = new float[9];
    float[] confidence2 = new float[9];

    cam1.update();
    cam2.update();
  userList = cam1.getUsers();
  userList2 = cam2.getUsers();
  
  //println("Number of users 1: " + userList.length);
  //println("Number of users 2: " + userList2.length);
  
    // initialise bools to false
  for(int i=0;i<userList.length;i++){
    same1[i] = false;
    //println("usrlist 1 elem " + i + " value " + userList[i]);
  }
    
 
  for(int j=0;j<userList2.length;j++){
    same2[j] = false;
    //println("usrlist 2 elem " + j + " value " + userList2[j]);
  }

  for(int i=0;i<userList.length;i++){  
  //boolean dont_overwrite = false; // bool to prevent overwritting true condition after com match has been found between two cameras
    cam1.getCoM(userList[i],com);
  
  
  if(cam1.isTrackingSkeleton(userList[i])){
        confidence[0] = cam1.getJointPositionSkeleton(userList[i],SimpleOpenNI.SKEL_HEAD,head);
        confidence[1] = cam1.getJointPositionSkeleton(userList[i],SimpleOpenNI.SKEL_NECK,neck);
        confidence[2] = cam1.getJointPositionSkeleton(userList[i],SimpleOpenNI.SKEL_LEFT_SHOULDER,leftshoulder);
        confidence[3] = cam1.getJointPositionSkeleton(userList[i],SimpleOpenNI.SKEL_RIGHT_SHOULDER,rightshoulder);
        confidence[4] = cam1.getJointPositionSkeleton(userList[i],SimpleOpenNI.SKEL_LEFT_HIP,lefthip);
        confidence[5] = cam1.getJointPositionSkeleton(userList[i],SimpleOpenNI.SKEL_LEFT_KNEE,leftknee);
        confidence[6] = cam1.getJointPositionSkeleton(userList[i],SimpleOpenNI.SKEL_TORSO,torso);
        confidence[7] = cam1.getJointPositionSkeleton(userList[i],SimpleOpenNI.SKEL_RIGHT_ELBOW,rightelbow);
        confidence[8] = cam1.getJointPositionSkeleton(userList[i],SimpleOpenNI.SKEL_RIGHT_HAND,righthand);
        userconfidence[i]= min(confidence);        
        unidentified[i][0] = neck.dist(head);                              //Cervical Spine
    unidentified[i][1] = leftshoulder.dist(rightshoulder); 
    unidentified[i][2] = torso.dist(neck); 
    unidentified[i][3] = neck.dist(head)+leftshoulder.dist(lefthip)+lefthip.dist(leftknee);
    unidentified[i][4] = torso.dist(lefthip)+torso.dist(leftshoulder); //+torso.dist(leftshoulder)        
    unidentified[i][5] = rightshoulder.dist(rightelbow);
    unidentified[i][6] = rightelbow.dist(righthand); 
    unidentified[i][7] = userconfidence[i];     
    }
    
    
  for(int j=0;j<userList2.length;j++){
        cam2.getCoM(userList2[j],com2);
    
    euc_dist = dist(com.x,com.y,com.z,com2.x,com2.y,com2.z);
      
    
        if(cam2.isTrackingSkeleton(userList2[j])){

      confidence2[0] = cam2.getJointPositionSkeleton(userList2[j],SimpleOpenNI.SKEL_HEAD,head);
      confidence2[1] = cam2.getJointPositionSkeleton(userList2[j],SimpleOpenNI.SKEL_NECK,neck);
      confidence2[2] = cam2.getJointPositionSkeleton(userList2[j],SimpleOpenNI.SKEL_LEFT_SHOULDER,leftshoulder);
      confidence2[3] = cam2.getJointPositionSkeleton(userList2[j],SimpleOpenNI.SKEL_RIGHT_SHOULDER,rightshoulder);
      confidence2[4] = cam2.getJointPositionSkeleton(userList2[j],SimpleOpenNI.SKEL_LEFT_HIP,lefthip);
      confidence2[5] = cam2.getJointPositionSkeleton(userList2[j],SimpleOpenNI.SKEL_LEFT_KNEE,leftknee);
      confidence2[6] = cam2.getJointPositionSkeleton(userList2[j],SimpleOpenNI.SKEL_TORSO,torso);
      confidence2[7] = cam2.getJointPositionSkeleton(userList2[j],SimpleOpenNI.SKEL_RIGHT_ELBOW,rightelbow);
      confidence2[8] = cam2.getJointPositionSkeleton(userList2[j],SimpleOpenNI.SKEL_RIGHT_HAND,righthand);

      userconfidence2[j]= min(confidence2);        
            unidentified2[i][0] = neck.dist(head);                              //Cervical Spine
      unidentified2[i][1] = leftshoulder.dist(rightshoulder); 
      unidentified2[i][2] = torso.dist(neck); 
      unidentified2[i][3] = neck.dist(head)+leftshoulder.dist(lefthip)+lefthip.dist(leftknee);
      unidentified2[i][4] = torso.dist(lefthip)+torso.dist(leftshoulder); //+torso.dist(leftshoulder)        
      unidentified2[i][5] = rightshoulder.dist(rightelbow);
      unidentified2[i][6] = rightelbow.dist(righthand); 
      unidentified2[i][7] = userconfidence2[i]; 
    }
      
    //println(userconfidence[i]);
 
  
/*     if (euc_dist < threshold ){
      same1[i] = true;
      same2[j] = true;

      if (userconfidence[i] > userconfidence2[j]){
        camera1[i] = true;
        camera2[j] = false;
      }
        
      else{
        camera1[i] = false;
        camera2[j] = true;
      }
      
    } */
 
    }
  } // end for outer loop
  
  
  }
     switch(key)
  {
  case ' ':

       //---For each unidentified user in camera 1--------------
    for(int i=0;i<userList.length;i++){  
    int ii = userList[i]-1;
    int currentguess;
    boolean withinthreshold = true;
    
    if ((same1[i] && camera1[i]) || !same1[i]){
      
      println("im here yo vijay sucks 1 " + i + " user conf " + userconfidence[i]);
    
      if(cam1.isTrackingSkeleton(userList[i])&&userconfidence[i]>0.6){ //if(idguess[userId-1][idcount]!=0)
      
      
//-------------------USING SVM TO RE-IDENTIFY---------------------------------  
        for(int j=0;j<mean.length;j++){
          copyunidentified[i][j] = unidentified[i][j];                    //Copy unidentified matrix for Threshold Comparison (Not part of SVM)
          unidentified[i][j] = (unidentified[i][j]-mean[j])/std[j];       //Normalize by subtracting mean and dividing by standard deviation
        } 
        
        currentguess = (int)model.test(unidentified[i]);
                                println("cam1 guess: " + currentguess);

        for(int j=0;j<mean.length-1;j++){                                           //Now perform THRESHOLD COMPARISON to cross-check SVM's euc_dist,but ignore CONFIDENCE which has no threshold
          if(abs(copyunidentified[i][j]-means[currentguess-1][j])>1.5*stds[currentguess-1][j])
            withinthreshold=false;
        }
        
        if(idguessindex[ii]==idcount && withinthreshold){
          idguess[ii][idguessindex[ii]] = currentguess;
          idguessindex[ii] = mode(idguess[ii]);                                   //Calculate mode of all estimates, assign to idguessindex as final identity
          if(!idused[idguessindex[ii]]){             
            cam1.stopTrackingSkeleton(userList[i]);                              //Stop tracking skeleton once final identity confirmed
            idused[idguessindex[ii]] = true;       
          }
          else{
            idguessindex[ii]=0;idguess[ii][idcount]=0;
          }                       //Restart id process again, can't have two people with the same id
        }      
        
        
        else if(withinthreshold){
          idguess[ii][idguessindex[ii]] = currentguess;
          idguessindex[ii]++;                                                     //Increment idguessindex for id estimation    
          println(idguessindex[ii]+" "+names[currentguess-1]);
//          println(copyunidentified[i]);
            // SEND INFO TO SERVER
        }
      }
    }      
  }
  
  
  
  
      for(int i=0;i<userList2.length;i++){  
      int ii = userList2[i]-1;
      int currentguess;
      boolean withinthreshold = true;
    
    if ((same2[i] && camera2[i]) || !same2[i]){
      
            println("im here yo vijay sucks 2 " + i + " user conf " + userconfidence2[i]);

       
      if(cam2.isTrackingSkeleton(userList2[i])&&userconfidence2[i]>0.6){ //if(idguess[userId-1][idcount]!=0)
//-------------------USING SVM TO RE-IDENTIFY---------------------------------  
        for(int j=0;j<mean.length;j++){
          copyunidentified2[i][j] = unidentified2[i][j];                    //Copy unidentified matrix for Threshold Comparison (Not part of SVM)
          unidentified2[i][j] = (unidentified2[i][j]-mean[j])/std[j];       //Normalize by subtracting mean and dividing by standard deviation
        } 
        currentguess = (int)model.test(unidentified2[i]);
        println("cam2 guess: " + currentguess);
        for(int j=0;j<mean.length-1;j++){                                           //Now perform THRESHOLD COMPARISON to cross-check SVM's euc_dist,but ignore CONFIDENCE which has no threshold
          if(abs(copyunidentified2[i][j]-means[currentguess-1][j])>1.5*stds[currentguess-1][j])withinthreshold=false;
         }
        if(idguessindex2[ii]==idcount && withinthreshold){
          idguess2[ii][idguessindex2[ii]] = currentguess;
          idguessindex2[ii] = mode(idguess2[ii]);                                   //Calculate mode of all estimates, assign to idguessindex2 as final identity
          if(!idused[idguessindex2[ii]]){             
          cam2.stopTrackingSkeleton(userList2[i]);                              //Stop tracking skeleton once final identity confirmed
          idused[idguessindex2[ii]] = true;       
          }else{idguessindex2[ii]=0;idguess2[ii][idcount]=0;}                       //Restart id process again, can't have two people with the same id
        }      
        else if(withinthreshold){
          idguess2[ii][idguessindex2[ii]] = currentguess;
          idguessindex2[ii]++;                                                     //Increment idguessindex2 for id estimation    
          println(idguessindex2[ii]+" "+names[currentguess-1]);
//          println(copyunidentified[i]);
            // SEND INFO TO SERVER

        }
      }
    }      
  }
  
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
  Collections.addAll(textdata, loadStrings("data.txt"));
  Collections.addAll(svmtextdata, loadStrings("svmdata.txt"));
}

void loadUsers()
{ 
  Collections.addAll(usertextdata, loadStrings("names.txt")); 
  means = new float[usertextdata.size()/3][8];
  stds = new float[usertextdata.size()/3][8]; 
  names = new String[usertextdata.size()/3];
  for (int i=0; i<usertextdata.size(); i++) {
  // 0.3.6.9th... lines are Names, 1.4.7.10th.. lines are Means, 2.5.8.11th..lines are STDs
    if(i%3==0)names[i/3] = usertextdata.get(i);
    else if(i%3==1){
  // Each line is split into an array of floating point numbers.
      float[] values = float(split(usertextdata.get(i), "," )); 
      means[(i-1)/3][0] = values[0];  
      means[(i-1)/3][1] = values[1];
      means[(i-1)/3][2] = values[2];  
      means[(i-1)/3][3] = values[3];  
      means[(i-1)/3][4] = values[4];  
      means[(i-1)/3][5] = values[5]; 
      means[(i-1)/3][6] = values[6];  
      means[(i-1)/3][7] = values[7];   
    }else if(i%3==2){
      float[] values = float(split(usertextdata.get(i), "," )); 
      stds[(i-2)/3][0] = values[0];  
      stds[(i-2)/3][1] = values[1];
      stds[(i-2)/3][2] = values[2];  
      stds[(i-2)/3][3] = values[3];  
      stds[(i-2)/3][4] = values[4];  
      stds[(i-2)/3][5] = values[5]; 
      stds[(i-2)/3][6] = values[6];  
      stds[(i-2)/3][7] = values[7]; 
    }
  }
}

void loadScalingData()
{
  String[] scaledata = loadStrings("scaling.txt");
  mean = float(split(scaledata[0],","));
  std = float(split(scaledata[1],","));
}

void onNewUser(SimpleOpenNI curContext,int userId){
 // println("New User " + userId);
 if(cam1 == curContext){
   cam1.startTrackingSkeleton(userId);
 }
 else{
   cam2.startTrackingSkeleton(userId);
 }
   println("new user detected: " + userId);
    //println(curContext);

}

void onLostUser(SimpleOpenNI curContext,int userId){                  //occurs after 10 seconds of losing user?
  println("Lost User " + userId);

if(cam1 == curContext){
  cam1.stopTrackingSkeleton(userId);
  
  idguess[userId-1] = new int[idcount+1];                             //Resets all of user's identity estimates to 0
  idused[idguessindex[userId-1]] = false;
  idguessindex[userId-1] = 0;
}
else{
  cam2.stopTrackingSkeleton(userId);
     idguess2[userId-1] = new int[idcount+1];                             //Resets all of user's identity estimates to 0
  idused2[idguessindex2[userId-1]] = false;
  idguessindex2[userId-1] = 0;
}

  
 
}

void onVisibleUser(SimpleOpenNI curContext,int userId){
  //println("onVisibleUser - userId: " + userId);
}
