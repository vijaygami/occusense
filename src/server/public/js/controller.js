angular.module('myApp.controllers', [])
.controller("HelloController", function($scope, socket) {

    console.log("Controller");

    socket.emit('getCount');

    socket.on('personCount', function(data){
        console.log("received data from server!");
        console.log(data.pCount);
    	$scope.count = data.pCount;
    });

    socket.on('update:person', function(data){
        console.log("received update from server");
        console.log(data);
    	$scope.pName = data.personName;
    });

    $scope.helloTo = {};
    $scope.helloTo.title = "AngularJS";
});