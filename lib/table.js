(function() {
  var MySQLDynamoTable, uuid, _,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __slice = [].slice;

  uuid = require('node-uuid');

  _ = require('lodash')._;

  module.exports = MySQLDynamoTable = (function(_super) {
    __extends(MySQLDynamoTable, _super);

    MySQLDynamoTable.prototype.defaults = function() {
      return this.extend(MySQLDynamoTable.__super__.defaults.apply(this, arguments), {
        tablePrefix: null
      });
    };

    /*	
    	## constructor 
    
    	`new MySQLDynamoTable( _model_settings, options )`
    	
    	Define the getter and setter and configure teh table.
    
    	@param {Object} _model_settings Model configuration.
    	@param {Object} options Basic config object
    */


    function MySQLDynamoTable(_model_settings, options) {
      var _this = this;

      this._model_settings = _model_settings;
      this.ERRORS = __bind(this.ERRORS, this);
      this._defaultRangeKey = __bind(this._defaultRangeKey, this);
      this._defaultHashKey = __bind(this._defaultHashKey, this);
      this._createRangeKey = __bind(this._createRangeKey, this);
      this._createHashKey = __bind(this._createHashKey, this);
      this._createId = __bind(this._createId, this);
      this._postProcess = __bind(this._postProcess, this);
      this._validateAttributes = __bind(this._validateAttributes, this);
      this._convertValue = __bind(this._convertValue, this);
      this._deFixHash = __bind(this._deFixHash, this);
      this._getOptions = __bind(this._getOptions, this);
      this._isExistend = __bind(this._isExistend, this);
      this._generate = __bind(this._generate, this);
      this.destroy = __bind(this.destroy, this);
      this.del = __bind(this.del, this);
      this.set = __bind(this.set, this);
      this.find = __bind(this.find, this);
      this.mget = __bind(this.mget, this);
      this.get = __bind(this.get, this);
      this.generate = __bind(this.generate, this);
      this.initialize = __bind(this.initialize, this);
      this.sql = __bind(this.sql, this);
      this.defaults = __bind(this.defaults, this);
      this.mng = options.manager;
      this.external = options.external;
      this.getter("name", function() {
        return _this._model_settings.name;
      });
      this.getter("tableName", function() {
        return (options.tablePrefix || "") + _this._model_settings.name;
      });
      this.getter("existend", function() {
        return _this.external != null;
      });
      this.getter("hasRange", function() {
        var _ref, _ref1;

        if ((_ref = _this._model_settings) != null ? (_ref1 = _ref.rangeKey) != null ? _ref1.length : void 0 : void 0) {
          return true;
        } else {
          return false;
        }
      });
      this.getter("hashKey", function() {
        var _ref;

        return ((_ref = _this._model_settings) != null ? _ref.hashKey : void 0) || null;
      });
      this.getter("hashKeyType", function() {
        var _ref;

        return ((_ref = _this._model_settings) != null ? _ref.hashKeyType : void 0) || "S";
      });
      this.getter("hashKeyLength", function() {
        var _ref;

        return ((_ref = _this._model_settings) != null ? _ref.hashKeyLength : void 0) || (_this.hashKeyType === "N" ? 5 : 255);
      });
      this.getter("rangeKey", function() {
        var _ref;

        return ((_ref = _this._model_settings) != null ? _ref.rangeKey : void 0) || null;
      });
      this.getter("rangeKeyType", function() {
        var _ref;

        if (_this.hasRange) {
          return ((_ref = _this._model_settings) != null ? _ref.rangeKeyType : void 0) || "N";
        } else {
          return null;
        }
      });
      this.getter("rangeKeyLength", function() {
        var _ref;

        return ((_ref = _this._model_settings) != null ? _ref.rangeKeyLength : void 0) || (_this.rangeKeyType === "N" ? 5 : 255);
      });
      MySQLDynamoTable.__super__.constructor.call(this, options);
      return;
    }

    /*
    	## sql
    	
    	`table.sql( statement[, args], cb )`
    	
    	shortcut to the `manager.sql()` method
    
    	@param { String|Array } statement A MySQL SQL statement or an array of multiple statements
    	@param { Array|Object } [args] Query arguments to auto escape. The arguments will directly passed to the `mysql.query()` method from [node-mysql](https://github.com/felixge/node-mysql#escaping-query-values)
    	@param { Function } cb Callback function 
    	
    	@api public
    */


    MySQLDynamoTable.prototype.sql = function() {
      return this.mng.sql.apply(this.mng, arguments);
    };

    /*
    	## initialize
    	
    	`table.initialize()`
    	
    	Initialize the Table object
    	
    	@api private
    */


    MySQLDynamoTable.prototype.initialize = function() {
      var SQLBuilder;

      this.log("debug", "init table", this.tableName, this.hashKey, this.rangeKey);
      SQLBuilder = (require("./sql"))({
        logging: this.config.logging
      });
      this.builder = new SQLBuilder();
      this.builder.table = this.tableName;
      this.builder.hash = {
        key: this.hashKey,
        type: this.hashKeyType,
        length: this.hashKeyLength
      };
      if (this.hasRange) {
        this.builder.range = {
          key: this.rangeKey,
          type: this.rangeKeyType,
          length: this.rangeKeyLength
        };
      }
      this.builder.setAttrs(_.clone(this._model_settings.attributes));
      if (this._model_settings.defaultfields != null) {
        this.builder.fields = this._model_settings.defaultfields;
      }
    };

    /*
    	## generate
    	
    	`table.generate( cb )`
    	
    	Generate the table within the DB if not existend
    	
    	@param { Function } cb Callback function 
    	
    	@api public
    */


    MySQLDynamoTable.prototype.generate = function(cb) {
      if (!this.existend) {
        this._generate(cb);
      } else {
        this.emit("create-status", "already-active");
        cb(null, false);
      }
    };

    /*
    	## get
    	
    	`table.get( id[, options], cb )`
    	
    	Get a single element
    	
    	@param { String|Number|Array } id The id of an element. If the used table is a range table you have to use an array `[hash,range]` as combined id.
    	@param { Object } [options] Options. See the [docs](http://mpneuried.github.io/mysql-dynamo/) for more information.
    	@param { Function } cb Callback function 
    	
    	@api public
    */


    MySQLDynamoTable.prototype.get = function() {
      var args, cb, options, sql, _i, _id, _query,
        _this = this;

      args = 2 <= arguments.length ? __slice.call(arguments, 0, _i = arguments.length - 1) : (_i = 0, []), cb = arguments[_i++];
      if (this._isExistend(cb)) {
        options = null;
        switch (args.length) {
          case 1:
            _id = args[0];
            break;
          case 2:
            _id = args[0], options = args[1];
        }
        options = this._getOptions(options);
        sql = this.builder.clone();
        if (options.fields != null) {
          sql.fields = options.fields;
        }
        sql.forward = options.forward != null ? options.forward : true;
        sql.limit = options.limit != null ? options.limit : 1000;
        _query = this._deFixHash(_id, cb);
        if (_query == null) {
          return;
        }
        sql.filter(_query);
        this.sql(sql.select(false), function(err, results) {
          var _obj;

          if (err) {
            cb(err);
            return;
          }
          if (results != null ? results.length : void 0) {
            _obj = _this._postProcess(results[0]);
            _this.emit("get", _obj);
            cb(null, _obj);
          } else {
            _this.emit("get-empty");
            cb(null, null);
          }
        });
      }
    };

    /*
    	## mget
    	
    	`table.mget( ids,[, options], cb )`
    	
    	Get multiple elements at once
    	
    	@param { Array } ids An array of id of an elements. If the used table is a range table you have to use an array of arrays `[hash,range]` as combined id.
    	@param { Object } [options] Options. See the [docs](http://mpneuried.github.io/mysql-dynamo/) for more information.
    	@param { Function } cb Callback function 
    	
    	@api public
    */


    MySQLDynamoTable.prototype.mget = function() {
      var args, cb, options, sql, _i, _id, _ids, _j, _len, _query, _statement,
        _this = this;

      args = 2 <= arguments.length ? __slice.call(arguments, 0, _i = arguments.length - 1) : (_i = 0, []), cb = arguments[_i++];
      if (this._isExistend(cb)) {
        options = null;
        switch (args.length) {
          case 1:
            _ids = args[0];
            break;
          case 2:
            _ids = args[0], options = args[1];
        }
        options = this._getOptions(options);
        sql = this.builder.clone();
        if (options.fields != null) {
          sql.fields = options.fields;
        }
        sql.forward = options.forward != null ? options.forward : true;
        sql.limit = options.limit != null ? options.limit : 1000;
        for (_j = 0, _len = _ids.length; _j < _len; _j++) {
          _id = _ids[_j];
          _query = this._deFixHash(_id, cb);
          if (_query != null) {
            sql.or().filterGroup().filter(_query);
          }
        }
        _statement = sql.select(false);
        this.log("debug", "mget", _ids, _statement);
        this.sql(_statement, function(err, results) {
          var _k, _len1, _obj, _objs;

          if (err) {
            cb(err);
            return;
          }
          if (results != null ? results.length : void 0) {
            _objs = [];
            for (_k = 0, _len1 = results.length; _k < _len1; _k++) {
              _obj = results[_k];
              _objs.push(_this._postProcess(_obj));
            }
            _this.emit("mget", _objs);
            cb(null, _objs);
          } else {
            _this.emit("mget-empty");
            cb(null, []);
          }
        });
      }
    };

    /*
    	## find
    	
    	`table.find( query[, startAt][, options], cb )`
    	
    	Find elements in a table
    	
    	@param { Object } query A query object. How to build … have a look at [Jed's Predicates ](https://github.com/jed/dynamo/wiki/High-level-API#wiki-predicates)
    	@param { String|Number|Array } [startAt] To realize a paging you can define a `startAt`. Usually the last item of a list. If you define `startAt` with the last item of the previous find you get the next collection of items without the given `startAt` item.  
    If the used table is a range table you have to use an array `[hash,range]` as combined `startAt`.
    	@param { Object } [options] Options. See the [docs](http://mpneuried.github.io/mysql-dynamo/) for more information.
    	@param { Function } cb Callback function 
    
    	@api public
    */


    MySQLDynamoTable.prototype.find = function() {
      var args, cb, options, query, sql, startAt, _i, _qHash, _statement, _x,
        _this = this;

      args = 2 <= arguments.length ? __slice.call(arguments, 0, _i = arguments.length - 1) : (_i = 0, []), cb = arguments[_i++];
      if (this._isExistend(cb)) {
        options = null;
        startAt = null;
        query = {};
        switch (args.length) {
          case 1:
            query = args[0];
            break;
          case 2:
            query = args[0], _x = args[1];
            if (_.isString(_x) || _.isNumber(_x)) {
              startAt = _x;
            } else {
              options = _x;
            }
            break;
          case 3:
            query = args[0], startAt = args[1], options = args[2];
        }
        options = this._getOptions(options);
        sql = this.builder.clone();
        if (options.fields != null) {
          sql.fields = options.fields;
        }
        sql.forward = options.forward != null ? options.forward : true;
        sql.limit = options.limit != null ? options.limit : 1000;
        if (startAt != null) {
          if (this.isRange) {
            this._handleError(cb, "startat-not-allowed");
            return;
          }
          startAt = this._deFixHash(startAt, cb);
          if (query[this.hashKey] != null) {
            _qHash = _.first(_.values(query[this.hashKey]));
          }
          if ((_qHash != null) && startAt[this.hashKey] !== _qHash) {
            this._handleError(cb, "invalid-startat-hash");
            return;
          }
          query[this.rangeKey] = {};
          query[this.rangeKey][sql.forward ? ">" : "<"] = startAt[this.rangeKey];
        }
        this.log("debug", "find", query, startAt, options);
        sql.filter(query);
        _statement = sql.select();
        this.sql(_statement, function(err, results) {
          var _j, _len, _obj, _objs;

          if (err) {
            cb(err);
            return;
          }
          _this.log("debug", "find query", _statement, results);
          if (results != null ? results.length : void 0) {
            _objs = [];
            for (_j = 0, _len = results.length; _j < _len; _j++) {
              _obj = results[_j];
              _objs.push(_this._postProcess(_obj));
            }
            cb(null, _objs);
          } else {
            cb(null, []);
          }
        });
      }
    };

    /*
    	## set
    	
    	`table.set( [ id,] data,[ options,] fnCallback  )`
    	
    	Insert or update an item. If the first argument is defined ist used as a update otherwise as a insert.
    	
    	@param { String|Number|Array } [id] If this argument is defined the `set` will be executed as a update otherwise as a insert. The id of an element. If the used table is a range table you have to use an array [hash,range] as combined id.
    	@param { Object } data The data to update or insert.
    	@param { Object } [options] Options. See the [docs](http://mpneuried.github.io/mysql-dynamo/) for more information.
    	@param { Function } cb Callback function 
    	
    	@api public
    */


    MySQLDynamoTable.prototype.set = function() {
      var args, attributes, cb, options, sql, _create, _i, _id,
        _this = this;

      args = 2 <= arguments.length ? __slice.call(arguments, 0, _i = arguments.length - 1) : (_i = 0, []), cb = arguments[_i++];
      if (this._isExistend(cb)) {
        options = null;
        switch (args.length) {
          case 1:
            _create = true;
            _id = null;
            attributes = args[0];
            break;
          case 2:
            if (_.isString(args[0]) || _.isNumber(args[0]) || _.isArray(args[0])) {
              _create = false;
              _id = args[0], attributes = args[1];
            } else {
              _create = true;
              _id = null;
              attributes = args[0], options = args[1];
            }
            break;
          case 3:
            _create = false;
            _id = args[0], attributes = args[1], options = args[2];
        }
        options = this._getOptions(options);
        sql = this.builder.clone();
        if (options.fields != null) {
          sql.fields = options.fields;
        }
        this._validateAttributes(_create, attributes, function(err, attributes) {
          var statements, _query, _select;

          if (err) {
            cb(err);
            return;
          }
          if (_create) {
            _this._createId(attributes, function(err, attributes) {
              var sqlGet, statements, _query;

              _this.log("debug", "create a item", attributes, options);
              statements = [sql.insert(attributes)];
              sqlGet = _this.builder.clone();
              _query = {};
              if (_this.hasRange) {
                _query[_this.hashKey] = attributes[_this.hashKey];
                _query[_this.rangeKey] = attributes[_this.rangeKey];
              } else {
                _query[_this.hashKey] = attributes[_this.hashKey];
              }
              sqlGet.filter(_query);
              statements.push(sqlGet.select(false));
              _this.sql(statements, function(err, results) {
                var _inserted, _meta, _obj;

                _this.log("info", "insert", err, results);
                if (err) {
                  if (err.code === "ER_DUP_ENTRY") {
                    _this._handleError(cb, "conditional-check-failed");
                    return;
                  }
                  cb(err);
                  return;
                }
                _meta = results[0], _inserted = results[1];
                if (_inserted != null ? _inserted.length : void 0) {
                  _obj = _this._postProcess(_inserted[0]);
                  _this.log("debug", "insert", statements, _obj);
                  _this.emit("create", _obj);
                  cb(null, _obj);
                } else {
                  cb(null, null);
                }
              });
            });
          } else {
            _this.log("debug", "update a item", _id, attributes, options);
            _query = _this._deFixHash(_id, cb);
            if (_query == null) {
              return;
            }
            sql.filter(_query);
            _select = sql.select(false);
            if (options.conditionals != null) {
              sql.filter(options.conditionals);
            }
            statements = [sql.update(attributes), _select];
            _this.sql(statements, function(err, results) {
              var _meta, _obj, _updated;

              if (err) {
                cb(err);
                return;
              }
              _this.log("debug", "update", results);
              _meta = results[0], _updated = results[1];
              if (_meta.affectedRows <= 0) {
                _this._handleError(cb, "conditional-check-failed");
                return;
              }
              if (_updated != null ? _updated.length : void 0) {
                _obj = _this._postProcess(_updated[0]);
                _this.emit("update", _obj);
                cb(null, _obj);
              } else {
                cb(null, null);
              }
            });
          }
        });
      }
    };

    /*
    	## del
    	
    	`table.del( id, cb )`
    	
    	Delete a single element
    	
    	@param { String|Number|Array } id The id of an element. If the used table is a range table you have to use an array `[hash,range]` as combined id. Otherwise you will get an error. 
    	@param { Function } cb Callback function 
    	
    	@api public
    */


    MySQLDynamoTable.prototype.del = function(_id, cb) {
      var args, options, sql, _i, _query, _statements,
        _this = this;

      args = 2 <= arguments.length ? __slice.call(arguments, 0, _i = arguments.length - 1) : (_i = 0, []), cb = arguments[_i++];
      _id = args[0], options = args[1];
      options || (options = {});
      if (this._isExistend(cb)) {
        _query = this._deFixHash(_id, cb);
        if (_query == null) {
          return;
        }
        sql = this.builder.clone();
        if (options.fields != null) {
          sql.fields = options.fields;
        }
        sql.filter(_query);
        _statements = [sql.select(false), sql.del()];
        this.sql(_statements, function(err, results) {
          var _deleted, _meta, _obj;

          if (err) {
            cb(err);
            return;
          }
          _meta = results[0], _deleted = results[1];
          _this.log("debug", "deleted", _meta, _deleted);
          if (_deleted != null ? _deleted.length : void 0) {
            _obj = _this._postProcess(_deleted[0]);
            _this.emit("delete", _deleted);
            cb(null, _obj);
          } else {
            _this.emit("del-empty");
            cb(null, null);
          }
        });
      }
    };

    /*
    	## destroy
    	
    	`table.destroy( cb )`
    	
    	Destroy this table with all data
    	
    	@param { Function } cb Callback function 
    	
    	@api public
    */


    MySQLDynamoTable.prototype.destroy = function(cb) {
      var sql,
        _this = this;

      if (this._isExistend()) {
        sql = this.builder.clone();
        this.sql(sql.drop(), function(err, meta) {
          if (err) {
            cb(err);
            return;
          }
          _this.emit("destroy", _this);
          _this.external = null;
          cb(null, meta);
        });
      } else {
        cb(null, null);
      }
    };

    /*
    	## _generate
    	
    	`table._generate( cb )`
    	
    	Run the create table sql query
    	
    	@param { Function } cb Callback function 
    	
    	@api private
    */


    MySQLDynamoTable.prototype._generate = function(cb) {
      var statement,
        _this = this;

      statement = this.builder.create();
      this.sql(statement, function(err, result) {
        _this.log("warning", "table `" + _this.tableName + "` generated");
        if (err) {
          cb(err);
          return;
        }
        _this.external = {
          name: _this.tableName,
          rows: 0
        };
        cb(null, _this.external);
      });
    };

    /*
    	## _isExistend
    	
    	`table._isExistend( [cb] )`
    	
    	Check if this tabel exists within the DB
    	
    	@param { Function } [cb] Callback method to answer with an error if defined
    	
    	@return { Boolean } Table exists 
    	
    	@api private
    */


    MySQLDynamoTable.prototype._isExistend = function(cb) {
      if (this.existend) {
        return true;
      } else {
        if (_.isFunction(cb)) {
          this._handleError(cb, "table-not-created", {
            tableName: this.tableName
          });
        }
        return false;
      }
    };

    /*
    	## _getOptions
    	
    	`table._getOptions( [options] )`
    	
    	Get the default options
    	
    	@param { Object } [options={}] The argument options to overwrite the defaults
    	
    	@return { Object } Extended options 
    	
    	@api private
    */


    MySQLDynamoTable.prototype._getOptions = function(options) {
      var _defOpt;

      if (options == null) {
        options = {};
      }
      _defOpt = {
        fields: this._model_settings.defaultfields != null ? this._model_settings.defaultfields : null,
        forward: this._model_settings.forward != null ? this._model_settings.forward : true
      };
      return _.extend(_defOpt, options || {});
    };

    /*
    	## _deFixHash
    	
    	`table._deFixHash( attrs, cb )`
    	
    	Convert a hash or hash/range id to a query
    	
    	@param { String|Number|Array|Object } attrs The id to convert 
    	@param { Function } cb Callback method to answer with an error
    	
    	@return { Object } The generated query 
    	
    	@api private
    */


    MySQLDynamoTable.prototype._deFixHash = function(attrs, cb) {
      var _attrs, _h, _hName, _hType, _r, _rName, _rType, _ref;

      if (_.isString(attrs) || _.isNumber(attrs) || _.isArray(attrs)) {
        _hName = this.hashKey;
        _attrs = {};
        _attrs[_hName] = _.clone(attrs);
      } else {
        _attrs = _.clone(attrs);
      }
      if (this.hasRange) {
        _hType = this.hashKeyType;
        _rName = this.rangeKey;
        _rType = this.rangeKeyType;
        if (!_.isArray(_attrs[_hName])) {
          this._handleError(cb, "invalid-range-call");
          return;
        }
        _ref = _attrs[_hName], _h = _ref[0], _r = _ref[1];
        _attrs[_hName] = this._convertValue(_h, _hType);
        _attrs[_rName] = this._convertValue(_r, _rType);
      }
      return _attrs;
    };

    /*
    	## _convertValue
    	
    	`table._convertValue( val, type )`
    	
    	Convert values to the defined type
    	
    	@param { Any } val The value to convert 
    	@param { String } type The type 
    	
    	@return { Any } The converted value 
    	
    	@api private
    */


    MySQLDynamoTable.prototype._convertValue = function(val, type) {
      switch (type.toUpperCase()) {
        case "N":
        case "numeric":
          return parseFloat(val, 10);
        case "S":
        case "string":
          if (val) {
            return val.toString(val);
          }
          break;
        default:
          return val;
      }
    };

    /*
    	## _validateAttributes
    	
    	`table._validateAttributes( isCreate, attrs, cb )`
    	
    	remove attributes that are not defined as table column
    	
    	@param { Boolean } isCreate This is a validation for create call 
    	@param { Object } attrs The attributtes to validate
    	@param { Function } cb Callback function 
    	
    	@api private
    */


    MySQLDynamoTable.prototype._validateAttributes = function(isCreate, attrs, cb) {
      var _k, _omit, _v;

      _omit = [];
      for (_k in attrs) {
        _v = attrs[_k];
        if (!_.isNumber(_v) && _.isEmpty(_v)) {
          attrs[_k] = null;
        }
      }
      this.log("debug", "_validateAttributes", attrs, _omit);
      cb(null, attrs);
    };

    /*
    	## _postProcess
    	
    	`table._postProcess( attrs )`
    	
    	Remove empty columns to act like dynamo and convert set columns to an array
    	
    	@param { Object } attrs The element to process 
    	
    	@return { Object } The processed object 
    	
    	@api private
    */


    MySQLDynamoTable.prototype._postProcess = function(attrs) {
      var _aKey, _arrayKeys, _i, _k, _len, _omit, _v;

      _arrayKeys = this.builder.attrArrayKeys;
      if (_arrayKeys.length) {
        for (_i = 0, _len = _arrayKeys.length; _i < _len; _i++) {
          _aKey = _arrayKeys[_i];
          if (attrs[_aKey] != null) {
            attrs[_aKey] = this.builder.setToArray(attrs[_aKey]);
          }
        }
      }
      _omit = [];
      for (_k in attrs) {
        _v = attrs[_k];
        if (!_.isNumber(_v) && _.isEmpty(_v)) {
          _omit.push(_k);
        }
      }
      attrs = _.omit(attrs, _omit);
      return attrs;
    };

    /*
    	## _createId
    	
    	`table._createId( attributes, cb )`
    	
    	Generate an new id. it will be a hash or a combination of hash/range and return the changed attributes
    	
    	@param { Obejct } attributes The attributes to insert 
    	@param { Function } cb Callback function 
    	
    	@api private
    */


    MySQLDynamoTable.prototype._createId = function(attributes, cb) {
      var _this = this;

      this._createHashKey(attributes, function(attributes) {
        if (_this.hasRange) {
          _this._createRangeKey(attributes, function(attributes) {
            cb(null, attributes);
          });
        } else {
          cb(null, attributes);
        }
      });
    };

    /*
    	## _createHashKey
    	
    	`table._createHashKey( attributes, cbH )`
    	
    	Get or generate a new hash.
    	
    	@param { Object } attributes The attributes to insert  
    	@param { Function } cbH Callback function 
    	
    	@api private
    */


    MySQLDynamoTable.prototype._createHashKey = function(attributes, cbH) {
      var _hName, _hType,
        _this = this;

      _hName = this.hashKey;
      _hType = this.hashKeyType;
      if (this._model_settings.fnCreateHash && _.isFunction(this._model_settings.fnCreateHash)) {
        this._model_settings.fnCreateHash(attributes, function(_hash) {
          attributes[_hName] = _this._convertValue(_hash, _hType);
          cbH(attributes);
        });
      } else if (attributes[_hName] != null) {
        attributes[_hName] = this._convertValue(attributes[_hName], _hType);
        cbH(attributes);
      } else {
        attributes[_hName] = this._convertValue(this._defaultHashKey(), _hType);
        cbH(attributes);
      }
    };

    /*
    	## _createRangeKey
    	
    	`table._createRangeKey( attributes, cbR )`
    	
    	Get or generate a new range.
    	
    	@param { Object } attributes The attributes to insert  
    	@param { Function } cbR Callback function 
    	
    	@api private
    */


    MySQLDynamoTable.prototype._createRangeKey = function(attributes, cbR) {
      var _rName, _rType,
        _this = this;

      _rName = this.rangeKey;
      _rType = this.rangeKeyType;
      if (this._model_settings.fnCreateRange && _.isFunction(this._model_settings.fnCreateRange)) {
        this._model_settings.fnCreateRange(attributes, function(__range) {
          attributes[_rName] = _this._convertValue(__range, _rType);
          cbR(attributes);
        });
      } else if (attributes[_rName] != null) {
        attributes[_rName] = this._convertValue(attributes[_rName], _rType);
        cbR(attributes);
      } else {
        attributes[_rName] = this._convertValue(this._defaultRangeKey(), _rType);
        cbR(attributes);
      }
    };

    /*
    	## _defaultHashKey
    	
    	`table._defaultHashKey()`
    	
    	Generate a default hash
    	
    	@return { String } A uuid as defaul hash 
    	
    	@api private
    */


    MySQLDynamoTable.prototype._defaultHashKey = function() {
      return uuid.v1();
    };

    /*
    	## _defaultRangeKey
    	
    	`table._defaultRangeKey()`
    	
    	Generate a default range key
    	
    	@return { Number } The current timestamp as default range key
    	
    	@api private
    */


    MySQLDynamoTable.prototype._defaultRangeKey = function() {
      return Date.now();
    };

    MySQLDynamoTable.prototype.ERRORS = function() {
      return this.extend(MySQLDynamoTable.__super__.ERRORS.apply(this, arguments), {
        "invalid-startat-hash": "The `startAt` has to be equal a queried hash.",
        "startat-not-allowed": "`startAt` value is only allowed for range tables",
        "conditional-check-failed": "This is not a valid request. It doesnt match the conditions or you tried to insert a existing hash.",
        "table-not-created": "Table '<%= tableName %>' not existend at AWS. please run `Table.generate()` or `Manager.generateAll()` first.",
        "invalid-range-call": "If you try to access a hash/range item you have to pass a Array of `[hash,range]` as id."
      });
    };

    return MySQLDynamoTable;

  })(require("./basic"));

}).call(this);
