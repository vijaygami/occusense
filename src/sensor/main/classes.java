import SimpleOpenNI.*;
import processing.core.*;

class cPersonIdent {
  /* Contains people from all cameras depending on
   		confidence levels */

  public int personId;			   // Local person ID
  public int camId;				     // Camera ID with higher confidence
  public boolean identified;   // Set to true when person has been identified
  public float confidence;		 // Minimum confidence 
  public float[] featDim = new float[8];	// Feature dimensions with higher confidence
  public int[] guesses = new int[10];			// Result of SVM for last 10 tries	

  // Constructor
  //public cPersonIdent(int personId, int camId, boolean identified, float confidence, float[] featDim, int[] guesses) {
  public cPersonIdent() {
    this.personId = personId;
    this.camId = camId;
    this.identified = false;
    this.featDim = featDim;
    this.guesses = guesses;
  }
}


class cPersonInfo {
  /* Contains people's details, location (COM) and joint positions */

  public int gpersonId;			// Global person ID
  public int personId;			// Local person ID
  public int camId;				  // Camera ID with higher confidence
  public String name;				// Name of person as trained by SVM
  public PVector com;				// Location of centre of mass 
  public float[] jointPos = new float[15];		// Joint positions of person

  // Constructor
  public cPersonInfo(int gpersonId, int personId, int camId, String name, PVector com, float[] jointPos) {
    this.gpersonId = gpersonId;
    this.personId = personId;
    this.camId = camId;
    this.name = name;
    this.com = com;
    this.jointPos = jointPos;
  }
}


class cSingleCam {
  /* Contains camera local info about users */

  public int personId;			// Local person ID
  public PVector com;			  // Location of centre of mass 
  public float[] featDim = new float[8];  // Feature dimensions with higher confidence

  // Constructor
  public cSingleCam(int personId, PVector com, float[] featDim) {
    this.personId = personId;
    this.com = com;
    this.featDim = featDim;
  } 
}




