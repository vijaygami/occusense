(function(){
	//initialise main app. include angoose client
	var m_app=angular.module('m_app', []);	

	//service to include scope in socket.on and .emit
	/*m_app.factory('socket', function($rootScope){
		var socket = io.connect('http://localhost:3000/webApp');
		
		return {
		    on: function (eventName, callback) {
		        socket.on(eventName, function () {  
		            var args = arguments;
		            $rootScope.$apply(function () {
		                callback.apply(socket, args);
		            });
		        });
		    },
		    emit: function (eventName, data, callback) {
		        socket.emit(eventName, data, function () {
		            var args = arguments;
		            $rootScope.$apply(function () {
		                if (callback) {
		                    callback.apply(socket, args);
		                }
		            });
		        })
		    }
		};
	});*/
	
	//controller for list of data
	m_app.controller('ListController', function($scope, $interval){ //include scope dependency
		//self.persons = persons.list;

		//set up socket 
		var socket = io.connect('http://localhost:3000/webApp');

		//list of pre determined colours for colour array
		$scope.colours = [
					{colour: "#000000", used: true, ID: 0},
					{colour: "#9be466", used: false, ID: 0},
					{colour: "#0092ff", used: false, ID: 0},
					{colour: "#bca7d2", used: false, ID: 0},
					{colour: "yellow", used: false, ID: 0},
					{colour: "orange", used: false, ID: 0}
					];

		//array for activity log. it will be pushed to from the gesture indicator controller and the mapCanvas directives controller
		$scope.log = [];

		//list of gestures available
		$scope.gestures = gesAvail;

		//list of gestures already performed (gesutre ID, user ID and time) of live gestures occured
		$scope.currGes =[];

		//constantly update scope
        //$interval([$scope.$apply()], [500]);

        //request data on interval
        $interval(function(){
			socket.emit('request:person');
			
	   	}, [150]);

        //update people when the data is recieved
	   	socket.on('update:person', function(data){
	        console.log("received data from server!");
	        //console.log(data);
		    //people is an array of all people objects with their data
		    $scope.people = data;
	    });

	    //socket to push to currGes (the live gesture list) each time a gesture is performed
	    socket.on('live_ges', function(gID, uID){
	    	console.log("gesture performed");
	    	$scope.currGes.push({gesID: gID, userID: uID, timestamp: Date.now});

	    });
	   	
	});
	
	//profile controller. functions to call socket to change name etc
	m_app.controller('ProfileController', function(){
		//variable to take new name
		this.newName = "";

		this.newColour = "";

		//variable to store selected user
		this.selectedID="";

		//when we click view activities on a user, set selected attributes for using in the timeline creation directive
		//ges_data takes the gesture history of the user in format [{name, time}, ..., ...]
		this.load_timeline=function(userName, ges_data, act_data, ges){
			
			//first set the username to display in the modal
			this.selectedName=userName;

			//set dom element
			var dom_element= "timeline_display";

			// DOM element where the Timeline will be attached
			var container = document.getElementById(dom_element);

			//be sure to clear the display every time we re load
			while (container.hasChildNodes()) {
			    container.removeChild(container.lastChild);
			}

			//array to store timeline data
			var item = [];

			//variable to show split in item between activities and gestuers
			var split;

			//store each activity to item
			for(var i=0; i<act_data.length; i++){
				//case for if the element isnt null, and the next element is defined
				if(act_data[i]!=null && typeof act_data[i+1] != "undefined"){
					
					//create timeline bar object. end date determine by next element 
					item.push({id: i, content: act_data[i].actName, 
						start: new Date(
							act_data[i].actTime.substring(0,4), 
							act_data[i].actTime.substring(5,7)-1,
							act_data[i].actTime.substring(8,10),
							+act_data[i].actTime.substring(11,13)+1,							
							act_data[i].actTime.substring(14,16),
							act_data[i].actTime.substring(17,19)),
						end: new Date(
							act_data[i+1].actTime.substring(0,4), 
							act_data[i+1].actTime.substring(5,7)-1,
							act_data[i+1].actTime.substring(8,10),
							+act_data[i+1].actTime.substring(11,13)+1,
							act_data[i+1].actTime.substring(14,16),
							act_data[i+1].actTime.substring(17,19))
						}						
					);
					
				}

				//case for if the next element is not defined (this is the last activity in the database for this person)
				else if(act_data[i]!=null && typeof act_data[i+1] == "undefined"){
					//set the end date of the timeline object to the current time and date
					item.push({id: i, content: act_data[i].actName, 
						start: new Date(
							act_data[i].actTime.substring(0,4), 
							act_data[i].actTime.substring(5,7)-1,
							act_data[i].actTime.substring(8,10),
							+act_data[i].actTime.substring(11,13)+1,
							act_data[i].actTime.substring(14,16),
							act_data[i].actTime.substring(17,19)),
						end: new Date			
						}						
					);
				}
				//keep setting split to i
				split=i;			
			}
			split++;
			
			//store each gesture to item. use split to continue the item array
			for(var i=split; i-split<ges_data.length; i++){

				//case to make sure the item is not null
				if(ges_data[i-split]!=null){
					//set name of gesture to a local variable cont
					var cont;
					for(var k=0; k<ges.length;k++){
						if(ges[k].ID == ges_data[i-split].gesID){
							cont = ges[k].name;
						}
					}

					//push to timeline object. no end time
					item.push({id: i, content: cont, 
						start: new Date(
							ges_data[i-split].gesTime.substring(0,4), 
							ges_data[i-split].gesTime.substring(5,7)-1,
							ges_data[i-split].gesTime.substring(8,10),
							+ges_data[i-split].gesTime.substring(11,13)+1,
							ges_data[i-split].gesTime.substring(14,16),
							ges_data[i-split].gesTime.substring(17,19)),
						style: "background-color: #fe9a76; border-color: black;"
						}
						
					);
				}

				
			}
			
			//create dataset for timeline
			var items = new vis.DataSet(item);

			// Create a DataSet (allows two way data-binding).
			/*var itemtest = new vis.DataSet([
			  {id: 1, content: 'Lights On', start: new Date(2015,05,17, 15), style: "background-color: #fe9a76; border-color: black;"},
			  {id: 2, content: 'Falling', start: new Date(2015,05,17, 15, 05, 50), style: "background-color: #fe9a76; border-color: black;"},
			  {id: 3, content: 'Sitting', start: new Date(2015,05,17, 14, 58), end: new Date(2015,05,17, 15, 03),},
			  {id: 5, content: 'Walking', start: new Date(2015,05,17, 15, 03), end: new Date(2015, 05, 17, 15, 05)},
			]);
*/
			//console.log(itemtest[0].start);

			// Configuration for the Timeline
			//eventually ensure it only displays daily data

			//options for timeline
			var options = {};


			// Create a Timeline
			var timeline = new vis.Timeline(container, items, options);
		};
		
		//when function called, it emits new name and user ID through a socket to be changed in database
		this.namechange = function(newName, currentName, userID, person){

			//emit socket only if the name has actually changed
			if(newName != currentName){
				console.log(newName + " " + userID);

				socket.emit('userName_change', userID,  newName);

			}
			
			//person.personName = newName;


			//reset newName
			this.newName = "";
		};

		//sets colour of each person on profile page. uses element ID from html doc to find it
		this.findcol = function(userID, col_array){
			for(var i=0; i<col_array.length;i++){
				if(userID == col_array[i].ID){
					document.getElementById("circle"+userID).setAttribute("fill", col_array[i].colour);
				}
			}
		};

		//set this.newColour to users current colour when we choose to edit a user
		this.findlocalcol = function(userID, col_array){
			for(var i=0; i<col_array.length;i++){
				if(userID == col_array[i].ID){
					this.newColour = col_array[i].colour;
				}
			}
		};

		//change the colour of each person on profile page
		this.changecol = function(userID, col_array){

			for(var i=0; i<col_array.length;i++){

				if(userID == col_array[i].ID){

					col_array[i].colour = this.newColour;

				}
			}
		};

	});

	//controller for the different tabs
	m_app.controller('PanelController', function(){
		//default tab is 1
		this.tab = 1;

		//make panel.selectTab call a function that sets tab to setTab when it is clicked
		this.selectTab = function(setTab){ 
			this.tab = setTab;
		};

		//make panel.isSelected call a function that checks if that tab is selected. 
		this.isSelected = function(checkTab){
			return this.tab===checkTab; //this returns true or false
		};
	});


	//controller to select the person whos joints/info we want to display
	m_app.controller('JointController', function(){
		//ID of the person selected. initially -1
		this.selected = -1;

	});

	//controller for animating real time live gestures
	m_app.controller('LivegesController', function(){
		
		this.tempcol = "";

		//function to delete a live gesture from currGes when it is clicked/dismissed on gui
		this.dismiss = function(i, array){
			//use the index i to splice the array
			array.splice(i, 1);
		};

		//function to find user name from user ID
		this.findname = function(userID, people){

			for(var i=0; i<people.length; i++){
				if(userID == people[i].personID){
					return people[i].personName;
				}
			}
		};

		//funciton to find colour from userID
		this.findcol = function(userID, col_array){

			for(var i=0; i<col_array.length; i++){
				if(userID == col_array[i].ID){
					this.tempcol = col_array[i].colour;
				}
			}		
		}

	});

	//controller for training gestures
	m_app.controller('GestureController', function($interval, $timeout, $scope){
		var timers;
		//the ID of the person to perform the gesture
		this.operator = 0;

		//the ID of the gesture to change
		this.gestureID = 0;

		//index of the person that is training it
		this.index = -1;

		//name of person training
		this.name ="";

		$scope.timer_array = ["Initialising...", "3", "2", "1", "Train!", "3", "2", "1"];

		//numbers variable for timer
		$scope.timer_num = " ";

		//commands/info for timer
		$scope.timer_holder=" ";

		//boolean to display saved confirmation
		$scope.saved_bool = false;

		this.test=0;

		this.request = function(persons){
			//test the function works
			this.test = this.operator  + this.gestureID;

			//set person ID of training
			this.operator=persons[this.index].personID;

			//set name of person training
			this.name = persons[this.index].personName;

			//ensure saved is set to false
			$scope.saved_bool=false;

			//ensure the timer variables are reset each time we click (in case we abort a training)
			$scope.timer_holder="";
			$scope.timer_num="";

			//INSERT SOCKET COMMS TO SERVER HERE
			socket.emit("ges_change", this.gestureID, this.operator);
			/*socket.on('response', function(msg){
				console.log(msg);
			});*/
		};

		this.timer = function(){
			
			//queue the timer indicators
			timers = $timeout(function(){$scope.timer_holder="Initialising...";}, 1000);
			timers = $timeout(function(){$scope.timer_num="3";}, 2000);
			timers = $timeout(function(){$scope.timer_num="2";}, 3000);
			timers = $timeout(function(){$scope.timer_num="1";}, 4000);
			timers = $timeout(function(){$scope.timer_num=" ";}, 5000);
			timers = $timeout(function(){$scope.timer_holder="Begin Training!";}, 5000);
			timers = $timeout(function(){$scope.timer_num="3";}, 6000);
			timers = $timeout(function(){$scope.timer_num="2";}, 7000);
			timers = $timeout(function(){$scope.timer_num="1";}, 8000);
			timers = $timeout(function(){$scope.timer_num="0";}, 9000);
			timers = $timeout(function(){$scope.timer_num=" ";}, 10000);
			timers = $timeout(function(){$scope.timer_holder="Saving...";}, 10000);
			timers = $timeout(function(){$scope.saved_bool="true";}, 13000);
			timers = $timeout(function(){$scope.saved_bool="false";}, 16000);
		};

		//function to cancel timeouts and reset variables if we cancel the training/start a new one
		this.cancel = function(){

		};

	});

	m_app.controller('TrainingController', function(){

	});

	//directive to indicate when a gesture is occuring, and who is doing it
	m_app.directive('gestureChanger', function(){
		return{


		}


	});

	//directive to load the timeline per person
	/*m_app.directive('activityTimeline', function(){
		return{
			restrict: 'AEC',
			scope: {'personActivities': '=', 'uid': '=', 'peopleInfo': '='}, //pass the gesList and the div element ID where we want the timeline to go
			link: function(scope, element, attrs){

				//set dom element
				var dom_element= "timeline_display";

				// DOM element where the Timeline will be attached
				var container = document.getElementById(dom_element);

				var test=scope.uid;
				console.log(test);

				// Create a DataSet (allows two way data-binding)
				var items = new vis.DataSet([
				  {id: 1, content: 'item 1'+test, start: '2013-04-20'},
				  {id: 2, content: 'item 2', start: '2013-04-14'},
				  {id: 3, content: 'item 3', start: '2013-04-18'},
				  {id: 4, content: 'item 4', start: '2013-04-16', end: '2013-04-19'},
				  {id: 5, content: 'item 5', start: '2013-04-25'},
				  {id: 6, content: 'item 6', start: '2013-04-27'}
				]);

				// Configuration for the Timeline
				var options = {};


				// Create a Timeline
				var timeline = new vis.Timeline(container, items, options);

			}
		}

	});*/

	//directive to set up and draw the joint map of a selectable person
	m_app.directive('jointCanvas', function(){
		return{
			restrict: 'AEC',
			scope: {'index': '=selected', 'peopleInfo': '=peoples', 'col_array': '=cols', 'element': '='}, //person ID is selected when we choose a person. skeleton is also passed into scope. scope.skeleton.head.x etc. colour array too
			link: function(scope, element, attrs){
				
				//set height and width of frames
				var width=420;
				var height = 300;

				//scale and offset of skeleton
				var scale = 70;
				var offset = 10;

				//create line variable globally
				var line;

				//index variable to access the correct persons data
				var index = 0;

				//create scene, camera and renderer. set sizes. append it to the panel in index.html, referred to by its ID. globals
				var scene = new THREE.Scene();
				var camera = new THREE.PerspectiveCamera( 75, width/ height, 0.1, 1000 );
				var renderer = new THREE.WebGLRenderer();
				renderer.setSize( width, height );
				document.getElementById(scope.element).appendChild( renderer.domElement );

				//call function to form the skeleton image. ONLY if the people data is defined
				//(prevents trying to access data before its loaded on start up)
				/*if(scope.index!=-1){
					console.log("passed");
					set_joints();
				}*/
				//function to create skeleton 
				function set_joints(){

					//find colour from the colour array, corresponding to the current ID selected
					var colour = find_colour();

					//set material colour and other properties
					var material = new THREE.LineBasicMaterial({
						color: colour,	//colour of lines
						linewidth: 3	//width of lines
						 
					});

					//create geometry to store the vertices of the skeleton.
					var geometry = new THREE.Geometry();

					//only add vertices if the selected ID is not 0
					if(scope.index >= 0){

						//if the selected ID is not zero, it means we want to display someones joints
						//call this function to find the correct index in peopleInfo that corresponds with the selected ID
						//find_index();
						index = scope.index ;

						//create all the vertices that the lines will be made from
						//function norm(a,b) takes the joint a, dimension b and returns the normalised co-ordinate
						geometry.vertices.push(
							new THREE.Vector3( norm("head", "x"), norm("head", "y"), norm("head", "z")),
							new THREE.Vector3( norm("neck", "x"), norm("neck", "y"), norm("neck", "z") ),

							new THREE.Vector3( norm("neck", "x"), norm("neck", "y"), norm("neck", "z") ),
							new THREE.Vector3( norm("rightshoulder", "x"), norm("rightshoulder", "y"), norm("rightshoulder", "z") ),

							new THREE.Vector3( norm("neck", "x"), norm("neck", "y"), norm("neck", "z") ),
							new THREE.Vector3( norm("leftshoulder", "x"), norm("leftshoulder", "y"), norm("leftshoulder", "z") ),

							new THREE.Vector3( norm("leftshoulder", "x"), norm("leftshoulder", "y"), norm("leftshoulder", "z") ),
							new THREE.Vector3( norm("leftelbow", "x"), norm("leftelbow", "y"), norm("leftelbow", "z") ),

							new THREE.Vector3( norm("leftelbow", "x"), norm("leftelbow", "y"), norm("leftelbow", "z") ),
							new THREE.Vector3( norm("lefthand", "x"), norm("lefthand", "y"), norm("lefthand", "z") ),

							new THREE.Vector3( norm("rightshoulder", "x"), norm("rightshoulder", "y"), norm("rightshoulder", "z") ),
							new THREE.Vector3( norm("rightelbow", "x"), norm("rightelbow", "y"), norm("rightelbow", "z") ),

							new THREE.Vector3( norm("rightelbow", "x"), norm("rightelbow", "y"), norm("rightelbow", "z") ),
							new THREE.Vector3( norm("righthand", "x"), norm("righthand", "y"), norm("righthand", "z") ),

							new THREE.Vector3( norm("leftshoulder", "x"), norm("leftshoulder", "y"), norm("leftshoulder", "z") ),
							new THREE.Vector3( 0, 0, 0 ),

							new THREE.Vector3( norm("rightshoulder", "x"), norm("rightshoulder", "y"), norm("rightshoulder", "z") ),
							new THREE.Vector3( 0, 0, 0 ),

							new THREE.Vector3( 0, 0, 0 ),
							new THREE.Vector3( norm("lefthip", "x"), norm("lefthip", "y"), norm("lefthip", "z") ),

							new THREE.Vector3( 0, 0, 0 ),
							new THREE.Vector3( norm("righthip", "x"), norm("righthip", "y"), norm("righthip", "z") ),

							new THREE.Vector3( norm("righthip", "x"), norm("righthip", "y"), norm("righthip", "z") ),
							new THREE.Vector3( norm("rightknee", "x"), norm("rightknee", "y"), norm("rightknee", "z") ),

							new THREE.Vector3( norm("lefthip", "x"), norm("lefthip", "y"), norm("lefthip", "z") ),
							new THREE.Vector3( norm("leftknee", "x"), norm("leftknee", "y"), norm("leftknee", "z") ),

							new THREE.Vector3( norm("leftknee", "x"), norm("leftknee", "y"), norm("leftknee", "z") ),
							new THREE.Vector3( norm("leftfoot", "x"), norm("leftfoot", "y"), norm("leftfoot", "z") ),

							new THREE.Vector3( norm("rightknee", "x"), norm("rightknee", "y"), norm("rightknee", "z") ),
							new THREE.Vector3( norm("rightfoot", "x"), norm("rightfoot", "y"), norm("rightfoot", "z") )


						);
						
						//remove any existing image from the scene
						scene.remove(line);

						//re-create line variable and add to scene
						line = new THREE.Line( geometry, material, THREE.LinePieces);
						scene.add( line );

						//set camera position
						camera.position.z=20;
						camera.position.y=0;
						camera.position.x=0;
					}

					//if the ID passed is 0, we only want to empty the scene
					else if(scope.index < 0){scene.remove(line);}


				};

				//function continuously calls to render the scene
				var render = function(){
					//continuously re calculate the joints if a user is selected and the people info is defined
					if(scope.index!=-1){
						if(typeof scope.peopleInfo[index] != "undefined"){
							set_joints();
						}
						
					}

					if(scope.index < 0){scene.remove(line);}



					//render
					requestAnimationFrame( render );
					renderer.render( scene, camera );
				
				};
				render();
				

				//function to normalise and scale the vertices
				function norm(bodypart, direction){
					//return (joints[scope.ID][bodypart][direction] - joints[scope.ID]["torso"][direction]) / scale;

					//index chooses the correct person in peopleInfo to display. 
					return (scope.peopleInfo[index]["joints"][bodypart][direction] - scope.peopleInfo[index]["joints"]["torso"][direction]) / scale;
				};

				//function to find the index number corresponding to the correct person in peopleInfo, from the ID passed
				/*function find_index(){					
					for(var i=0; i<scope.peopleInfo.length; i++){
						if(scope.peopleInfo[i].personID == scope.ID){index=i; break;}
					}
				};*/

				//finds the correct colour corresponding to the person we are displaying from the ID value
				function find_colour(){

					var correct_colour;

					
					for(var i=0; i<scope.col_array.length;i++){
						
						if(scope.col_array[i].ID == scope.peopleInfo[index].personID){correct_colour = scope.col_array[i].colour; break;}
						
					}

					return correct_colour;
					
				}

			}
		};

	});

	//directive to set up and draw map canvas
	m_app.directive('mapCanvas', function(){
		return {
			restrict: 'AEC',
			template: '<canvas id="map" width="725" height="550"></canvas>',
			scope: {'peopleInfo': '=info', 'col_array': '=cols'}, //should provide 2 way binding for people data, activity log colour array
			link: function(scope, element, attrs){
				if(scope.stage){
				}
				else{


					//create stage if not already created
					var stage = new createjs.Stage("map"); //create a stage
					
					//create text object for displaying person info on canvas
					var display_info=new createjs.Text("Click User to display Information", "16px monospace", "#000");

					//ticker to continuously update map
					createjs.Ticker.addEventListener("tick", tick);

					//create array to store shape objects for each person with attributes .name .id .color etc
					var p_array = [];

					//initialise map once
					map_init();

					//test object for coordinate scaling
					/*var test = new createjs.Shape();
					test.graphics.beginFill("red").drawCircle(0, 0, 15);
					test.x=725;
					test.y=400;
					stage.addChild(test);
					stage.update();*/
					
					function tick(){

						//add any new users to the canvas
						user_add();

						//update all current user positions or remove/add existing users to canvas
						user_update();
					}					
				}
				



				//function to update existing users coordinates, remove any unidentified users from the canvas, add existing reidentified users to canvas
				function user_update(){

					//update every object in p_array
					for(var i=0; i<p_array.length ; i++){

						//variable to handle the case where p_array object is no longer in the database
						var found = false;

						//change the colour if needed
						changed_colour(p_array, i, p_array[i].id);

						//check if name has changed
						changed_name(p_array[i].id, p_array[i].name, p_array, i);

						
						//compare current objects to database peopleInfo
						angular.forEach(scope.peopleInfo, function(value, key){

							//if the person is identified in p_array and is still identified in peopleInfo, simply update the coordinates
							if(value.personID == p_array[i].id && value.identified && p_array[i].identified){
								p_array[i].x = value.coord.x/20;
								p_array[i].y = value.coord.y/20;
								p_array[i].alpha = 1;
								// value.coord.x=value.coord.x+1; /*TEST ANIMATION*/
								// if (value.coord.x > stage.canvas.width) { value.coord.x = 0; }
								found=true;
							}

							//if the person is identified in the database peopleInfo, but not identified in p_array, add to canvas and update coordinates
							if(value.persionID == p_array[i].id && value.identified && !p_array[i].identified){
								console.log("called");
								p_array[i].x=value.coord.x;
								p_array[i].y=value.coord.y;
								
								//stage.addChild(p_array[i]);

								found=true;
							}

							//if the person is in p_array and is now unidentified, keep their data and grey them on canvas
							if(value.personID == p_array[i].id && !value.identified){

								//update the objects status and remove it from the stage
								p_array[i].identified = false;
								p_array[i].alpha = 0.35;
								//stage.removeChild(p_array[i]);
								found=true;
							}

							
						});
						
						
						if(!found){

							//p_array[i].identified = false;
							p_array[i].alpha = 0.35;
							//stage.removeChild(p_array[i]);
						}
					}

					//update stage
					stage.update();
				};


				//function to add any newly identified users
				function user_add(){
					var string = [];
					//for each person in peopleInfo...
					angular.forEach(scope.peopleInfo, function(value, key){
						//console.log("adding user");
						//initially set exists to false
						var exists = false;

						
						for(var i=0;i<p_array.length;i++){
							//if the element in peopleInfo is in p_array, set exists to true
							if(p_array[i].id == value.personID && value.identified){exists=true;}
						}

						//if the element in peopleInfo is not in p_array but is now newly identified, make a circle of it
						if(value.identified && !exists){

							//create container
							var container = new createjs.Container();

							//create shape object
							var circle = new createjs.Shape();

							//create text label object
							var label = new createjs.Text(value.personName);

							//call function to find next available colour and return it
							var avail_colour=find_colour(key);

							//draw circle and assign available colour found
							circle.graphics.beginFill(avail_colour).drawCircle(0, 0, 25);
							//circle.color=avail_colour;

							//set object attributes. name color ID co-ordinates identified or not
							/*circle.name =value.personName;
							circle.id = value.personID;
							circle.color = avail_colour;
							circle.x = value.coord.x; 
							circle.y = value.coord.y;
							circle.identified = value.identified;*/

							//set text label attributes
							//label = value.personName;
							label.x =0;
							label.y=0;
							label.textAlign = "center";
							label.textBaseline = "middle";
							console.log(label.text);

							//add circle to container
							container.addChild(circle, label);

							//set container attributes
							container.name =value.personName;
							container.id = value.personID;
							container.color = avail_colour;
							container.x = value.coord.x; 
							container.y = value.coord.y;
							// container.identified = value.identified;
							container.identified = true;
							console.log(container.color);

							//push the container and label into p_array
							p_array.push(container);
						
							//add container to stage and update
							stage.addChild(container); 
							stage.update();	

							//set mouse event handler for mouse click to display the info (doesnt live update yet)
							container.on("mouseover", function(){
							display_info.text = "ID: " +value.personID+"\nName: "+value.personName+"\nActivity: "+value.activity+"\nx: "+value.coord.x;
							
							//stage.addChild(display_info); 
							//stage.update();
							});
						}
					});
					
					
				};
				

				//mouse off handler to remove text info from person circles
				function handleMouseOff(){
					display_info.text="Click User to display Information";
					stage.update();
				}

				function map_init() {
						//enable mouse over animations
				    	stage.enableMouseOver();

				    	//add person info text as stage child
				    	display_info.x = 30;
				    	display_info.y = 500;
				    	stage.addChild(display_info);


				    	var floor = new createjs.Bitmap("/images/floorplan.png"); //floor play

						//Add the floor plan
						floor.image.onload = function(){
							var scale = stage.canvas.width/floor.image.width;
							floor.scaleX = floor.scaleY = scale;
							stage.update();

						};
					
						//set mouse off handler
						floor.on("mousedown", handleMouseOff);

						stage.addChild(floor); //add floorplan to stage
						stage.update();
				};

				//find the next unused colour
				function find_colour(current_person){
					

					//find the next unused colour
					for(var j=0;j<scope.col_array.length;j++){
						//if the colour is not being used, quit loop. its index is j
						if(!scope.col_array[j].used){
							//update col_array attributes. use the current_person argument to set whos using that colour	
							scope.col_array[j].ID = scope.peopleInfo[current_person].personID;
							scope.col_array[j].used = true;
							//return the colour
							return scope.col_array[j].colour;
							

						}
					}

					//if the loop exits, a colour has not been found. return black
					return "black";
				};

				//detect if the user has changed their preferred colour
				function changed_colour(containers, index, userID){

					for(var i=0;i<scope.col_array.length; i++){
						if(userID == scope.col_array[i].ID){
							//if the colour has changed
							if(containers[index].color != scope.col_array[i].colour){
								console.log("colour changed");
								//remove everything from container
								containers[index].removeAllChildren();
								//delete from p_array
								containers.splice(index, 1);
								//set to unused NOTE: this relies on a new user not being added at the same time as changing a colour (bad bug but oh well)
								scope.col_array[i].used = false;


							}
						}
					}
				}

				//detect if the user has changed their name
				function changed_name(userID, userName, containers, index){

					for(var i=0;i<scope.peopleInfo.length; i++){
						if(userID == scope.peopleInfo[i].personID){
							//if the name has changed
							if(userName !== scope.peopleInfo[i].personName){

								containers[index].getChildAt(1).text = scope.peopleInfo[i].personName;
								/*for(var j=0;j<scope.col_array.length;j++){
									if(scope.col_array[j].ID == userID){
										scope.col_Array[j].used = false;
									}
								}
								//remove everything from container
								containers[index].removeAllChildren();
								//delete from p_array
								containers.splice(index, 1);*/

								
							}
						}
					}

					
				}
			}
		};


	});

	

	//list of available gestures
	var gesAvail = [{name: "Lights", ID: 0, performed: "is gesturing to switch the lights", description: "A gesture to turn the lights on or off", icon: "glyphicon glyphicon-flash"},
					{name: "Fan", ID: 1, performed: "is gesturing to switch the fan", description: "A gesture to turn the fan on or off", icon: "glyphicon glyphicon-screenshot"},
					{name: "Curtains", ID: 2, performed: "is gesturing to draw the curtains", description: "A gesture to draw the curtains", icon: "glyphicon glyphicon-picture"},
					{name: "Channel", ID: 3, performed: "is changing the TV channel", description: "A gesture to change the TV channel", icon: "glyphicon glyphicon-blackboard"},
					{name: "Falling", ID: 4, performed: "has fallen, call emergency services!", description: "A warning to indicate when someone has fallen", icon: "glyphicon glyphicon-plus-sign"},
					];

	//dummy number of people identified
	var n_people = 3;
	

})();