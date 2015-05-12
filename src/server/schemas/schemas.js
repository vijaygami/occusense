var mongoose = require('mongoose');

// Coord schema 
/*var coordSchema = new mongoose.Schema({
	x: Number,
	y: Number,
	z: Number
})*/

//Gesture Schema
var gestureSchema = new mongoose.Schema({
	gestureName: String,
	time : { type : Date, default: Date.now }
})

//Activity Schema
var activitySchema = new mongoose.Schema({
	activityName: String,
	time : { type : Date, default: Date.now }
})

// Sensor Schema
var sensorSchema = new mongoose.Schema({
	sensorID: Number,
	x: Number,
	y: Number,
	z: Number
})

// Room Schema
var roomSchema = new mongoose.Schema({
	roomID: Number,
	roomName: String,
	roomDim: {
		length: Number,
		width: Number,
		height: Number
	},
	sensors: [sensorSchema]
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
	//bodypartDim: [Number],
	roomID: Number,
	coord:{
		x: Number,
		y: Number,
		z: Number,
	},
	activity: {type: String, enum: ['moving','still','lying']},
})

//Gesture History
var gesHistorySchema = new mongoose.Schema({
	personID: Number,
	personName: String,
	gesList: [gestureSchema],
})

//Activity History
var actHistorySchema = new mongoose.Schema({
	personID: Number,
	personName: String,
	actList: [activitySchema],
})

var Room = mongoose.model('Room', roomSchema);
var App = mongoose.model('App', appSchema);
var Person = mongoose.model('Person',personSchema);
var GesHistory = mongoose.model('GesHistory',gesHistorySchema);
var ActHistory = mongoose.model('ActHistory',actHistorySchema);

exports.Room = Room;
exports.App = App;
exports.Person = Person;
exports.GesHistory = GesHistory;
exports.ActHistory = ActHistory;