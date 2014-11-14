(function() {
  var app;

  app = angular.module('BApp', ['B.Chart.Users', 'B.Table.Cmds', 'B.Table.Pkgs', 'B.Map', 'B.Delta', 'ui.bootstrap']);

  app.factory('bDataSvc', function($http) {
    return {
      fetchAllP: $http.get("https://bower-server-etl.herokuapp.com/api/1/data/all")
    };
  });

  app.factory('bPoP', function() {
    var _reduceFunc;
    _reduceFunc = function(period, currentOrPrior) {
      return function(a, b, i) {
        if ((currentOrPrior === 'current' ? i >= period : i < period)) {
          return a + b;
        } else {
          return a;
        }
      };
    };
    return {
      process: function(data, period) {
        return [data.reduce(_reduceFunc(period, 'prior'), 0), data.reduce(_reduceFunc(period, 'current'), 0)];
      }
    };
  });

  app.factory('d3', function() {
    return d3;
  });

  app.controller('BHeaderCtrl', function(bDataSvc) {
    bDataSvc.fetchAllP.then((function(_this) {
      return function(data) {
        _this.pkgs = data.data.overview.totalPackages;
      };
    })(this));
  });

  app.filter('round', function() {
    return function(input, decimals) {
      if (input == null) {
        return void 0;
      } else if (input >= 1000) {
        return (input / 1000).toFixed(1) + ' k';
      } else {
        return input.toFixed(decimals);
      }
    };
  });

}).call(this);

//# sourceMappingURL=../js/b-app.js.map