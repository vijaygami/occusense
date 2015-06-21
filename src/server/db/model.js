var mongoose = require('mongoose');

// Room Schema
var roomSchema = new mongoose.Schema({
	roomID: Number,
	roomName: String,
	roomDim: {
		length: Number,
		width: Number,
		height: Number
	},
	sensor: [{sensorID: Number, x: Number}]
})

// Appliance Schema
var appSchema = new mongoose.Schema({
	appID: Number,
	appName: String,
	status: {type: String, enum: ['on', 'off','offline']},
	roomID: Number,
	coord: {
		x: Number,
		y: Number,
		z: Number
	}
})

//People Schema
var personSchema = new mongoose.Schema({
	personID: Number,
	personName: String,
	roomID: Number,
	NodeID: String,
	coord:{
		x: Number,
		y: Number,
		z: Number
	},
	identified: Boolean,
	activity: {type: String, enum: ['moving','still','lying']},
	gesList: [{gesName: String, gesTime: { type : Date, default: Date.now }}],
	actList: [{actName: String, actTime: { type : Date, default: Date.now }}],
	joints: {
		head: 			{x: Number, y: Number, z: Number},
		neck: 			{x: Number, y: Number, z: Number},
		leftshoulder: 	{x: Number, y: Number, z: Number},
		rightshoulder: 	{x: Number, y: Number, z: Number},
		lefthip: 		{x: Number, y: Number, z: Number},
		righthip: 		{x: Number, y: Number, z: Number},
		leftknee: 		{x: Number, y: Number, z: Number},
		rightknee: 		{x: Number, y: Number, z: Number},
		torso: 			{x: Number, y: Number, z: Number},
		rightelbow: 	{x: Number, y: Number, z: Number},
		leftelbow: 		{x: Number, y: Number, z: Number},
		righthand: 		{x: Number, y: Number, z: Number},
		lefthand: 		{x: Number, y: Number, z: Number},
		leftfoot: 		{x: Number, y: Number, z: Number},
		rightfoot: 		{x: Number, y: Number, z: Number}
	}
})

var Room = mongoose.model('Room', roomSchema);
var App = mongoose.model('App', appSchema);
var Person = mongoose.model('Person',personSchema);

exports.Room = Room;
exports.App = App;
exports.Person = Person;


//Adding new person documents for testing purposes only
// var p1 = new Person({
// 	personID: 1, 
// 	personName: "Vijay",
// 	roomID: 1,
// 	// coord: {x:100, y:200, z:20},
// 	 identified: false
// 	// activity: 'still',
// 	// joints: {
// 	// 				head: {x: 68.94943, y: 1592.4082, z: -407.7578},
// 	// 				neck: {x: 80.04651, y: 1381.4038, z: -399.68762},
// 	// 				leftshoulder: {x: -73.47821, y: 1373.7241, z: -389.3728},
// 	// 				rightshoulder: { x: 233.57121, y: 1389.0834, z: -410.00256 },
// 	// 				lefthip: {x: 2.5872803, y: 940.5572, z: -376.27478},
// 	// 				righthip: {x: 203.34717, y: 950.5997, z: -389.76318 },
// 	// 				leftknee: {x: -33.697906, y: 507.41913, z: -345.8711},
// 	// 				rightknee: {x:206.73271, y: 519.4461, z: -320.83118 },
// 	// 				torso: {x: 91.506836, y: 1163.4911, z: -391.35327},
// 	// 				rightelbow: {x: 334.95398, y: 1077.9265, z: -381.20947},
// 	// 				leftelbow: {x:-136.69202, y: 1078.6252, z: -337.5221 },
// 	// 				righthand: {x: 352.3958, y: 784.11096, z: -452.5243},
// 	// 				lefthand: {x:-116.85309, y: 768.9044, z: -383.38684 },
// 	// 				leftfoot: {x: -73.46942, y: -7.6688232, z: 106.22778 },
// 	// 				rightfoot: {x: 359.9148, y: 8.82019, z: 164.12549 }
// 	// 		},
// })

// p1.save(function(err){
// 	if (err){
// 		return err;
// 	} else {
// 		console.log('Saved ' + p1.personName);
// 	}

// })

// var p2 = new Person({
// 	personID: 2, 
// 	personName: "PP",
// 	roomID: 1,
// 	coord: {x:100, y:200, z:20},
// 	identified: true,
// 	activity: 'still',
// 	joints: {
// 					head: {x: 68.94943, y: 1592.4082, z: -407.7578},
// 					neck: {x: 80.04651, y: 1381.4038, z: -399.68762},
// 					leftshoulder: {x: -73.47821, y: 1373.7241, z: -389.3728},
// 					rightshoulder: { x: 233.57121, y: 1389.0834, z: -410.00256 },
// 					lefthip: {x: 2.5872803, y: 940.5572, z: -376.27478},
// 					righthip: {x: 203.34717, y: 950.5997, z: -389.76318 },
// 					leftknee: {x: -33.697906, y: 507.41913, z: -345.8711},
// 					rightknee: {x:206.73271, y: 519.4461, z: -320.83118 },
// 					torso: {x: 91.506836, y: 1163.4911, z: -391.35327},
// 					rightelbow: {x: 334.95398, y: 1077.9265, z: -381.20947},
// 					leftelbow: {x:-136.69202, y: 1078.6252, z: -337.5221 },
// 					righthand: {x: 352.3958, y: 784.11096, z: -452.5243},
// 					lefthand: {x:-116.85309, y: 768.9044, z: -383.38684 },
// 					leftfoot: {x: -73.46942, y: -7.6688232, z: 106.22778 },
// 					rightfoot: {x: 359.9148, y: 8.82019, z: 164.12549 }
// 			},
// 	gesture:{occuring: true, ID: 1}
// })

// p2.save(function(err){
// 	if (err){
// 		return err;
// 	} else {
// 		console.log('Saved ' + p2.personName);
// 	}

// })
