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
	//bodypartDim: [Number],
	roomID: Number,
	coord:{
		x: Number,
		y: Number,
		z: Number
	},
	identified: Boolean,
	activity: {type: String, enum: ['moving','still','lying']},
	gesList: [{gesName: String, gesTime: { type : Date, default: Date.now }}],
	actList: [{actName: String, actTime: { type : Date, default: Date.now }}]
})

var Room = mongoose.model('Room', roomSchema);
var App = mongoose.model('App', appSchema);
var Person = mongoose.model('Person',personSchema);

exports.Room = Room;
exports.App = App;
exports.Person = Person;

//Adding new person documents for testing purposes only
/*var p1 = new Person({
	personID: 10, 
	personName: "Samuel Jackson",
	roomID: 1,
	coord: {x:21, y:56, z:2},
	identified: true,
	activity: 'moving'
})

p1.save(function(err){
	if (err){
		return err;
	} else {
		console.log('Saved ' + p1.personName);
	}

})
*/
