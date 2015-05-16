import SimpleOpenNI.*;
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
SocketIO socket;
SimpleOpenNI cam1,cam2;
float        zoomF = 0.14f;        // was 0.1]                                                                                                                                                                                                                [
float        rotX = radians(150);  // by default rotate the whole scene 180deg around the x-axis, was 160
                                   // the data from openni comes upside down
float        rotY = radians(0);
boolean      autoCalib=true;

PVector      bodyCenter = new PVector();
PVector      bodyDir = new PVector();
PVector      com = new PVector();                                   
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
float[][] means,stds;                                      // Not used in SVM, but used to record data to train SVM
float[] userconfidence = new float[20];
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
int savecounter=0;
ArrayList<float[]> savefeaturelist = new ArrayList<float[]>();

void setup()
{ 
  size(1024,768,P3D);  // strange, get drawing error in the cameraFrustum if i use P3D, in opengl there is no problem
  SimpleOpenNI.start();
  cam1 = new SimpleOpenNI(0,this);
  cam2 = new SimpleOpenNI(1,this);
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
//  socket = new WebSocketP5(this,9237);
  socket = new SocketIO();
  try{socket.connect("http://192.168.173.1:52233/", new IOCallback(){
    public void onMessage(JSONObject json, IOAcknowledge ack){println("Server sent JSON");}
    public void onMessage(String data, IOAcknowledge ack) {println("Server sent Data");}
    public void onError(SocketIOException socketIOException) {println("Error Occurred");socketIOException.printStackTrace();}
    public void onDisconnect() {println("Connection terminated.");}
    public void onConnect() {println("Connection established");}
    public void on(String event, IOAcknowledge ack, Object... args) {println("Server triggered event");}
  });}catch(MalformedURLException e1){e1.printStackTrace();}
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
  
//  // draw the skeleton if it's available
//  int[] userList = cam1.getUsers();
//  for(int i=0;i<userList.length;i++)
//  {
//    int ii = userList[i]-1; 
//    if(cam1.isTrackingSkeleton(userList[i]))
//      drawSkeleton(userList[i]);
//    
//    // draw the center of mass
//    if(cam1.getCoM(userList[i],com))
//    {
//      stroke(100,255,0);
//      strokeWeight(1);
//      beginShape(LINES);
//        vertex(com.x - 15,com.y,com.z); 
//        vertex(com.x + 15,com.y,com.z);        
//        vertex(com.x,com.y - 15,com.z);
//        vertex(com.x,com.y + 15,com.z);
//        vertex(com.x,com.y,com.z - 15);
//        vertex(com.x,com.y,com.z + 15);
//      endShape();
//      
//      fill(255,255,255);textSize(200);rotateX(-rotX);
//      if(idguess[ii][idcount]==0)text(Integer.toString(userList[i]),com.x,-com.y,-com.z);
//      else text(names[idguessindex[ii]-1],com.x,-com.y,-com.z); //text(names[identityfound[i]-1],com.x,-com.y,-com.z);
//      rotateX(rotX);
//    }      
//  }    
 
// //Display userdef null point
//  strokeWeight(20);
////  stroke(255,0,0);//RED X-AXIS(LEFT-RIGHT)
////  line(0,0,0,500,0,0);
//    
//  stroke(0,255,0);//GREEN Y-AXIS(FLOOR-CEILING)
//  line(0,0,0,0,500,0);
//
//  stroke(0,0,255);//BLUE Z-AXIS(NEAR-FAR)
////  line(0,0,0,0,0,-500);
//  rotateX(-PI/2);
//  rect(0,0,500,500);
//  strokeWeight(1);

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

// -----------------------------------------------------------------
// Keyboard events

void keyPressed()
{
  int[] userList = cam1.getUsers();
  float[][] unidentified = new float[userList.length][8];
  float[][] copyunidentified = new float[userList.length][8];
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
    cam1.update();
    for(int i=0;i<userList.length;i++){
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
//        cam1.convertRealWorldToProjective(torso, belly);
//        belly = cam1.depthMapRealWorld()[(int)belly.x+(int)belly.y*cam1.depthWidth()];
        userconfidence[i]= min(confidence);
        unidentified[i][0] = neck.dist(head);                              //Cervical Spine
        unidentified[i][1] = leftshoulder.dist(rightshoulder); 
        unidentified[i][2] = torso.dist(neck); 
//        unidentified[i][3] = torso.dist(leftshoulder);                   //Shall we replace this with height?
        unidentified[i][3] = neck.dist(head)+leftshoulder.dist(lefthip)+lefthip.dist(leftknee);
        unidentified[i][4] = torso.dist(lefthip)+torso.dist(leftshoulder); //+torso.dist(leftshoulder)        
        unidentified[i][5] = rightshoulder.dist(rightelbow);
        unidentified[i][6] = rightelbow.dist(righthand); 
        unidentified[i][7] = userconfidence[i];                            //leftknee.dist(lefthip);       
      }
    }
  }
  
  switch(key)
  {
  case ' ':
//---For each unidentified user--------------
    for(int i=0;i<userList.length;i++){
      int ii = userList[i]-1;
      int currentguess;
      boolean withinthreshold = true;
      if(cam1.isTrackingSkeleton(userList[i])&&userconfidence[i]>0.6){ //if(idguess[userId-1][idcount]!=0)
//-------------------USING SVM TO RE-IDENTIFY---------------------------------  
        for(int j=0;j<mean.length;j++){
          copyunidentified[i][j] = unidentified[i][j];                    //Copy unidentified matrix for Threshold Comparison (Not part of SVM)
          unidentified[i][j] = (unidentified[i][j]-mean[j])/std[j];       //Normalize by subtracting mean and dividing by standard deviation
        } 
        currentguess = (int)model.test(unidentified[i]);
        for(int j=0;j<mean.length-1;j++){                                           //Now perform THRESHOLD COMPARISON to cross-check SVM's result,but ignore CONFIDENCE which has no threshold
          if(userconfidence[i]<1){
             if(abs(copyunidentified[i][j]-means[currentguess-1][j])>2*stds[currentguess-1][j])withinthreshold=false; 
          }
          else{
            if(abs(copyunidentified[i][j]-means[currentguess-1][j+8])>1.4*stds[currentguess-1][j+8])withinthreshold=false;
          }
         }
        if(idguessindex[ii]==idcount && withinthreshold){
          idguess[ii][idguessindex[ii]] = currentguess;
          idguessindex[ii] = mode(idguess[ii]);                                   //Calculate mode of all estimates, assign to idguessindex as final identity
          if(!idused[idguessindex[ii]]){             
          cam1.stopTrackingSkeleton(userList[i]);                              //Stop tracking skeleton once final identity confirmed
          idused[idguessindex[ii]] = true;       
          }else{idguessindex[ii]=0;idguess[ii][idcount]=0;}                       //Restart id process again, can't have two people with the same id
        }      
        else if(withinthreshold){
          idguess[ii][idguessindex[ii]] = currentguess;
          idguessindex[ii]++;                                                     //Increment idguessindex for id estimation    
          println((ii+1)+" "+names[currentguess-1]+" "+idguessindex[ii]);
        }
      }
    }
    break;                                                                                                                                       
//-----------------SAVE USER FEATURES, ADD NAME (TBC: AVERAGING, NAME INPUT)-----------------------------
    case '1':if(cam1.isTrackingSkeleton(1)&&userconfidence[0]>0.6)saveUser(unidentified[0]);
    break;
    case '2':if(cam1.isTrackingSkeleton(2)&&userconfidence[1]>0.6)saveUser(unidentified[1]);
    break;
    case '3':if(cam1.isTrackingSkeleton(3)&&userconfidence[2]>0.6)saveUser(unidentified[2]);
    break;
    case '4':if(cam1.isTrackingSkeleton(4)&&userconfidence[3]>0.6)saveUser(unidentified[3]);
    break;
    case '5':if(cam1.isTrackingSkeleton(5)&&userconfidence[4]>0.6)saveUser(unidentified[4]);
    break;
//---------Send XY Coordinates over WebSocket----------------------------------
    case '0':
      String xx = "{\"type\":\"FeatureCollection\",\"features\":[";
      for(int i=0;i<userList.length;i++){
        int ii = userList[i]-1;
        cam1.getCoM(userList[i],com);
        if(idguess[ii][idcount]>0){       
//          xx += "{\"type\":\"Feature\",\"properties\":{\"id\":"+(i+1)+",\"name\":\""+names[idguessindex[ii]-1]+"\"},\"geometry\":{\"type\":\"Point\",\"coordinates\":["+map(com.x,-2000,2000,300,800)+","+map(com.z,-500,5000,500,1000)+"]}},";
          xx += "{\"type\":\"Feature\",\"properties\":{\"id\":"+(i+1)+",\"name\":\""+names[idguessindex[ii]-1]+"\"},\"geometry\":{\"type\":\"Point\",\"coordinates\":["+map(-com.x,-2000,2000,50,650)+","+map(-com.z,-5000,500,400,1300)+"]}},";  
      }else{
//          xx += "{\"type\":\"Feature\",\"properties\":{\"id\":"+(i+1)+",\"name\":\"?\"},\"geometry\":{\"type\":\"Point\",\"coordinates\":["+map(com.x,-2000,2000,300,800)+","+map(com.z,-500,5000,500,1000)+"]}},";
          xx += "{\"type\":\"Feature\",\"properties\":{\"id\":"+(i+1)+",\"name\":\"?\"},\"geometry\":{\"type\":\"Point\",\"coordinates\":["+map(-com.x,-2000,2000,50,650)+","+map(-com.z,-5000,500,400,1300)+"]}},";  
      }
      }
//      socket.broadcast(xx.substring(0,xx.length()-1)+"]}");  //Subtract the last comma and end the json packet
      socket.emit("sendPeopleLocation", xx.substring(0,xx.length()-1)+"]}");
//      println(xx);
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
//        cam1.setMirror(!cam1.mirror());
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

void saveData(String name, float[] savedata)
{
  textdata.add(name);
  textdata.add(savedata[0]+","+savedata[1]+","+savedata[2]+","+savedata[3]+","+savedata[4]+","+savedata[5]+","+savedata[6]+","+savedata[7]);
  saveStrings("data.txt", textdata.toArray(new String[textdata.size()]));
  textdata.clear();
  svmtextdata.add(names.length+"");
  svmtextdata.add(savedata[0]+","+savedata[1]+","+savedata[2]+","+savedata[3]+","+savedata[4]+","+savedata[5]+","+savedata[6]+","+savedata[7]);
  saveStrings("svmdata.txt", svmtextdata.toArray(new String[svmtextdata.size()]));
  svmtextdata.clear();
  loadData();
}

void saveUser(float[] savefeature)    //Currently VERY INEFFICIENT. But not a big problem as saving text file is not time-constrained
{
  int savesize = 200;
  if(savecounter==savesize){                //Now that enough data has been collected, do some preprocessing (discard outliers) before saving to text
    float[] featuremean = new float[8];
    float[] featurestd = new float[8];
    for(int j=0;j<8;j++){
      for(int k=0;k<savesize;k++){
        featuremean[j] += savefeaturelist.get(k)[j]; //+= to sum for calculation of mean 
      }  
      featuremean[j] = featuremean[j]/savesize;  //Actually Mean
      for(int kk=0;kk<savesize;kk++){
        featurestd[j] += (savefeaturelist.get(kk)[j]-featuremean[j])*(savefeaturelist.get(kk)[j]-featuremean[j]);
      }
      featurestd[j] = sqrt(featurestd[j]/savesize); //Actually Standard Deviation
    }
    //Now to save User's Means and STDs into "names.txt"
    usertextdata.add(username);
    usertextdata.add(featuremean[0]+","+featuremean[1]+","+featuremean[2]+","+featuremean[3]+","+featuremean[4]+","+featuremean[5]+","+featuremean[6]+","+featuremean[7]);
    usertextdata.add(featurestd[0]+","+featurestd[1]+","+featurestd[2]+","+featurestd[3]+","+featurestd[4]+","+featurestd[5]+","+featurestd[6]+","+featurestd[7]);
    saveStrings("names.txt", usertextdata.toArray(new String[usertextdata.size()]));
    usertextdata.clear();
    loadUsers();
    //Now we have mean and std for each feature, next is to discard outlier frames with any feature beyond 2stds of mean
    for(int i=0;i<savesize;i++){
      boolean discard = false;
      for(int j=0;j<7;j++){
        if(abs(savefeaturelist.get(i)[j]-featuremean[j])>1.5*featurestd[j])discard=true;
      }
      if(!discard){saveData(username, savefeaturelist.get(i));}
    }
    savecounter=0;
    savefeaturelist = new ArrayList<float[]>();
    togglesave = false;
    println("Data Saved........");
  }else{
    savefeaturelist.add(savefeature);
    savecounter++;
  }
}

void loadScalingData()
{
  String[] scaledata = loadStrings("scaling.txt");
  mean = float(split(scaledata[0],","));
  std = float(split(scaledata[1],","));
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
 
// -----------------------------------------------------------------
// SimpleOpenNI user events

void onNewUser(SimpleOpenNI curcam1,int userId){
  println("New User " + userId);
  cam1.startTrackingSkeleton(userId);
}

void onLostUser(SimpleOpenNI curcam1,int userId){                  //occurs after 10 seconds of losing user?
  println("Lost User " + userId);
  cam1.stopTrackingSkeleton(userId);
  idguess[userId-1] = new int[idcount+1];                             //Resets all of user's identity estimates to 0
  idused[idguessindex[userId-1]] = false;
  idguessindex[userId-1] = 0;
}

void onVisibleUser(SimpleOpenNI curcam1,int userId){
  //println("onVisibleUser - userId: " + userId);
}

//----------------------------------------------------------------
