(function() {
  var mysql, _,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  mysql = require('mysql');

  _ = require('lodash')._;

  module.exports = function(options) {
    var SQLBuilder;

    return SQLBuilder = (function(_super) {
      __extends(SQLBuilder, _super);

      SQLBuilder.prototype.defaults = function() {
        return this.extend(SQLBuilder.__super__.defaults.apply(this, arguments), {
          fields: "*",
          limit: 1000,
          hash: {
            key: "",
            type: "S",
            required: true,
            length: 5,
            "default": "",
            isHash: true
          },
          range: {
            key: "",
            type: "N",
            required: true,
            length: 11,
            "default": 0,
            isRange: true
          },
          attr: {
            key: "",
            type: "S",
            required: false,
            length: 255
          },
          sqlSetDelimiter: "|",
          standardFilterCombine: "AND"
        });
      };

      function SQLBuilder(_c) {
        var _base, _base1, _base2;

        this._c = _c != null ? _c : {};
        this.ERRORS = __bind(this.ERRORS, this);
        this._generateSetCommand = __bind(this._generateSetCommand, this);
        this._getAttrConfig = __bind(this._getAttrConfig, this);
        this._validateAttributes = __bind(this._validateAttributes, this);
        this._getSaveVariables = __bind(this._getSaveVariables, this);
        this.getArrayAttrKeys = __bind(this.getArrayAttrKeys, this);
        this.getLimit = __bind(this.getLimit, this);
        this.setLimit = __bind(this.setLimit, this);
        this.getFields = __bind(this.getFields, this);
        this.setFields = __bind(this.setFields, this);
        this.getWhere = __bind(this.getWhere, this);
        this.getOrderField = __bind(this.getOrderField, this);
        this.getOrderBy = __bind(this.getOrderBy, this);
        this.getForward = __bind(this.getForward, this);
        this.setForward = __bind(this.setForward, this);
        this.getAttrKeys = __bind(this.getAttrKeys, this);
        this.getAttrs = __bind(this.getAttrs, this);
        this.setAttrs = __bind(this.setAttrs, this);
        this._isRange = __bind(this._isRange, this);
        this.getRangeKey = __bind(this.getRangeKey, this);
        this.getRange = __bind(this.getRange, this);
        this.setRange = __bind(this.setRange, this);
        this.getHashKey = __bind(this.getHashKey, this);
        this.getHash = __bind(this.getHash, this);
        this.setHash = __bind(this.setHash, this);
        this.getTable = __bind(this.getTable, this);
        this.setTable = __bind(this.setTable, this);
        this.setToArray = __bind(this.setToArray, this);
        this.genRowCreate = __bind(this.genRowCreate, this);
        this.del = __bind(this.del, this);
        this.create = __bind(this.create, this);
        this.filterGroup = __bind(this.filterGroup, this);
        this.and = __bind(this.and, this);
        this.or = __bind(this.or, this);
        this.filter = __bind(this.filter, this);
        this.query = __bind(this.query, this);
        this.update = __bind(this.update, this);
        this.insert = __bind(this.insert, this);
        this.clone = __bind(this.clone, this);
        this.initialize = __bind(this.initialize, this);
        this.defaults = __bind(this.defaults, this);
        (_base = this._c).attrs || (_base.attrs = []);
        (_base1 = this._c).attrKeys || (_base1.attrKeys = []);
        (_base2 = this._c).attrsArrayKeys || (_base2.attrsArrayKeys = []);
        SQLBuilder.__super__.constructor.call(this, options);
        return;
      }

      SQLBuilder.prototype.initialize = function() {
        this.define("table", this.getTable, this.setTable);
        this.define("hash", this.getHash, this.setHash);
        this.getter("hashkey", this.getHashKey);
        this.define("range", this.getRange, this.setRange);
        this.getter("rangekey", this.getRangeKey);
        this.getter("isRange", this._isRange);
        this.define("attrs", this.getAttrs, this.setAttrs);
        this.getter("attrKeys", this.getAttrKeys);
        this.getter("attrArrayKeys", this.getArrayAttrKeys);
        this.define("fields", this.getFields, this.setFields);
        this.define("limit", this.getLimit, this.setLimit);
        this.define("forward", this.getForward, this.setForward);
        this.getter("orderby", this.getOrderBy);
        this.getter("orderfield", this.getOrderField);
        this.getter("where", this.getWhere);
        this.log("debug", "initialized");
      };

      SQLBuilder.prototype.clone = function() {
        this.log("debug", "run clone", Object.keys(this._c));
        return new SQLBuilder(_.clone(this._c));
      };

      SQLBuilder.prototype.insert = function(attributes) {
        var statement, _keys, _ref, _vals;

        attributes = this._validateAttributes(true, attributes);
        statement = [];
        statement.push("INSERT INTO " + this.table);
        _ref = this._getSaveVariables(attributes), _keys = _ref[0], _vals = _ref[1];
        statement.push("( " + (_keys.join(", ")) + " )");
        statement.push("VALUES ( " + (_vals.join(", ")) + " )");
        return _.compact(statement).join("\n");
      };

      SQLBuilder.prototype.update = function(attributes) {
        var statement, _i, _idx, _key, _keys, _len, _ref, _sets, _vals;

        attributes = this._validateAttributes(false, attributes);
        statement = [];
        statement.push("UPDATE " + this.table);
        _ref = this._getSaveVariables(attributes), _keys = _ref[0], _vals = _ref[1];
        _sets = [];
        for (_idx = _i = 0, _len = _keys.length; _i < _len; _idx = ++_i) {
          _key = _keys[_idx];
          _sets.push("" + _key + " = " + _vals[_idx]);
        }
        statement.push("SET " + (_sets.join(", ")));
        statement.push(this.where);
        return _.compact(statement).join("\n");
      };

      SQLBuilder.prototype.query = function(complex) {
        var statement;

        if (complex == null) {
          complex = true;
        }
        statement = [];
        statement.push("SELECT " + this.fields);
        statement.push("FROM " + this.table);
        statement.push(this.where);
        if (complex) {
          statement.push(this.orderby);
          statement.push(this.limit);
        }
        return _.compact(statement).join("\n");
      };

      SQLBuilder.prototype.filter = function(key, pred) {
        var _base, _cbn, _filter, _k, _operand, _pred, _ref, _val;

        (_base = this._c).filters || (_base.filters = []);
        this.log("debug", "filter", key, pred);
        if (_.isObject(key)) {
          for (_k in key) {
            _pred = key[_k];
            this.filter(_k, _pred);
          }
        } else {
          _filter = "" + key + " ";
          if (pred == null) {
            _filter += "is NULL";
          } else if (_.isString(pred) || _.isNumber(pred)) {
            _filter += "= " + (mysql.escape(pred));
          } else {
            _operand = Object.keys(pred)[0];
            _val = pred[_operand];
            switch (_operand) {
              case "==":
                _filter += _val != null ? "= " + (mysql.escape(_val)) : "is NULL";
                break;
              case "!=":
                _filter += _val != null ? "!= " + (mysql.escape(_val)) : "is not NULL";
                break;
              case ">":
              case "<":
                _filter += "" + _operand + " " + (mysql.escape(_val));
                break;
              case ">":
              case "<":
              case "<=":
              case ">=":
                if (_.isArray(_val)) {
                  _filter += "between " + (mysql.escape(_val[0])) + " and " + (mysql.escape(_val[1]));
                } else {
                  _filter += "" + _operand + " " + (mysql.escape(_val));
                }
                break;
              case "contains":
                _filter += "like '" + (mysql.escape("%" + _val + "%")) + "'";
                break;
              case "!contains":
                _filter += "not like '" + (mysql.escape("%" + _val + "%")) + "'";
                break;
              case "startsWith":
                _filter += "like '" + (mysql.escape(_val + "%")) + "'";
                break;
              case "in":
                if (!_.isArray(_val)) {
                  _val = [_val];
                }
                _filter += "in ( '" + (mysql.escape(_val)) + "')";
            }
          }
          if ((_ref = this._c.filters) != null ? _ref.length : void 0) {
            _cbn = this._c._filterCombine ? this._c._filterCombine : this.config.standardFilterCombine;
            this._c.filters.push(_cbn);
          }
          this._c.filters.push(_filter);
          this._c._filterCombine = null;
        }
        return this;
      };

      SQLBuilder.prototype.or = function() {
        var _ref;

        if ((_ref = this._c.filters) != null ? _ref.length : void 0) {
          this._c._filterCombine = "OR";
        }
        return this;
      };

      SQLBuilder.prototype.and = function() {
        var _ref;

        if ((_ref = this._c.filters) != null ? _ref.length : void 0) {
          this._c._filterCombine = "AND";
        }
        return this;
      };

      SQLBuilder.prototype.filterGroup = function(newGroup) {
        var _add, _base, _ref;

        if (newGroup == null) {
          newGroup = true;
        }
        (_base = this._c).filters || (_base.filters = []);
        _add = 0;
        if ((this._c._filterGroup != null) && this._c._filterGroup >= 0) {
          this.log("debug", "filterGroup A", this._c.filters, this._c._filterGroup);
          if (this._c._filterGroup === 0) {
            this._c.filters.unshift("(");
          } else {
            this._c.filters.splice(this._c._filterGroup, 0, "(");
          }
          this._c.filters.push(")");
          _add = 1;
          this.log("debug", "filterGroup B", this._c.filters, this._c._filterGroup);
          this._c._filterGroup = null;
        }
        if (newGroup) {
          this._c._filterGroup = (((_ref = this._c.filters) != null ? _ref.length : void 0) || 0) + _add;
        }
        return this;
      };

      SQLBuilder.prototype.create = function() {
        var attr, defs, prim, statement, _i, _len, _ref;

        statement = [];
        statement.push("CREATE TABLE " + this.table + " (");
        defs = [];
        _ref = this.attrs;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          attr = _ref[_i];
          defs.push(this.genRowCreate(attr));
        }
        prim = "\nPRIMARY KEY (";
        prim += " `" + this.hash.key + "` ";
        if (this.isRange) {
          prim += ", `" + this.range.key + "` ";
        }
        prim += ")";
        defs.push(prim);
        statement.push(defs.join(", "));
        statement.push("\n) ENGINE=InnoDB DEFAULT CHARSET=utf8;");
        return statement.join(" ");
      };

      SQLBuilder.prototype.del = function() {
        var statement;

        statement = [];
        statement.push("DELETE");
        statement.push("FROM " + this.table);
        statement.push(this.where);
        return _.compact(statement).join("\n");
      };

      SQLBuilder.prototype.genRowCreate = function(opt) {
        var isSet, isString, stmt, _opt;

        _opt = this.extend({}, this.config.attr, opt);
        stmt = "\n`" + _opt.key + "` ";
        isString = false;
        isSet = false;
        if (_opt.type === "A" || _opt.type === "array") {
          isSet = true;
          stmt += "text";
        } else if (_opt.type === "S" || _opt.type === "string") {
          isString = true;
          if (_opt.length === +Infinity) {
            stmt += "text ";
          } else {
            stmt += "varchar(" + _opt.length + ") ";
          }
        } else {
          if (_opt.length > 11) {
            stmt += "bigint(" + _opt.length + ") ";
          } else {
            stmt += "int(" + _opt.length + ") ";
          }
        }
        if (!isSet && _opt.required) {
          stmt += "NOT NULL ";
        }
        if (!isSet && (_opt["default"] != null)) {
          if (isString) {
            stmt += "DEFAULT '" + _opt["default"] + "'";
          } else {
            stmt += "DEFAULT " + _opt["default"];
          }
        }
        return stmt;
      };

      SQLBuilder.prototype.setToArray = function(value) {
        var _lDlm;

        _lDlm = this.config.sqlSetDelimiter.length;
        if ((value == null) || (value != null ? value.length : void 0) <= _lDlm) {
          return null;
        }
        return value.slice(_lDlm, +(-(_lDlm + 1)) + 1 || 9e9).split(this.config.sqlSetDelimiter);
      };

      SQLBuilder.prototype.setTable = function(tbl) {
        this._c.table = tbl;
      };

      SQLBuilder.prototype.getTable = function() {
        if (this._c.table != null) {
          return this._c.table;
        } else {
          return this._handleError(null, "no-table");
        }
      };

      SQLBuilder.prototype.setHash = function(_h) {
        this._c.hash = {};
        this.extend(this._c.hash, this.config.hash, _h);
        this._c.attrs.push(this._c.hash);
        this._c.attrKeys.push(this._c.hash.key);
      };

      SQLBuilder.prototype.getHash = function() {
        if (this._c.hash != null) {
          return this._c.hash;
        } else {
          return this._handleError(null, "no-hash");
        }
      };

      SQLBuilder.prototype.getHashKey = function() {
        return this.hash.key;
      };

      SQLBuilder.prototype.setRange = function(_r) {
        if (_r != null) {
          this._c.isRange = true;
          this._c.range = {};
          this.extend(this._c.range, this.config.range, _r);
          this._c.attrs.push(this._c.range);
          this._c.attrKeys.push(this._c.range.key);
        } else {
          this._c.isRange = false;
          _.omit(this._c, "range");
        }
      };

      SQLBuilder.prototype.getRange = function() {
        return this._c.range;
      };

      SQLBuilder.prototype.getRangeKey = function() {
        if (this.isrange) {
          return this.range.key;
        } else {
          return null;
        }
      };

      SQLBuilder.prototype._isRange = function() {
        if (this._c.isRange != null) {
          return this._c.isRange || false;
        }
      };

      SQLBuilder.prototype.setAttrs = function(_attrs) {
        var attr, _i, _len, _ref;

        for (_i = 0, _len = _attrs.length; _i < _len; _i++) {
          attr = _attrs[_i];
          if (attr.key != null) {
            this._c.attrKeys.push(attr.key);
            this._c.attrs.push(this.extend({}, this.config.attr, attr));
            if ((_ref = attr.type) === "A" || _ref === "array") {
              this._c.attrsArrayKeys.push(attr.key);
            }
          }
        }
      };

      SQLBuilder.prototype.getAttrs = function() {
        if (this._c.attrs != null) {
          return this._c.attrs;
        } else {
          return [];
        }
      };

      SQLBuilder.prototype.getAttrKeys = function() {
        return this._c.attrKeys || [];
      };

      SQLBuilder.prototype.setForward = function(_forward) {
        if (_forward == null) {
          _forward = true;
        }
        if (_forward) {
          this._c.forward = true;
        } else {
          this._c.forward = false;
        }
      };

      SQLBuilder.prototype.getForward = function() {
        if (this._c.forward != null) {
          return this._c.forward;
        } else {
          return true;
        }
      };

      SQLBuilder.prototype.getOrderBy = function() {
        if (this.forward) {
          return "ORDER BY " + this.orderfield + " ASC";
        } else {
          return "ORDER BY " + this.orderfield + " DESC";
        }
      };

      SQLBuilder.prototype.getOrderField = function() {
        if (this.isRange) {
          return this.rangekey;
        } else {
          return this.hashkey;
        }
      };

      SQLBuilder.prototype.getWhere = function() {
        var _filters;

        _filters = this._c.filters || [];
        if (_filters.length) {
          this.filterGroup(false);
          return "WHERE " + (_filters.join("\n"));
        } else {
          return null;
        }
      };

      SQLBuilder.prototype.setFields = function(_fields) {
        if (_fields == null) {
          _fields = this.config.fields;
        }
        if (_.isArray(_fields)) {
          this._c.fields = _fields.join(", ");
        } else {
          this._c.fields = _fields;
        }
      };

      SQLBuilder.prototype.getFields = function() {
        if (this._c.fields != null) {
          return this._c.fields;
        } else {
          return this.config.fields;
        }
      };

      SQLBuilder.prototype.setLimit = function(_limit) {
        if (_limit == null) {
          _limit = this.config.limit;
        }
        this._c.limit = _limit;
      };

      SQLBuilder.prototype.getLimit = function() {
        if (this._c.limit != null) {
          return "LIMIT " + this._c.limit;
        } else {
          return "LIMIT " + this.config.limit;
        }
      };

      SQLBuilder.prototype.getArrayAttrKeys = function() {
        return this._c.attrsArrayKeys || [];
      };

      SQLBuilder.prototype._getSaveVariables = function(attributes) {
        var _cnf, _key, _keys, _setval, _val, _vals;

        _keys = [];
        _vals = [];
        for (_key in attributes) {
          _val = attributes[_key];
          _cnf = this._getAttrConfig(_key);
          if (_cnf) {
            switch (_cnf.type) {
              case "string":
              case "number":
              case "S":
              case "N":
                _keys.push(_key);
                _vals.push(mysql.escape(_val));
                break;
              case "array":
              case "A":
                _setval = this._generateSetCommand(_key, _val, this.config.sqlSetDelimiter);
                if (_setval != null) {
                  _keys.push(_key);
                  _vals.push(_setval);
                }
                this.log("debug", "setCommand", _setval, _val, _key);
            }
          }
        }
        return [_keys, _vals];
      };

      SQLBuilder.prototype._validateAttributes = function(isCreate, attrs) {
        attrs = _.pick(attrs, this.attrKeys);
        this.log("debug", "validateAttributes", attrs);
        return attrs;
      };

      SQLBuilder.prototype._getAttrConfig = function(key) {
        var attr, _i, _len, _ref;

        _ref = this.attrs;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          attr = _ref[_i];
          if (attr.key === key) {
            return attr;
          }
        }
        return null;
      };

      SQLBuilder.prototype._generateSetCommandTmpls = {
        add: _.template('IF( INSTR( <%= set %>,"<%= val %><%= dlm %>") = 0, "<%= val %><%= dlm %>", "" )'),
        rem: _.template('REPLACE( <%= set %>, "<%= dlm %><%= val %><%= dlm %>", "<%= dlm %>")'),
        set: _.template('IF( <%= key %> is NULL,"<%= dlm %>", <%= key %>)')
      };

      SQLBuilder.prototype._generateSetCommand = function(key, inp, dlm) {
        var added, usedRem, _add, _i, _inp, _j, _len, _len1, _ref, _ref1, _set;

        this.log("debug", "_generateSetCommand", key, inp);
        if (inp == null) {
          return mysql.escape(dlm);
        } else if (_.isArray(inp)) {
          if (!inp.length) {
            return mysql.escape(dlm);
          } else {
            return mysql.escape(dlm + inp.join(dlm) + dlm);
          }
        } else if (_.isObject(inp)) {
          if (inp["$reset"]) {
            if (_.isArray(inp["$reset"])) {
              return mysql.escape(dlm + inp["$reset"].join(dlm) + dlm);
            } else {
              return mysql.escape(dlm + inp["$reset"] + dlm);
            }
          } else {
            _set = this._generateSetCommandTmpls.set({
              key: key,
              dlm: dlm
            });
            _add = [_set];
            added = [];
            usedRem = false;
            if (inp["$add"] != null) {
              if (_.isArray(inp["$add"])) {
                _ref = _.uniq(inp["$add"]);
                for (_i = 0, _len = _ref.length; _i < _len; _i++) {
                  _inp = _ref[_i];
                  added.push(_inp);
                  _add.push(this._generateSetCommandTmpls.add({
                    val: _inp,
                    set: _set,
                    dlm: dlm
                  }));
                }
              } else {
                added.push(inp["$add"]);
                _add.push(this._generateSetCommandTmpls.add({
                  val: inp["$add"],
                  set: _set,
                  dlm: dlm
                }));
              }
              if (_add.length) {
                _set = "CONCAT( " + (_add.join(", ")) + " )";
              }
            }
            if (inp["$rem"] != null) {
              if (_.isArray(inp["$rem"])) {
                _ref1 = _.difference(_.uniq(inp["$rem"]), added);
                for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
                  _inp = _ref1[_j];
                  usedRem = true;
                  _set = this._generateSetCommandTmpls.rem({
                    val: _inp,
                    set: _set,
                    dlm: dlm
                  });
                }
              } else {
                usedRem = true;
                _set = this._generateSetCommandTmpls.rem({
                  val: inp["$rem"],
                  set: _set,
                  dlm: dlm
                });
              }
            }
            if (added.length || usedRem) {
              return _set;
            } else {
              return null;
            }
          }
        } else if (inp != null) {
          return mysql.escape(dlm + inp + dlm);
        } else {
          return null;
        }
      };

      SQLBuilder.prototype.ERRORS = function() {
        return this.extend(SQLBuilder.__super__.ERRORS.apply(this, arguments), {
          "no-tables": "No table defined",
          "no-hash": "No hash defined"
        });
      };

      return SQLBuilder;

    })(require("./basic"));
  };

}).call(this);
