angular.module('app.controllers', ['ui.keypress', 'angularLocalStorage']).controller({
  AppCtrl: ['$scope', 'storage', '$location'].concat(function($scope, storage, $location){
    storage.bind($scope, 'list', {
      defaultValue: []
    });
    $scope.add = function(){
      $scope.list.unshift({
        title: $scope.newItem
      });
      return $scope.newItem = "";
    };
    $scope.toggleItem = function(id){
      return console.log(id);
    };
    return console.log($location.path());
  })
});
angular.module('app', ['app.controllers'], function($locationProvider){
  return $locationProvider.html5Mode(true);
});