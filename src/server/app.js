#!/usr/bin/env node

/**
 * Module dependencies.
 */
var debug = require('debug')('DepthSense:server');
var express = require('express');
var http = require('http');
var path = require('path');
var favicon = require('serve-favicon');
var logger = require('morgan');
var cookieParser = require('cookie-parser');
var bodyParser = require('body-parser');
var mongoose = require('mongoose');
require('./db/db');
var personData = require('./db/person');
var OplogWatcher = require('mongo-oplog-watcher');

// Create app instance
var app = express();
var server = http.createServer(app);

// Attach Socket.IO to server
var ioServer = require('socket.io')(server);

//Get port from environment and store in Express
var port = normalizePort(process.env.PORT || '3000');
app.set('port', port);

//Listen on provided port, on all network interfaces
server.listen(port);
server.on('error', onError);
server.on('listening', onListening);

// view engine setup to use html
app.set('views', path.join(__dirname, 'views'));
app.engine('html', require('ejs').renderFile);
app.set('view engine', 'html');

// uncomment after placing your favicon in /public
//app.use(favicon(__dirname + '/public/favicon.ico'));
app.use(logger('dev'));
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: false }));
app.use(cookieParser());
app.use(express.static(path.join(__dirname, 'public')));

// Routing
app.get('/', function(req, res){
	res.sendfile(__dirname + '/views/index.html');
});


// catch 404 and forward to error handler
app.use(function(req, res, next) {
  var err = new Error('Not Found');
  err.status = 404;
  next(err);
});


// error handlers

// development error handler
// will print stacktrace
if (app.get('env') === 'development') {
  app.use(function(err, req, res, next) {
	res.status(err.status || 500);
	res.render('error', {
	  message: err.message,
	  error: err
	});
  });
}

// production error handler
// no stacktraces leaked to user
app.use(function(err, req, res, next) {
  res.status(err.status || 500);
  res.render('error', {
	message: err.message,
	error: {}
  });
});

/**
 * Normalize a port into a number, string, or false.
 */
function normalizePort(val) {
  var port = parseInt(val, 10);

  if (isNaN(port)) {
	// named pipe
	return val;
  }

  if (port >= 0) {
	// port number
	return port;
  }

  return false;
}

/**
 * Event listener for HTTP server "error" event.
 */
function onError(error) {
  if (error.syscall !== 'listen') {
	throw error;
  }

  var bind = typeof port === 'string'
	? 'Pipe ' + port
	: 'Port ' + port;

  // handle specific listen errors with friendly messages
  switch (error.code) {
	case 'EACCES':
	  console.error(bind + ' requires elevated privileges');
	  process.exit(1);
	  break;
	case 'EADDRINUSE':
	  console.error(bind + ' is already in use');
	  process.exit(1);
	  break;
	default:
	  throw error;
  }
}

/**
 * Event listener for HTTP server "listening" event.
 */
function onListening() {
  var addr = server.address();
  var bind = typeof addr === 'string'
	? 'pipe ' + addr
	: 'port ' + addr.port;
  debug('Listening on ' + bind);
}


// Client-server connection through socket.io
ioServer.on('connection', function(socket){
	console.log('New client connected with id = ' + socket.id);

	socket.on('disconnect', function(){
	console.log(socket.id + ' disconnected!!');
	});

	// test socket event
	socket.on('getCount', function(){
		console.log("Received count request from client: " + socket.id);
		personData.personCount(function(count){
			socket.emit('personCount', {pCount:count});
		});
	});
  
	// Custom socket event to assign ID to new user
	socket.on('request new user id', function(data){
	// Assign model to var
	var Person = mongoose.model('Person');

	Person.count({'identified':true}, 
	  function(err, count){
		if(count == 0){
		  // If no people in database then assign ID = 1
		  var newID = 1;
		} else {
		  // Else find the max used ID and generate a new ID
		  
		  // Query 'people' collection to find max used ID
		  Person
			.findOne()
			.sort('-personID')
			.exec(function(err, doc){
			  // Generate new ID and name
			  var newID = doc.personID + 1;
			  var newUser = "Guest_" + newID;

			  // Broadcast new user details to all clients
			  socket.emit('new user', {userID:newID, user:newUser})

			});
		}
	  }
	);
	}); // End of event

}); // End of ioServer


// Watch people collection in depthdb for changes
var oplog = new OplogWatcher({
  host:"127.0.0.1:27017" ,ns: "depthdb.people"
});


// Web socket namespace /webApp to handle connections to web app clients
var ioWebApp = ioServer.of('/webApp').on('connection', function(socket){
	console.log('Web app client connected: ' + socket.id);

	// On connection, send all people who have been identified
	var Person = mongoose.model('Person');
	personData.personCount(function(count){
		socket.emit('personCount', {pCount:count});
	}); // Change this


	/* Events called on specific socket */
	/*----------------------------------*/

	/* Events called on the whole namespace */
	/*--------------------------------------*/
	// Event triggered when document updated
	oplog.on('update', function(doc) {
		console.log("Person document updated!");
		console.log(doc);
		ioWebApp.emit('update:person',doc);
	});

	// Event triggered when document inserted
	oplog.on('insert', function(doc) {
		console.log("New person document inserted!");
		console.log(doc);
		ioWebApp.emit('insert:person',doc);
	});

});

 
