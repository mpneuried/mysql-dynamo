(function() {
  exports.version = '0.2.1';

  exports.getSqlBuilder = require('./lib/sql');

  exports.utils = require('./lib/utils');

  exports.utils = require('./lib/table');

  module.exports = require('./lib/manager');

}).call(this);
