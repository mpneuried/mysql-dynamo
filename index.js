(function() {
  exports.version = '0.3.2';

  exports.getSqlBuilder = require('./lib/sql');

  exports.utils = require('./lib/utils');

  exports.table = require('./lib/table');

  module.exports = require('./lib/manager');

}).call(this);
