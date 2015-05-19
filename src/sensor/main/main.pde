// Imports 
import processing.core.*;
import SimpleOpenNI.*;

// Class: main
// Super: PApplet
public class main extends PApplet {

    //  An array of camera objects
    int numCams = 2;
    Camera[] cams = new Camera[numCams];
    
    // Processing running in "Java" mode so main function 
    // required to call PApplet.main
    public static void main(String[] args) {
        String fullClassName = main.class.getName();
        PApplet.main(fullClassName);
    }
  
    public void setup() {
        size(1280,960, P3D); 
        
        // Load the library
        SimpleOpenNI.start();
        
        // Initialize all cams
        for (int i = 0; i < cams.length; i++) {
            cams[i] = new Camera(this, i);
        }
                             
    }
  
    public void draw() {
        // Update the cams
        SimpleOpenNI.updateAll();
        image(cams[0].depthImage(), 0, 0);
        image(cams[1].depthImage(), 640, 460);
        /* ADD DRAW CODE HERE */
    }
    
    public void debug(){
      /* ADD DEBUG CODE HERE */
    }
    
    public void multicam(){
      /* ADD MULTICAM CODE HERE */
    }
    
    public void reidentify(){
      /* ADD SVM CODE HERE */
    }
    
    public void onNewUser(SimpleOpenNI curcams,int userId){
      // Called when new user detected
    }
  
    public void onLostUser(SimpleOpenNI curcams,int userId) {
      // Called 10 seconds after losing user
    
    }
  
    public void onVisibleUser(SimpleOpenNI curcams,int userId){
    
    }
 
}
