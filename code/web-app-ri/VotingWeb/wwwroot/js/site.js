var app = angular.module('VotingApp', ['ui.bootstrap']);
app.run(function () { });

app.controller('VotingAppController', ['$rootScope', '$scope', '$http', '$timeout', '$interval', function ($rootScope, $scope, $http, $timeout, $interval) {


    $http.get('api/Votes/cache')
            .then(function (data, status) {
                $scope.ads = data;
            }, function (data, status) {
                $scope.ads = undefined;
            })

    $scope.refresh = function () {
        $http.get('api/Votes?c=' + new Date().getTime())
            .then(function (data, status) {
                $scope.votes = data;
            }, function (data, status) {
                $scope.votes = undefined;
            })
    };
    
  
    $interval($scope.refresh, 10000);



    $scope.remove = function (item) {
        $http.delete('api/Votes/' + item)
            .then(function (data, status) {
                $scope.refresh();
            })
    };

    $scope.addNew = function (item) {
        var fd = new FormData();
        fd.append('item', item);
        $http.put('api/Votes/Add/' + item , fd, {
            transformRequest: angular.identity,
            headers: { 'Content-Type': undefined }
        })
            .then(function (data, status) {
                $scope.refresh();
                $scope.item = undefined;
                $scope.error = undefined;
            },
                function (response) {
                    $scope.error = response.data;
                })
    };

    $scope.add = function (id) {
        var fd = new FormData();
        fd.append('item', id);
        $http.put('api/Votes/vote/' + id, fd, {
            transformRequest: angular.identity,
            headers: { 'Content-Type': undefined }
        })
            .then(function (data, status) {
                $scope.refresh();
                $scope.item = undefined;
                $scope.error = undefined;
            },
            function (response) {
                $scope.error = response.data;
            })
    };
}]);