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
var routes = require('./routes/index');

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

//app.use('/', routes);

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

}); // End of ioServer */

//event handler for sensor nodes
var ioSensor = ioServer.of('/nodes').on('connection',function(socket){

	console.log('Sensor Node connected with id: ' + socket.id);
	
	//for debug
	socket.on('temp',function(){
		
		var Person = mongoose.model('Person');

		Person.findOne({personID: 3},function(err,doc){
			doc.nodeID = socket.id;
			doc.save();
			console.log('node is now: ' + doc.nodeID);
		});
	});

	//
	socket.on('disconnect', function(){
	    console.log('Sensor Node ' + socket.id + ' disconnected!!');
	});

	//receive JSON and send back / broadcast
	socket.on('rec_data', function(data){
		
		socket.broadcast.emit('res_data', data);

		console.log('Broadcast data from Node ' + socket.id)
	});

	//
	socket.on('req_new_ID',function(){

		var Person = mongoose.model('Person');

		//find the number of people and create new ID with count plus 1
		Person.count({}, function(err, count){
			
			var newID = count + 1;

			//create a new person entity
			var p1 = new Person({
				personName: 'Guest_' + newID,
				personID: newID,
				identified: true,
				nodeID: socket.id

			});

			p1.save(function(err){

				if(err){
					return err;
				}
				else{
					console.log('saved ' + p1.personName + ' with ID: ' + p1.personID);
				}

				//initialise COM and jointPosition for later access
				Person.findOne({personID: p1.personID},function(err,doc){
					
				 	doc.COM.push({});
					for(i=0;i<15;i++){
						doc.jointPosition.push({});
					}

			  		doc.save();
			  		console.log('person with id: ' + doc);
				});				
			});

			socket.emit('res_new_ID', p1.personID);

		});

	});

	//person identified, update database
	socket.on('identified',function(data){

		console.log('id: ' + data);

		var Person = mongoose.model('Person');
		Person.findOne({personID: data},function(err,doc){
			var name = doc.personName;
			console.log('person identified ' + name);
			doc.identified = true;
		});
	});

	//updating COM and jointPosition from node
	socket.on('person_COM',function(data){

		var Person = mongoose.model('Person');


		var size = Object.keys(data).length;

		for (i = 0; i < size; i++){
    		
    		pID = data[i].id;

    		console.log('Updating COM and jointPosition for person with id: ' + pID);

    		var k = i;

			Person.findOne({personID: pID},function(err,doc){

				//update COM field
				doc.COM[0].cx = data[k].COM[0];
				doc.COM[0].cy = data[k].COM[1];
				doc.COM[0].cz = data[k].COM[2];
				
				for(j = 0; j < 15; j++){

					//update jointPosition
					doc.jointPosition[j].cx = data[k].joint[j][0];
					doc.jointPosition[j].cy = data[k].joint[j][1];
					doc.jointPosition[j].cz = data[k].joint[j][2];
				}
    			
    		 	doc.save();

    		 	console.log(doc);
    		});
		}
	});
	
	//event for gesture performed
	socket.on('ges_perf',function(gID, pID){
		
		console.log(gID + ' ' + pID);

		var Person = mongoose.model('Person');

		Person.findOne({personID: pID},function(err,doc){

			//push new gesture record to history log
    		doc.gesList.push({gesID:gID});

    		doc.save();

    	});
	});

	//
	socket.on('ges_new',function(data, gID){
		
		//after training, forward 
		socket.broadcast.emit('ges_res',data, gID);
	})

});

// Watch people collection in depthdb for changes
var oplog = new OplogWatcher({
  host:"127.0.0.1:27017" ,ns: "depthdb.people"
});


// Web socket namespace /webApp to handle connections to web app clients
var ioWebApp = ioServer.of('/webApp').on('connection', function(socket){
	console.log('Web app client connected: ' + socket.id);

	// On connection, send all people who have been identified
	var Person = mongoose.model('Person');
	personData.identPeople(function(data){
		socket.emit('initial:person', {data});
	});

	/* Events called on specific socket */
	/*----------------------------------*/

	socket.on('ges_change',function(data){
		socket.emit('response', data);
	});

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