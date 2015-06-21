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
var routes = require('./routes/index');

// Create app instance
var app = express();
var server = http.createServer(app);

// Attach Socket.IO to server
var ioServer = require('socket.io').listen(server);

//settings for socket.io
ioServer.set('log level', 1);

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
	res.sendFile(__dirname + '/views/index.html');
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


//event handler for server 
var ioWeb = ioServer.of('/web').on('connection', function (socket) {

	console.log('Sensor connected with id = ' + socket.id);

	socket.on('disconnect', function(){
	    console.log(socket.id + ' disconnected!!');
	});

	setInterval(function(){
		socket.emit('date', {'date': new Date()});
	}, 1000);
	

});

//event handler for sensor nodes
var ioSensor = ioServer.of('/nodes').on('connection',function(socket){

	console.log('Sensor Node connected with id: ' + socket.id);
	
	//receive JSON and send back / broadcast
	socket.on('test_fwd', function(data){
		
		socket.broadcast.emit('test_bcd', data);

		console.log('Broadcast data from Node ' + socket.id);
	});

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
		
			});

			socket.emit('res_new_ID', p1.personID);
			console.log('"'+p1.personID+'" sent back to sensor with id: '+p1.nodeID);
		});

	});


	// Person lost from view of all cameras so update identified field in db
	socket.on("lost:person",function(data){

		var Person = mongoose.model('Person');
		Person.findOne({personID: data},function(err,doc){
			if (err){
				console.error(err);
			} else {
				
				doc.identified = false;		// Update status
				doc.save();					// Save document in db
				console.log(doc.personName + ' lost with id: ' + doc.personID);
				console.log('Database updated for ' + doc.personName);
			}
		});
	});
	

	// Person identified and in view of atleast one camera
	socket.on('identified',function(data){

		var Person = mongoose.model('Person');
		Person.findOne({personID: data},function(err,doc){
			if (err){
				console.error(err);
			} else {
				
				doc.identified = true;		// Update status
				doc.nodeID = socket.id;
				doc.save();					// Save document in db
				console.log(doc.personName + ' identified with id: ' + doc.personID+' at Sensor: '+socket.id);
				console.log('Database updated for ' + doc.personName);	
			}
		});
	});

	//updating COM and jointPosition from node
	socket.on('person_COM',function(data){

		var Person = mongoose.model('Person');


		var size = Object.keys(data).length;

		for (i = 0; i < size; i++){
    		
    		pID = data[i].id;

    		//console.log('Updating COM and jointPosition for person with id: ' + pID);

    		var k = i;

			Person.findOne({personID: pID},function(err,doc){

				//update COM field
				doc.coord.x = data[k].COM[0];
				doc.coord.y = data[k].COM[1];
				doc.coord.z = data[k].COM[2];
				
				//update jointPosition
				doc.joints.head.x = data[k].joint[0][0];
				doc.joints.head.y = data[k].joint[0][1];
				doc.joints.head.z = data[k].joint[0][2];

				doc.joints.neck.x = data[k].joint[1][0];
				doc.joints.neck.y = data[k].joint[1][1];
				doc.joints.neck.z = data[k].joint[1][2];

				doc.joints.leftshoulder.x = data[k].joint[2][0];
				doc.joints.leftshoulder.y = data[k].joint[2][1];
				doc.joints.leftshoulder.z = data[k].joint[2][2];

				doc.joints.rightshoulder.x = data[k].joint[3][0];
				doc.joints.rightshoulder.y = data[k].joint[3][1];
				doc.joints.rightshoulder.z = data[k].joint[3][2];
				
				doc.joints.lefthip.x = data[k].joint[4][0];
				doc.joints.lefthip.y = data[k].joint[4][1];
				doc.joints.lefthip.z = data[k].joint[4][2];

				doc.joints.righthip.x = data[k].joint[5][0];
				doc.joints.righthip.y = data[k].joint[5][1];
				doc.joints.righthip.z = data[k].joint[5][2];

				doc.joints.leftknee.x = data[k].joint[6][0];
				doc.joints.leftknee.y = data[k].joint[6][1];
				doc.joints.leftknee.z = data[k].joint[6][2];
																								
				doc.joints.rightknee.x = data[k].joint[7][0];
				doc.joints.rightknee.y = data[k].joint[7][1];
				doc.joints.rightknee.z = data[k].joint[7][2];

				doc.joints.rightelbow.x = data[k].joint[8][0];
				doc.joints.rightelbow.y = data[k].joint[8][1];
				doc.joints.rightelbow.z = data[k].joint[8][2];  

				doc.joints.leftelbow.x = data[k].joint[9][0];
				doc.joints.leftelbow.y = data[k].joint[9][1];
				doc.joints.leftelbow.z = data[k].joint[9][2];

				doc.joints.righthand.x = data[k].joint[10][0];
				doc.joints.righthand.y = data[k].joint[10][1];
				doc.joints.righthand.z = data[k].joint[10][2];

				doc.joints.lefthand.x = data[k].joint[11][0];
				doc.joints.lefthand.y = data[k].joint[11][1];
				doc.joints.lefthand.z = data[k].joint[11][2];

				doc.joints.torso.x = data[k].joint[12][0];
				doc.joints.torso.y = data[k].joint[12][1];
				doc.joints.torso.z = data[k].joint[12][2];

				doc.joints.leftfoot.x = data[k].joint[13][0];
				doc.joints.leftfoot.y = data[k].joint[13][1];
				doc.joints.leftfoot.z = data[k].joint[13][2];				
				
				doc.joints.rightfoot.x = data[k].joint[14][0];
				doc.joints.rightfoot.y = data[k].joint[14][1];
				doc.joints.rightfoot.z = data[k].joint[14][2];					

				doc.save();

    		});
		}
	});
	

	//event for gesture performed
	socket.on('ges_perf',function(gID, pID){
		
		console.log(gID + ' performed by ' + pID);

		var Person = mongoose.model('Person');

		Person.findOne({personID: pID},function(err,doc){

			//push new gesture record to history log
    		doc.gesList.push({gesID:gID});
    		doc.save();
    		//ioWebApp.broadcast.emit('');
    	});
	});

	//
	socket.on('ges_new',function(data, gID){
		
		//after training, forward 
		socket.broadcast.emit('ges_res',data, gID);
	})

	//
	socket.on('checkUser',function(pID){
		var Person = mongoose.model('Person');
		
		Person.findOne({personID: pID},function(err,doc){ 
			var check;

			if (doc.identified == false){
				check = 1;
			} else {
				check = 0;
			}
			socket.emit('res_checkUser', check);
			console.log(check+' for checking user sent back to sensor with id: '+doc.nodeID);
		});
	});

});

// Web socket namespace /webApp to handle connections to web app clients
var ioWebApp = ioServer.of('/webApp').on('connection', function(socket){
	console.log('Web app client connected: ' + socket.id);

	var Person = mongoose.model('Person');
	
	/* Events called on specific socket */
	/*----------------------------------*/
	socket.on('request:person', function(){
		personData.identPeople(function(data){
			socket.emit('update:person', data);
		});		
	});

	//
	socket.on('ges_change',function(gID, pID){
		var Person = mongoose.model('Person');
		Person.findOne({personID: pID},function(err,doc){ 
			ioSensor.to(doc.nodeID).emit('ges_train', gID, pID);
		});
	});

	//
	socket.on('userName_change',function(pID, newname){
		var Person = mongoose.model('Person');
		Person.findOne({personID: pID},function(err,doc){ 
			doc.personName = newname;
			doc.save();
			console.log(doc.personName+' has changed name to '+newname);
		});
	});

});