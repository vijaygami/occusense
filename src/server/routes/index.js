var express = require('express');
var router = express.Router();
var personData = require('../db/person');

/* GET home page. */
router.get('/', function(req, res, next) {
  
	// Get people count
	personData.personCount(function(err, count){
		res.render('index', {count: count});
	});
});

module.exports = router;
