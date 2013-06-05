uuid = require 'node-uuid'
_ = require('lodash')._

module.exports = class MySQLDynamoTable extends require( "./basic" )

	constructor: ( @_model_settings, options )->

		@mng = options.manager
		@external = options.external

		@getter "name", =>
			@_model_settings.name

		@getter "tableName", =>
			@_model_settings.name

		@getter "existend", =>
			@external?

		@getter "hasRange", =>
			if @_model_settings?.rangeKey?.length then true else false

		@getter "hashKey", =>
			@_model_settings?.hashKey or null

		@getter "hashKeyType", =>
			@_model_settings?.hashKeyType or "S"

		@getter "hashKeyLength", =>
			@_model_settings?.hashKeyLength or if @hashKeyType is "N" then 5 else 255


		@getter "rangeKey", =>
			@_model_settings?.rangeKey or null

		@getter "rangeKeyType", =>
			if @hasRange
				@_model_settings?.rangeKeyType or "N"
			else
				null

		@getter "rangeKeyLength", =>
			@_model_settings?.rangeKeyLength or if @rangeKeyType is "N" then 5 else 255

		super( options )
		return

	sql: =>
		@mng.sql.apply( @mng, arguments )

	initialize: =>
		@log "debug", "init table", @tableName, @hashKey, @rangeKey

		SQLBuilder = ( require( "./sql" ) )( logging: @config.logging )

		@builder = new SQLBuilder()
			
		@builder.table = @name
		
		@builder.hash =
			key: @hashKey
			type: @hashKeyType
			length: @hashKeyLength

		if @hasRange
			@builder.range =
				key: @rangeKey
				type: @rangeKeyType
				length: @rangeKeyLength
		
		@builder.setAttrs( _.clone( @_model_settings.attributes ) )

		if @_model_settings.defaultfields?
			@builder.fields = @_model_settings.defaultfields
		return

	generate: ( cb )=>
		if not @existend
			# create table
			@_generate cb
		else
			# table already existing
			@emit( "create-status", "already-active" )
			cb( null, false )
		return

	_generate: ( cb )=>

		statement = @builder.create()

		@sql statement, ( err, result )=>
			@log "debug", "table generated", statement, err, result 
			if err
				cb( err )
				return

			@external = 
				name: @name
				rows: 0

			cb( null, @external )
			return
		return

	get: ( args..., cb )=>
		if @_isExistend( cb )
			options = null
			switch args.length
				when 1
					[ _id ] = args
				when 2
					[ _id, options ] = args

			options = @_getOptions( options )
			
			
			sql = @builder.clone()

			sql.fields = options.fields if options.fields?
			sql.forward = if options.forward? then options.forward else true
			sql.limit = if options.limit? then options.limit else 1000

			_query = @_deFixHash( _id, cb )
			return unless _query?

			sql.filter( _query )

			@sql sql.query( false ), ( err, results )=>
				if err
					cb( err )
					return

				if results?.length
					_obj = @_postProcess( results[ 0 ] )
					@emit( "get", _obj )
					cb( null,  _obj )
				else
					@emit( "get-empty" )
					cb( null, null )
				return

		return

	mget: ( args..., cb )=>
		if @_isExistend( cb )
			options = null
			switch args.length
				when 1
					[ _ids ] = args
				when 2
					[ _ids, options ] = args

			options = @_getOptions( options )
			
			sql = @builder.clone()

			sql.fields = options.fields if options.fields?
			sql.forward = if options.forward? then options.forward else true
			sql.limit = if options.limit? then options.limit else 1000

			for _id in _ids
				_query = @_deFixHash( _id, cb )
				if _query?
					sql.or().filterGroup().filter( _query )

			_statement = sql.query( false )
			@log "debug", "mget", _ids, _statement

			@sql _statement, ( err, results )=>
				if err
					cb( err )
					return


				if results?.length
					_objs = []
					for _obj in results
					 	_objs.push( @_postProcess( _obj ) )
					@emit( "mget", _objs )
					cb( null, _objs )
				else
					@emit( "mget-empty" )
					cb( null, [] )
				return

		return

	find: ( args..., cb )=>

		if @_isExistend( cb )

			options = null
			startAt = null
			query = {}
			switch args.length
				when 1
					[ query ] = args
				when 2
					[ query, _x ] = args
					if _.isString( _x ) or _.isNumber( _x )
						startAt = _x
					else
						options = _x
				when 3
					[ query, startAt, options ] = args

			options = @_getOptions( options )

			if startAt?
				if @isRange
					@_handleError( cb, "startat-not-allowed" )
					return

				startAt = @_deFixHash( startAt, cb )

				if query[ @hashKey ]?
					_qHash = _.first( _.values( query[ @hashKey ] ) )

				if _qHash? and startAt[ @hashKey ] isnt _qHash
					@_handleError( cb, "invalid-startat-hash" )
					return

				query[ @rangeKey ] = { ">": startAt[ @rangeKey ] }

			@log "debug", "find", query, startAt, options

			sql = @builder.clone()
			sql.fields = options.fields if options.fields?
			sql.forward = if options.forward? then options.forward else true
			sql.limit = if options.limit? then options.limit else 1000

			sql.filter( query )
			_statement = sql.query()

			@sql _statement, ( err, result )=>
				if err
					cb( err )
					return
				@log "debug", "find query", _statement, result
				cb( null, result )
				return

		return

	set: ( args..., cb )=>
		if @_isExistend( cb )
			options = null

			switch args.length
				when 1
					_create = true
					_id = null
					[ attributes ] = args
				when 2
					if _.isString( args[ 0 ] ) or _.isNumber( args[ 0 ] ) or _.isArray( args[ 0 ] )
						_create = false
						[ _id, attributes ] = args
					else
						_create = true
						_id = null
						[ attributes, options ] = args
				when 3
					_create = false
					[ _id, attributes, options ] = args
			
			options = @_getOptions( options )

			sql = @builder.clone()

			@_validateAttributes _create, attributes, ( err, attributes )=>
				if err
					cb( err )
					return

				if _create
					@_createId attributes, ( err, attributes )=>
						@log "debug", "create a item", attributes, options
						
						sql.fields = options.fields if options.fields?
						
						statements = [ sql.insert( attributes ) ]

						sqlGet = @builder.clone()

						_query = {}
						if @hasRange
							_query[ @hashKey ] = attributes[ @hashKey ]
							_query[ @rangeKey ] = attributes[ @rangeKey ]
						else
							_query[ @hashKey ] = attributes[ @hashKey ]
						sqlGet.filter( _query )

						statements.push sqlGet.query( false )

						@sql statements, ( err, results )=>
							@log "info", "insert", err,results
							if err
								if err.code is "ER_DUP_ENTRY"
									@_handleError( cb, "conditional-check-failed" )
									return
								cb( err )
								return
							[ _meta, _inserted ] = results
							if _inserted?.length
								_obj = @_postProcess( _inserted[ 0 ] )
								@log "debug", "insert", statements, _obj
								
								@emit( "create", _obj )
								cb( null, _obj )
							else 
								cb( null, null )
							return
						return

				else
					
					@log "debug", "update a item", _id, attributes, options
					
					sql.fields = options.fields if options.fields?

					_query = @_deFixHash( _id, cb )
					return unless _query?

					sql.filter( _query )

					_select = sql.query( false )

					if options.conditionals?
						sql.filter( options.conditionals )

					statements = [ sql.update( attributes ), _select ]

					@sql statements, ( err, results )=>
						if err
							cb( err )
							return

						@log "debug", "update", results

						[ _meta, _updated ] = results
						if _meta.affectedRows <= 0
							@_handleError( cb, "conditional-check-failed" )
							return

						if _updated?.length
							_obj = @_postProcess( _updated[ 0 ] )  
							
							@emit( "update", _obj )

							cb( null, _obj )
						else 
							cb( null, null )
						return
				return
		return

	del: ( _id, cb )=>
		[ args..., cb ] = arguments
		[ _id, options ] = args

		options or= {}
		
		if @_isExistend( cb )
			_query = @_deFixHash( _id, cb )
			return unless _query?

			_statements = []

			sql = @builder.clone()

			sql.fields = options.fields if options.fields?
			sql.filter( _query )
			_statements = [ sql.query( false ),sql.del() ]

			@sql _statements, ( err, results )=>
				if err
					cb( err )
					return
				[ _meta, _deleted ] = results
				@log "debug", "deleted", _meta, _deleted
				if _deleted?.length
					_obj = @_postProcess( _deleted[ 0 ] )
					@emit( "delete", _deleted )
					cb( null,  _obj )
				else
					@emit( "del-empty" )
					cb( null, null )
				return


		return


	_isExistend: ( cb )=>
		if @existend
			true
		else 
			if _.isFunction( cb )
				# table not existend
				@_handleError( cb, "table-not-created", tableName: @tableName )
			false

	_getOptions: ( options = {} )=>
		_defOpt =
			fields: if @_model_settings.defaultfields? then @_model_settings.defaultfields else null
			forward: if @_model_settings.forward? then @_model_settings.forward else true
			
		_.extend( _defOpt, options or {} )


	_deFixHash: ( attrs, cb )=>
		
		if _.isString( attrs ) or _.isNumber( attrs ) or _.isArray( attrs )
			_hName = @hashKey
			_attrs = {}
			_attrs[ _hName ] = _.clone( attrs )
		else
			_attrs = _.clone( attrs )
		
		if @hasRange
			_hType = @hashKeyType
			_rName = @rangeKey
			_rType = @rangeKeyType

			if not _.isArray( _attrs[ _hName ] )

				@_handleError( cb, "invalid-range-call" )
				return

			[ _h, _r ] = _attrs[ _hName ]
			_attrs[ _hName ] =  @_convertValue( _h, _hType )
			_attrs[ _rName ] =  @_convertValue( _r, _rType )

		_attrs

	_convertValue: ( val, type )=>
		switch type.toUpperCase()
			when "N", "numeric"
				parseFloat( val, 10 )
			when "S", "string"
				val.toString( val ) if val
			else
				val

	_validateAttributes: ( isCreate, attrs, cb )=>
		_omit = []
		for _k, _v of attrs
			attrs[ _k ] = null if not _.isNumber( _v ) and _.isEmpty( _v )

		@log "debug", "_validateAttributes",  attrs, _omit

		cb( null, attrs )
		return

	_postProcess: ( attrs )=>
		# convert set to array
		_arrayKeys = @builder.attrArrayKeys
		if _arrayKeys.length
			for _aKey in _arrayKeys
				if attrs[ _aKey ]?
					attrs[ _aKey ] = @builder.setToArray( attrs[ _aKey ] ) 

		# remove empty attributes
		_omit = []
		for _k, _v of attrs
			_omit.push( _k ) if not _.isNumber( _v ) and _.isEmpty( _v )
		attrs = _.omit( attrs, _omit )

		attrs

	_createId: ( attributes, cb )=>
		@_createHashKey attributes, ( attributes )=>

			# create range attribute if defined in shema
			if @hasRange
				@_createRangeKey attributes, ( attributes )=>
					cb( null, attributes )
					return
			else
				cb( null, attributes )
			return

		return

	_createHashKey: ( attributes, cbH )=>
		_hName = @hashKey
		_hType = @hashKeyType

		if @_model_settings.fnCreateHash and _.isFunction( @_model_settings.fnCreateHash )
			@_model_settings.fnCreateHash attributes, ( _hash )=>
				attributes[ _hName ] = @_convertValue( _hash, _hType )
				cbH( attributes )
				return

		else if attributes[ _hName ]?
			# check the type
	
			attributes[ _hName ] = @_convertValue( attributes[ _hName ], _hType )
			cbH( attributes )

		else
			# create default id as uuid if not defined by attributes
			attributes[ _hName ] = @_convertValue( @_defaultHashKey(), _hType )
			cbH( attributes )

		return

	_createRangeKey: ( attributes, cbR )=>
		_rName = @rangeKey
		_rType = @rangeKeyType
		
		if @_model_settings.fnCreateRange and _.isFunction( @_model_settings.fnCreateRange )
			@_model_settings.fnCreateRange attributes, ( __range )=>
				attributes[ _rName ] = @_convertValue( __range, _rType )
				cbR( attributes )
				return

		else if attributes[ _rName ]?
			# check the type
	
			attributes[ _rName ] = @_convertValue( attributes[ _rName ], _rType )
			cbR( attributes )

		else
			# create default range as timestamp if not defined by attributes
			attributes[ _rName ] = @_convertValue( @_defaultRangeKey(), _rType )
			cbR( attributes )

		return

	_defaultHashKey: =>
		uuid.v1()

	_defaultRangeKey: =>
		Date.now()


	ERRORS: =>
		@extend super, 
			"invalid-startat-hash": "The `startAt` has to be equal a queried hash."
			"startat-not-allowed": "`startAt` value is only allowed for range tables"
			"conditional-check-failed": "This is not a valid request. It doesnt match the conditions or you tried to insert a existing hash."
			"table-not-created": "Table '<%= tableName %>' not existend at AWS. please run `Table.generate()` or `Manager.generateAll()` first."
			"invalid-range-call": "If you try to access a hash/range item you have to pass a Array of `[hash,range]` as id."