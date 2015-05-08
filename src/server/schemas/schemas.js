var mongoose = require('mongoose');

// Coord schema 
var coordSchema = new mongoose.Schema({
	x: Number,
	y: Number,
	z: Number
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

var Room = mongoose.model('Room', roomSchema);
var App = mongoose.model('App', appSchema);

exports.Room = Room;
exports.App = App;