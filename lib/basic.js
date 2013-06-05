(function() {
  var Base, colors, extend, _,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __slice = [].slice;

  _ = require('lodash')._;

  extend = require('extend');

  colors = require('colors');

  module.exports = Base = (function(_super) {
    __extends(Base, _super);

    Base.prototype.extend = extend;

    Base.prototype.defaults = function() {
      return {
        logging: {
          severity: "info",
          severitys: "fatal,error,warning,info,debug".split(",")
        }
      };
    };

    /*	
    	## constructor 
    
    	`new Baisc( {} )`
    	
    	Basie constriuctor. Define the configuration by options and defaults, init logging and init the error handler
    
    	@param {Object} options Basic config object
    */


    function Base(options) {
      this.ERRORS = __bind(this.ERRORS, this);
      this._initErrors = __bind(this._initErrors, this);
      this._checkLogging = __bind(this._checkLogging, this);
      this.log = __bind(this.log, this);
      this._handleError = __bind(this._handleError, this);
      this.setter = __bind(this.setter, this);
      this.getter = __bind(this.getter, this);
      this.define = __bind(this.define, this);
      this.initialize = __bind(this.initialize, this);
      this.defaults = __bind(this.defaults, this);      this.config = extend(true, {}, this.defaults(), options);
      this._initErrors();
      this.initialize();
      return;
    }

    Base.prototype.initialize = function() {};

    Base.prototype.define = function() {
      var fnGet, fnSet, prop, _oGetSet;

      prop = arguments[0], fnGet = arguments[1], fnSet = arguments[2];
      if (_.isFunction(fnGet)) {
        _oGetSet = {
          get: fnGet
        };
        if ((fnSet != null) && _.isFunction(fnSet)) {
          _oGetSet.set = fnSet;
        }
        Object.defineProperty(this, prop, _oGetSet);
      } else {
        Object.defineProperty(this, prop, fnGet);
      }
    };

    Base.prototype.getter = function(prop, fnGet) {
      Object.defineProperty(this, prop, {
        get: fnGet
      });
    };

    Base.prototype.setter = function(prop, fnGet) {
      Object.defineProperty(this, prop, {
        set: fnGet
      });
    };

    /*
    	## _handleError
    	
    	`basic._handleError( cb, err [, data] )`
    	
    	Baisc error handler. It creates a true error object and returns it to the callback, logs it or throws the error hard
    	
    	@param { Function|String } cb Callback function or NAme to send it to the logger as error 
    	@param { String|Error|Object } err Error type, Obejct or real error object
    	
    	@api private
    */


    Base.prototype._handleError = function(cb, err, data) {
      var _base, _err, _ref, _ref1;

      if (data == null) {
        data = {};
      }
      if (_.isString(err)) {
        _err = new Error();
        _err.name = err;
        if (this.isRest) {
          _err.message = ((_ref = this._ERRORS) != null ? typeof (_base = _ref[err])[1] === "function" ? _base[1](data) : void 0 : void 0) || "unkown";
        } else {
          _err.message = ((_ref1 = this._ERRORS) != null ? typeof _ref1[err] === "function" ? _ref1[err](data) : void 0 : void 0) || "unkown";
        }
        _err.customError = true;
      } else {
        _err = err;
      }
      if (_.isFunction(cb)) {
        cb(_err);
      } else if (_.isString(cb)) {
        this.log("error", cb, _err);
      } else {
        throw _err;
      }
    };

    /*
    	## log
    	
    	`base.log( id, cb )`
    	
    	desc
    	
    	@param { String } id Desc 
    	@param { Function } cb Callback function 
    	
    	@return { String } Return Desc 
    	
    	@api private
    */


    Base.prototype.log = function() {
      var args, code, content, severity, _c, _i, _len, _tmpl;

      severity = arguments[0], code = arguments[1], content = 3 <= arguments.length ? __slice.call(arguments, 2) : [];
      if (this._checkLogging(severity)) {
        _tmpl = "%s %s - " + (new Date().toString().slice(4, 24)) + " - %s ";
        args = [_tmpl, severity.toUpperCase(), this.constructor.name, code];
        if (content.length) {
          args[0] += "\n";
          for (_i = 0, _len = content.length; _i < _len; _i++) {
            _c = content[_i];
            args.push(_c);
          }
        }
        switch (severity) {
          case "fatal":
            args[0] = args[0].red.bold.inverse;
            console.error.apply(console, args);
            console.trace();
            break;
          case "error":
            args[0] = args[0].red.bold;
            console.error.apply(console, args);
            break;
          case "warning":
            args[0] = args[0].yellow.bold;
            console.warn.apply(console, args);
            break;
          case "info":
            args[0] = args[0].blue.bold;
            console.info.apply(console, args);
            break;
          case "debug":
            args[0] = args[0].green.bold;
            console.log.apply(console, args);
            break;
        }
      }
    };

    Base.prototype._checkLogging = function(severity) {
      var iServ;

      if (this._logging_iseverity == null) {
        this._logging_iseverity = this.config.logging.severitys.indexOf(this.config.logging.severity);
      }
      iServ = this.config.logging.severitys.indexOf(severity);
      if ((this.config.logging.severity != null) && iServ <= this._logging_iseverity) {
        return true;
      } else {
        return false;
      }
    };

    /*
    	## _initErrors
    	
    	`basic._initErrors(  )`
    	
    	convert error messages to underscore templates
    	
    	@api private
    */


    Base.prototype._initErrors = function() {
      var key, msg, _ref;

      this._ERRORS = this.ERRORS();
      _ref = this._ERRORS;
      for (key in _ref) {
        msg = _ref[key];
        if (this.isRest) {
          if (!_.isFunction(msg[1])) {
            this._ERRORS[key][1] = _.template(msg[1]);
          }
        } else {
          if (!_.isFunction(msg)) {
            this._ERRORS[key] = _.template(msg);
          }
        }
      }
    };

    Base.prototype.ERRORS = function() {
      return {
        "not-implemented": "This function is planed but currently not implemented"
      };
    };

    return Base;

  })(require('events').EventEmitter);

}).call(this);
