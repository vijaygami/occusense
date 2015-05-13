// Module dependancies
var mongoose = require('mongoose');
var dbName = 'depthdb';

// Create models from schemas
require('./model');

// Connect to mongodb 
mongoose.connect('mongodb://localhost/' + dbName);

var db = mongoose.connection;
db.once('open', function(){
	console.log('Successfully connected to ' + dbName);
});

// Error handler
db.on('error', console.error.bind(console, 'Connection error:'));

// Close the Mongoose connection when app closes 
process.on('SIGINT', function() {  
  mongoose.connection.close(function () { 
    console.log('Mongoose connection disconnected through app termination!'); 
    process.exit(0); 
  }); 
}); 