(function() {
  var MySQLDynamoManager, Table, mysql, utils, _,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __slice = [].slice;

  _ = require('lodash')._;

  mysql = require('mysql');

  Table = require("./table");

  utils = require("./utils");

  module.exports = MySQLDynamoManager = (function(_super) {
    __extends(MySQLDynamoManager, _super);

    MySQLDynamoManager.prototype.defaults = function() {
      return this.extend(MySQLDynamoManager.__super__.defaults.apply(this, arguments), {
        host: 'localhost',
        user: 'root',
        password: 'secret',
        database: "your-database",
        multipleStatements: false,
        waitForConnections: true,
        connectionLimit: 10,
        queueLimit: 0
      });
    };

    function MySQLDynamoManager(options, tableSettings) {
      this.tableSettings = tableSettings;
      this.ERRORS = __bind(this.ERRORS, this);
      this.generate = __bind(this.generate, this);
      this.generateAll = __bind(this.generateAll, this);
      this._getTablesToGenerate = __bind(this._getTablesToGenerate, this);
      this.has = __bind(this.has, this);
      this.get = __bind(this.get, this);
      this.list = __bind(this.list, this);
      this._initTables = __bind(this._initTables, this);
      this._fetchTables = __bind(this._fetchTables, this);
      this.connect = __bind(this.connect, this);
      this.sql = __bind(this.sql, this);
      this.initialize = __bind(this.initialize, this);
      this.defaults = __bind(this.defaults, this);
      MySQLDynamoManager.__super__.constructor.apply(this, arguments);
    }

    MySQLDynamoManager.prototype.initialize = function() {
      this.pool = mysql.createPool(this.config);
      this.connected = false;
      this.fetched = false;
      this._dbTables = {};
      this._tables = {};
      this.log("debug", "initialized");
    };

    MySQLDynamoManager.prototype.sql = function() {
      var args, cb, _i,
        _this = this;

      args = 2 <= arguments.length ? __slice.call(arguments, 0, _i = arguments.length - 1) : (_i = 0, []), cb = arguments[_i++];
      this.log("info", "run query", args);
      if (_.isArray(args[0])) {
        args[0] = args[0].join(";\n");
      }
      this.pool.getConnection(function(err, conn) {
        if (err) {
          cb(err);
          return;
        }
        args.push(function() {
          conn.end();
          cb.apply(_this, arguments);
        });
        conn.query.apply(conn, args);
      });
    };

    MySQLDynamoManager.prototype.connect = function(cb) {
      var _this = this;

      this._fetchTables(function(err) {
        if (err) {
          cb(err);
        } else {
          _this._initTables(null, cb);
        }
      });
    };

    MySQLDynamoManager.prototype._fetchTables = function(cb) {
      var statement,
        _this = this;

      statement = "SELECT table_name as name, table_rows as rows FROM information_schema.tables WHERE  table_schema = database()";
      this.sql(statement, function(err, results) {
        var table, _i, _len;

        if (err) {
          cb(err);
        } else {
          for (_i = 0, _len = results.length; _i < _len; _i++) {
            table = results[_i];
            _this._dbTables[table.name] = table;
          }
          _this.log("debug", "fetched db tables", _this._dbTables);
          _this.fetched = true;
          cb(null, true);
        }
      });
    };

    MySQLDynamoManager.prototype._initTables = function(tables, cb) {
      var table, tableName, _ext, _opt;

      if (tables == null) {
        tables = this.tableSettings;
      }
      if (this.fetched) {
        for (tableName in tables) {
          table = tables[tableName];
          tableName = tableName.toLowerCase();
          if (this._tables[tableName] != null) {
            delete this._tables[tableName];
          }
          _ext = this._dbTables[table.name];
          _opt = {
            manager: this,
            external: _ext,
            logging: this.config.logging
          };
          this._tables[tableName] = new Table(table, _opt);
          this.emit("new-table", tableName, this._tables[tableName]);
        }
        this.connected = true;
        cb(null);
      } else {
        this._handeError(cb, "no-tables-fetched");
      }
    };

    MySQLDynamoManager.prototype.list = function(cb) {
      var _this = this;

      this._fetchTables(function(err) {
        if (err) {
          cb(err);
        } else {
          cb(null, Object.keys(_this._tables));
        }
      });
    };

    MySQLDynamoManager.prototype.get = function(tableName) {
      tableName = tableName.toLowerCase();
      if (this.has(tableName)) {
        return this._tables[tableName];
      } else {
        return null;
      }
    };

    MySQLDynamoManager.prototype.has = function(tableName) {
      tableName = tableName.toLowerCase();
      return this._tables[tableName] != null;
    };

    MySQLDynamoManager.prototype._getTablesToGenerate = function() {
      var tbl, _n, _ref, _ret;

      _ret = {};
      _ref = this._tables;
      for (_n in _ref) {
        tbl = _ref[_n];
        if (_ret[tbl.tableName] == null) {
          _ret[tbl.tableName] = {
            name: _n,
            tableName: tbl.tableName
          };
        }
      }
      return _ret;
    };

    MySQLDynamoManager.prototype.generateAll = function(cb) {
      var aCreate, table, _n, _ref,
        _this = this;

      aCreate = [];
      _ref = this._getTablesToGenerate();
      for (_n in _ref) {
        table = _ref[_n];
        aCreate.push(_.bind(function(tableName, cba) {
          var _this = this;

          this.generate(tableName, function(err, generated) {
            cba(err, generated);
          });
        }, this, table.name));
      }
      utils.runSeries(aCreate, function(err, _generated) {
        if (utils.checkArray(err)) {
          cb(err);
        } else {
          _this.emit("all-tables-generated");
          cb(null);
        }
      });
    };

    MySQLDynamoManager.prototype.generate = function(tableName, cb) {
      var tbl,
        _this = this;

      tbl = this.get(tableName);
      if (!tbl) {
        this._handeError(cb, "table-not-found", {
          tableName: tableName
        });
      } else {
        tbl.generate(function(err, generated) {
          if (err) {
            cb(err);
            return;
          }
          _this.emit("table-generated", generated);
          cb(null, generated);
        });
        return;
      }
    };

    MySQLDynamoManager.prototype.ERRORS = function() {
      return this.extend(MySQLDynamoManager.__super__.ERRORS.apply(this, arguments), {
        "no-tables-fetched": "Currently not tables fetched. Please run `Manager.connect()` first.",
        "table-not-found": "Table `<%= tableName %>` not found."
      });
    };

    return MySQLDynamoManager;

  })(require("./basic"));

}).call(this);
