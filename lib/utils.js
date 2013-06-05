(function() {
  var _;

  _ = require('lodash')._;

  module.exports = {
    runSeries: function(fns, callback) {
      var completed, data, iterate;

      if (fns.length === 0) {
        return callback();
      }
      completed = 0;
      data = [];
      iterate = function() {
        return fns[completed](function(results) {
          data[completed] = results;
          if (++completed === fns.length) {
            if (callback) {
              return callback(data);
            }
          } else {
            return iterate();
          }
        });
      };
      return iterate();
    },
    runParallel: function(fns, callback) {
      var completed, data, iterate, started;

      if (fns.length === 0) {
        return callback();
      }
      started = 0;
      completed = 0;
      data = [];
      iterate = function() {
        fns[started]((function(i) {
          return function(results) {
            data[i] = results;
            if (++completed === fns.length) {
              if (callback) {
                callback(data);
              }
            }
          };
        })(started));
        if (++started !== fns.length) {
          return iterate();
        }
      };
      return iterate();
    },
    checkArray: function(ar) {
      if (_.isArray(ar)) {
        return _.any(ar, _.identity);
      } else {
        return _.identity(ar);
      }
    }
  };

}).call(this);
