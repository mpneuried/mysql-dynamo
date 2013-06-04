_ = require('lodash')._
extend = require('extend')
colors = require('colors')

# # Basic Module
# ### extends [Logger](logger.coffee.html)

# Worker basics to handle errors and initialize modules

module.exports = class Base extends require('events').EventEmitter
	# ## internals

	extend: extend

	# **defaukt** *Object* basic object to hold config defaults. Will be overwritten by the constructor options
	defaults: =>
		logging:
			severity: "info"
			severitys: "fatal,error,warning,info,debug".split( "," )

	###	
	## constructor 

	`new Baisc( {} )`
	
	Basie constriuctor. Define the configuration by options and defaults, init logging and init the error handler

	@param {Object} options Basic config object

	###
	constructor: ( options )->
		@config = extend( true, {}, @defaults(), options )

		# init errors
		@_initErrors()

		@initialize()

		return

	initialize: =>
		return

	define: =>
		[ prop, fnGet, fnSet ] = arguments
		if _.isFunction( fnGet )
			_oGetSet = 
				get: fnGet
			_oGetSet.set = fnSet if fnSet? and _.isFunction( fnSet )
			Object.defineProperty @, prop, _oGetSet
		else
			Object.defineProperty @, prop, fnGet
		return

	getter: ( prop, fnGet )=>
		Object.defineProperty @, prop, get: fnGet
		return

	setter: ( prop, fnGet )=>
		Object.defineProperty @, prop, set: fnGet
		return	

	# handle a error
	###
	## _handleError
	
	`basic._handleError( cb, err [, data] )`
	
	Baisc error handler. It creates a true error object and returns it to the callback, logs it or throws the error hard
	
	@param { Function|String } cb Callback function or NAme to send it to the logger as error 
	@param { String|Error|Object } err Error type, Obejct or real error object
	
	@api private
	###
	_handleError: ( cb, err, data = {} )=>
		# try to create a error Object with humanized message
		if _.isString( err )
			_err = new Error()
			_err.name = err
			if @isRest
				_err.message = @_ERRORS?[ err ][ 1 ]?( data ) or "unkown"
			else
				_err.message = @_ERRORS?[ err ]?( data ) or "unkown"
			_err.customError = true
		else 
			_err = err

		if _.isFunction( cb )
			#@log "error", "", _err
			cb( _err )
		else if _.isString( cb )
			@log "error", cb, _err
		else
			throw _err
		return

	# ### log 
	#
	# *trigger a log event to run the configured logger*
	#
	# **Parameters:**
	#
	# **severity:** { Response } *type of logging entry. Possibel values are: fatal,error,warning,info,debug*
	# **errorcode:** { String } *log errorcode*  
	# **content:** { any } *Data to log*
	# **time:** { Number } *optional time to log the duration of a process*
	###
	## log
	
	`base.log( id, cb )`
	
	desc
	
	@param { String } id Desc 
	@param { Function } cb Callback function 
	
	@return { String } Return Desc 
	
	@api private
	###
	log: ( severity, code, content... )=>

		# get the severity and throw a log event
		if @_checkLogging( severity )
			_tmpl = "%s %s - #{ new Date().toString()[4..23]} - %s "

			args = [ _tmpl, severity.toUpperCase(), @constructor.name, code ]

			if content.length
				args[ 0 ] += "\n"
				for _c in content
					args.push _c

			switch severity
				when "fatal"
					args[ 0 ] = args[ 0 ].red.bold.inverse
					console.error.apply( console, args )
					console.trace()
				when "error"
					args[ 0 ] = args[ 0 ].red.bold
					console.error.apply( console, args )
				when "warning"
					args[ 0 ] = args[ 0 ].yellow.bold
					console.warn.apply( console, args )
				when "info"
					args[ 0 ] = args[ 0 ].blue.bold
					console.info.apply( console, args )
				when "debug"
					args[ 0 ] = args[ 0 ].green.bold
					console.log.apply( console, args )
				else
	
		return

	_checkLogging: ( severity )=>
		if not @_logging_iseverity?
			@_logging_iseverity = @config.logging.severitys.indexOf( @config.logging.severity )

		iServ = @config.logging.severitys.indexOf( severity )
		if @config.logging.severity? and iServ <= @_logging_iseverity
			true
		else
			false

	###
	## _initErrors
	
	`basic._initErrors(  )`
	
	convert error messages to underscore templates
	
	@api private
	###
	_initErrors: =>
		@_ERRORS = @ERRORS()
		for key, msg of @_ERRORS
			if @isRest
				if not _.isFunction( msg[ 1 ] )
					@_ERRORS[ key ][ 1 ] = _.template( msg[ 1 ] )
			else
				if not _.isFunction( msg )
					@_ERRORS[ key ] = _.template( msg )
		return

	ERRORS: =>
		"not-implemented": "This function is planed but currently not implemented"