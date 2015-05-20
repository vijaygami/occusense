import SimpleOpenNI.PVector;

class cPersonIdent {
	/* Contains people from all cameras depending on
		confidence levels */

  	public int personId;			// Local person ID
  	public int camId;				// Camera ID with higher confidence
	public boolean identified;		// Set to true when person has been identified
	public float confidence;		// Minimum confidence of the  
	public float[7] featDim;		// Feature dimensions with higher confidence
	public int[10] guesses;			// Result of SVM for last 10 tries	
	
	// Constructor
	public cPersonIdent(){
	    this.personId = personId;
	  	this.camId = camId;
		this.identified = identified;
		this.confidence = confidence;
		this.featDim = featDim;
		this.guesses = guesses;
  	}
}


class cPersonInfo {
	/* Contains people's details, location (COM) and joint positions */

  	public int gpersonId;			// Global person ID
  	public int personId;			// Local person ID
  	public int camId;				// Camera ID with higher confidence
	public String name				// Name of person as trained by SVM
	public PVector com;				// Location of centre of mass 
	public float[15] jointPos;		// Joint positions of person
	
	// Constructor
	public cPersonInfo(){
	    this.gpersonId = gpersonId;
	    this.personId = personId;
	  	this.camId = camId;
	  	this.name = name;
		this.com = com;
		this.jointPos = jointPos;
  	}
}


class cSingleCam {
	/* Contains camera local info */

  	public int personId;			// Local person ID
	public PVector com;				// Location of centre of mass 
	public float confidence;		// Minimum confidence of the  
	
	// Constructor
	public cSingleCam(){
	    this.personId = personId;
		this.com = com;
		this.confidence = confidence;
  	}
}





