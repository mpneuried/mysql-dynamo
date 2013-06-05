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
      this.del = __bind(this.del, this);
      this.set = __bind(this.set, this);
      this.find = __bind(this.find, this);
      this.mget = __bind(this.mget, this);
      this.get = __bind(this.get, this);
      this._generate = __bind(this._generate, this);
      this.generate = __bind(this.generate, this);
      this.initialize = __bind(this.initialize, this);
      this.sql = __bind(this.sql, this);
      this.mng = options.manager;
      this.external = options.external;
      this.getter("name", function() {
        return _this._model_settings.name;
      });
      this.getter("tableName", function() {
        return _this._model_settings.name;
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

    MySQLDynamoTable.prototype.sql = function() {
      return this.mng.sql.apply(this.mng, arguments);
    };

    MySQLDynamoTable.prototype.initialize = function() {
      var SQLBuilder;

      this.log("debug", "init table", this.tableName, this.hashKey, this.rangeKey);
      SQLBuilder = (require("./sql"))({
        logging: this.config.logging
      });
      this.builder = new SQLBuilder();
      this.builder.table = this.name;
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

    MySQLDynamoTable.prototype.generate = function(cb) {
      if (!this.existend) {
        this._generate(cb);
      } else {
        this.emit("create-status", "already-active");
        cb(null, false);
      }
    };

    MySQLDynamoTable.prototype._generate = function(cb) {
      var statement,
        _this = this;

      statement = this.builder.create();
      this.sql(statement, function(err, result) {
        _this.log("debug", "table generated", statement, err, result);
        if (err) {
          cb(err);
          return;
        }
        _this.external = {
          name: _this.name,
          rows: 0
        };
        cb(null, _this.external);
      });
    };

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
        this.sql(sql.query(false), function(err, results) {
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
        _statement = sql.query(false);
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
          query[this.rangeKey] = {
            ">": startAt[this.rangeKey]
          };
        }
        this.log("debug", "find", query, startAt, options);
        sql = this.builder.clone();
        if (options.fields != null) {
          sql.fields = options.fields;
        }
        sql.forward = options.forward != null ? options.forward : true;
        sql.limit = options.limit != null ? options.limit : 1000;
        sql.filter(query);
        _statement = sql.query();
        this.sql(_statement, function(err, result) {
          if (err) {
            cb(err);
            return;
          }
          _this.log("debug", "find query", _statement, result);
          cb(null, result);
        });
      }
    };

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
              if (options.fields != null) {
                sql.fields = options.fields;
              }
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
              statements.push(sqlGet.query(false));
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
            if (options.fields != null) {
              sql.fields = options.fields;
            }
            _query = _this._deFixHash(_id, cb);
            if (_query == null) {
              return;
            }
            sql.filter(_query);
            _select = sql.query(false);
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
        _statements = [];
        sql = this.builder.clone();
        if (options.fields != null) {
          sql.fields = options.fields;
        }
        sql.filter(_query);
        _statements = [sql.query(false), sql.del()];
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

    MySQLDynamoTable.prototype._defaultHashKey = function() {
      return uuid.v1();
    };

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
