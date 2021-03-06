mongoose = require('mongoose');

// Return people count in all rooms
exports.personCount = function personCount(callback){
	
	// Assign model to local variable
	var Person = mongoose.model('Person');

	// Find total count of people all rooms
	Person.count({'identified': true}, function(err, count){
		if (err){
			console.error(err);
		} else {
			callback("", count);
		}
	});
};

// Return identified people in all rooms
exports.identPeople = function identPeople(callback){
	
	// Assign model to local variable
	var Person = mongoose.model('Person');

	// Find total count of people all rooms
	Person.find({'identified': true}, function(err, data){
		if (err){
			console.error(err);
		} else {
			callback(data);
		}
	});
};