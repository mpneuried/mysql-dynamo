(function() {
  exports.version = '0.2.7';

  exports.getSqlBuilder = require('./lib/sql');

  exports.utils = require('./lib/utils');

  exports.table = require('./lib/table');

  module.exports = require('./lib/manager');

}).call(this);
