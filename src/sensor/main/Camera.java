import processing.core.PApplet;
import SimpleOpenNI.*;

// Class: Camera
// Super: SimpleOpenNI
// Provides constructor to instantiate SimpleOpenNI and other methods and callbacks
public class Camera extends SimpleOpenNI {

    // Class constructor
    Camera(PApplet p, int devIndex) {
        super(devIndex, p, SimpleOpenNI.RUN_MODE_MULTI_THREADED);
    
        // Enable depth map generation
        if(!this.enableDepth()){
            System.out.println("No device found!!");
        } 
        else {
            System.out.println("Device connected!!");
          
            // Enable skeleton generation
            this.enableUser();
        }
    }
  
}
