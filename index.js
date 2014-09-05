(function() {
<<<<<<< HEAD
  exports.version = '0.3.0';
=======
  exports.version = '@@version';
>>>>>>> eaa0e8f0da9d0dbdbbc83d6d0ef9a8026c70cae6

  exports.getSqlBuilder = require('./lib/sql');

  exports.utils = require('./lib/utils');

  exports.table = require('./lib/table');

  module.exports = require('./lib/manager');

}).call(this);
