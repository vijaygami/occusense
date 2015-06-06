import SimpleOpenNI.*;
import processing.core.*;

// Class: Camera
// Super: SimpleOpenNI
// Provides constructor to instantiate SimpleOpenNI and other methods and callbacks
class Camera extends SimpleOpenNI {

  // Class constructor
  Camera(PApplet p, int devIndex) {
    super(devIndex, p, SimpleOpenNI.RUN_MODE_MULTI_THREADED);

    // Enable depth map generation
    if (!this.enableDepth()) {
      System.out.println("No device found!!");
      System.out.println("Exiting");
      p.exit();
      return;
    } else {
      System.out.println("Device connected!!");

      // Enable skeleton generation
      this.enableUser();
      this.setMirror(false);
    }
  }
}


class cPersonIdent {
  /* Contains people from all cameras depending on
   		confidence levels */

  public int gpersonId;        //  Global person ID
  public int personId;			   // Local person ID
  public int camId;				     // Camera ID with higher confidence
  public int identified;       // Set to true when person has been identified
  public PVector com;       // Location of centre of mass 
  public float[] featDim = new float[13];	// Feature dimensions with higher confidence
  public float[] featDimMean = new float[12];	// Mean of feature dimensions during identification stage(excluding confidence)
  public PVector[] jointPos = new PVector[15];    // Joint positions of person
  public int[] guesses = new int[21];			// Result of SVM for last 20 tries. Last element is the mode of the first 20 guesses
  public int guessIndex;        // Keeps count of guesses made. Max is 20

  // Constructor
  public cPersonIdent() {
    this.gpersonId = gpersonId;
    this.personId = personId;
    this.camId = camId;
    this.identified = 0;      // 0 = Unidentified, 1 = Identified, 2 = Save User
    this.com = com;
    this.featDim = featDim;
	this.featDimMean = featDimMean;
    this.jointPos = jointPos;
    this.guesses = guesses;
    this.guessIndex = guessIndex;
  }
}


class cSingleCam {
  /* Contains camera local info about users */

  public int personId;			// Local person ID
  public PVector com;			  // Location of centre of mass 
  public float[] featDim = new float[13];  // Feature dimensions with higher confidence
  public PVector[] jointPos = new PVector[15];    // Joint positions of person

  // Constructor
  public cSingleCam(int personId, PVector com, float[] featDim, PVector[] jointPos) {
    this.personId = personId;
    this.com = com;
    this.featDim = featDim;
    this.jointPos = jointPos;
  } 
}

class cPersonMeans {
  /* Contains means of features for people already stored on database, hence global id exists */

  public int gpersonId;                     // Global person ID
  public float[] featMean = new float[12];  // Feature dimensions with higher   

  // Constructor
  public cPersonMeans() {
    this.gpersonId = gpersonId;
    this.featMean = featMean;
  }
}



