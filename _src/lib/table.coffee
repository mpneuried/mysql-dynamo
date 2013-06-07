# import the external modules
uuid = require 'node-uuid'
_ = require('lodash')._

# # MySQL Dynamo Table
# ### extends [Basic](basic.coffee.html)

# Work with the data of a table
module.exports = class MySQLDynamoTable extends require( "./basic" )

	# define the defaults
	defaults: =>
		# extend the parent defaults
		@extend super,
			# **tablePrefix** *String* Option to prefix all generating tables
			tablePrefix: null

	###	
	## constructor 

	`new MySQLDynamoTable( _model_settings, options )`
	
	Define the getter and setter and configure teh table.

	@param {Object} _model_settings Model configuration.
	@param {Object} options Basic config object

	###
	constructor: ( @_model_settings, options )->

		# set internal values
		@mng = options.manager
		@external = options.external

		# define the getters
		@getter "name", =>
			@_model_settings.name

		@getter "tableName", =>
			( options.tablePrefix or "" ) + @_model_settings.name

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

	# # Public methods

	###
	## sql
	
	`table.sql( statement[, args], cb )`
	
	shortcut to the `manager.sql()` method

	@param { String|Array } statement A MySQL SQL statement or an array of multiple statements
	@param { Array|Object } [args] Query arguments to auto escape. The arguments will directly passed to the `mysql.query()` method from [node-mysql](https://github.com/felixge/node-mysql#escaping-query-values)
	@param { Function } cb Callback function 
	
	@api public
	###
	sql: =>
		@mng.sql.apply( @mng, arguments )


	###
	## initialize
	
	`table.initialize()`
	
	Initialize the Table object
	
	@api private
	###
	initialize: =>
		@log "debug", "init table", @tableName, @hashKey, @rangeKey

		SQLBuilder = ( require( "./sql" ) )( logging: @config.logging )

		@builder = new SQLBuilder()
			
		@builder.table = @tableName
		
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

	###
	## generate
	
	`table.generate( cb )`
	
	Generate the table within the DB if not existend
	
	@param { Function } cb Callback function 
	
	@api public
	###
	generate: ( cb )=>
		if not @existend
			# create table
			@_generate cb
		else
			# table already existing
			@emit( "create-status", "already-active" )
			cb( null, false )
		return

	###
	## get
	
	`table.get( id[, options], cb )`
	
	Get a single element
	
	@param { String|Number|Array } id The id of an element. If the used table is a range table you have to use an array `[hash,range]` as combined id.
	@param { Object } [options] Options. See the [docs](http://mpneuried.github.io/mysql-dynamo/) for more information.
	@param { Function } cb Callback function 
	
	@api public
	###
	get: ( args..., cb )=>
		if @_isExistend( cb )

			# dispatch the arguments
			options = null
			switch args.length
				when 1
					[ _id ] = args
				when 2
					[ _id, options ] = args

			# get the standard options
			options = @_getOptions( options )
			
			# clone the SqlBuilder Instance
			sql = @builder.clone()

			# set the options
			sql.fields = options.fields if options.fields?
			sql.forward = if options.forward? then options.forward else true
			sql.limit = if options.limit? then options.limit else 1000

			# get the hash or hash/range query
			_query = @_deFixHash( _id, cb )
			return unless _query?

			# set the filter
			sql.filter( _query )

			# execute the query
			@sql sql.select( false ), ( err, results )=>
				if err
					cb( err )
					return

				if results?.length
					# postprocess the results
					_obj = @_postProcess( results[ 0 ] )
					@emit( "get", _obj )
					cb( null,  _obj )
				else
					@emit( "get-empty" )
					cb( null, null )
				return

		return

	###
	## mget
	
	`table.mget( ids,[, options], cb )`
	
	Get multiple elements at once
	
	@param { Array } ids An array of id of an elements. If the used table is a range table you have to use an array of arrays `[hash,range]` as combined id.
	@param { Object } [options] Options. See the [docs](http://mpneuried.github.io/mysql-dynamo/) for more information.
	@param { Function } cb Callback function 
	
	@api public
	###
	mget: ( args..., cb )=>
		if @_isExistend( cb )

			# dispatch the arguments
			options = null
			switch args.length
				when 1
					[ _ids ] = args
				when 2
					[ _ids, options ] = args

			# get the standard options
			options = @_getOptions( options )
			
			# clone the SqlBuilder Instance
			sql = @builder.clone()

			# set the options
			sql.fields = options.fields if options.fields?
			sql.forward = if options.forward? then options.forward else true
			sql.limit = if options.limit? then options.limit else 1000

			# loop through the ids and add the filters to the SqlBuilder
			for _id in _ids
				_query = @_deFixHash( _id, cb )
				if _query?
					sql.or().filterGroup().filter( _query )

			# execute the query
			_statement = sql.select( false )
			@log "debug", "mget", _ids, _statement

			@sql _statement, ( err, results )=>
				if err
					cb( err )
					return


				if results?.length
					# postprocess every single results results
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

	###
	## find
	
	`table.find( query[, startAt][, options], cb )`
	
	Find elements in a table
	
	@param { Object } query A query object. How to build … have a look at [Jed's Predicates ](https://github.com/jed/dynamo/wiki/High-level-API#wiki-predicates)
	@param { String|Number|Array } [startAt] To realize a paging you can define a `startAt`. Usually the last item of a list. If you define `startAt` with the last item of the previous find you get the next collection of items without the given `startAt` item.  
If the used table is a range table you have to use an array `[hash,range]` as combined `startAt`.
	@param { Object } [options] Options. See the [docs](http://mpneuried.github.io/mysql-dynamo/) for more information.
	@param { Function } cb Callback function 

	@api public
	###
	find: ( args..., cb )=>

		if @_isExistend( cb )

			# dispatch the arguments
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

			# get the standard options
			options = @_getOptions( options )

			# clone the SqlBuilder Instance
			sql = @builder.clone()

			# check the startAt argument and create a predicate like query
			if startAt?
				# abort if start at is used for a hash table
				if @isRange
					@_handleError( cb, "startat-not-allowed" )
					return

				# get the hash or hash/range query from the `startAt`
				startAt = @_deFixHash( startAt, cb )

				# get the hash value
				if query[ @hashKey ]?
					_qHash = _.first( _.values( query[ @hashKey ] ) )

				# check if the `startAt` hash matches a possible hash within the query
				if _qHash? and startAt[ @hashKey ] isnt _qHash
					@_handleError( cb, "invalid-startat-hash" )
					return

				# generate the start at predicate
				query[ @rangeKey ] = { ">": startAt[ @rangeKey ] }

			@log "debug", "find", query, startAt, options

			# set the options
			sql.fields = options.fields if options.fields?
			sql.forward = if options.forward? then options.forward else true
			sql.limit = if options.limit? then options.limit else 1000

			# execute the query
			sql.filter( query )
			_statement = sql.select()

			@sql _statement, ( err, results )=>
				if err
					cb( err )
					return
				@log "debug", "find query", _statement, results

				if results?.length
					# postprocess every single results results
					_objs = []
					for _obj in results
					 	_objs.push( @_postProcess( _obj ) )
					cb( null, _objs )
				else
					cb( null, [] )
				return

		return

	###
	## set
	
	`table.set( [ id,] data,[ options,] fnCallback  )`
	
	Insert or update an item. If the first argument is defined ist used as a update otherwise as a insert.
	
	@param { String|Number|Array } [id] If this argument is defined the `set` will be executed as a update otherwise as a insert. The id of an element. If the used table is a range table you have to use an array [hash,range] as combined id.
	@param { Object } data The data to update or insert.
	@param { Object } [options] Options. See the [docs](http://mpneuried.github.io/mysql-dynamo/) for more information.
	@param { Function } cb Callback function 
	
	@api public
	###
	set: ( args..., cb )=>
		if @_isExistend( cb )

			# dispatch the arguments
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
			
			# get the standard options
			options = @_getOptions( options )

			# clone the SqlBuilder Instance
			sql = @builder.clone()

			# set the options				
			sql.fields = options.fields if options.fields?

			# validate the attribute to remove arguments not defined in the list of columns
			@_validateAttributes _create, attributes, ( err, attributes )=>
				if err
					cb( err )
					return

				if _create

					# generate a new id
					@_createId attributes, ( err, attributes )=>
						@log "debug", "create a item", attributes, options
						
						# create the sql statement for insert
						statements = [ sql.insert( attributes ) ]

						# clone the SqlBuilder Instance
						sqlGet = @builder.clone()

						# generate the query to return the inserted element after insert
						_query = {}
						if @hasRange
							_query[ @hashKey ] = attributes[ @hashKey ]
							_query[ @rangeKey ] = attributes[ @rangeKey ]
						else
							_query[ @hashKey ] = attributes[ @hashKey ]
						sqlGet.filter( _query )

						statements.push sqlGet.select( false )

						# execute the query
						@sql statements, ( err, results )=>
							@log "info", "insert", err,results
							if err
								# check for a special error and rewrite it
								if err.code is "ER_DUP_ENTRY"
									@_handleError( cb, "conditional-check-failed" )
									return
								cb( err )
								return

							[ _meta, _inserted ] = results
							if _inserted?.length
								# postprocess the result
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
					
					# get the hash or hash/range query
					_query = @_deFixHash( _id, cb )
					return unless _query?

					sql.filter( _query )

					# generate the result get query
					_select = sql.select( false )

					# add the conditionals to the update
					if options.conditionals?
						sql.filter( options.conditionals )

					# create the statement array
					statements = [ sql.update( attributes ), _select ]

					# execute the query
					@sql statements, ( err, results )=>
						if err
							cb( err )
							return

						@log "debug", "update", results

						[ _meta, _updated ] = results

						# if no rows has been effected the conditional has been failed
						if _meta.affectedRows <= 0
							@_handleError( cb, "conditional-check-failed" )
							return

						if _updated?.length
							# postprocess the result
							_obj = @_postProcess( _updated[ 0 ] )  
							
							@emit( "update", _obj )

							cb( null, _obj )
						else 
							cb( null, null )
						return
				return
		return

	###
	## del
	
	`table.del( id, cb )`
	
	Delete a single element
	
	@param { String|Number|Array } id The id of an element. If the used table is a range table you have to use an array `[hash,range]` as combined id. Otherwise you will get an error. 
	@param { Function } cb Callback function 
	
	@api public
	###
	del: ( _id, cb )=>
		[ args..., cb ] = arguments
		[ _id, options ] = args

		options or= {}
		
		if @_isExistend( cb )
			_query = @_deFixHash( _id, cb )
			return unless _query?


			# clone the SqlBuilder Instance
			sql = @builder.clone()

			# set the options	
			sql.fields = options.fields if options.fields?

			# define the filter
			sql.filter( _query )
			_statements = [ sql.select( false ),sql.del() ]

			# execute the query
			@sql _statements, ( err, results )=>
				if err
					cb( err )
					return
				[ _meta, _deleted ] = results

				@log "debug", "deleted", _meta, _deleted
				if _deleted?.length
					# postprocess the result
					_obj = @_postProcess( _deleted[ 0 ] )
					@emit( "delete", _deleted )
					cb( null,  _obj )
				else
					@emit( "del-empty" )
					cb( null, null )
				return
		return

	###
	## destroy
	
	`table.destroy( cb )`
	
	Destroy this table with all data
	
	@param { Function } cb Callback function 
	
	@api public
	###
	destroy: ( cb )=>
		if @_isExistend()

			# clone the SqlBuilder Instance
			sql = @builder.clone()

			@sql sql.drop(), ( err, meta )=>
				if err
					cb( err )
					return
				@emit( "destroy", @ )
				@external = null
				cb( null, meta )
				return
		else
			cb( null, null )
		return

	# # Private methods

	###
	## _generate
	
	`table._generate( cb )`
	
	Run the create table sql query
	
	@param { Function } cb Callback function 
	
	@api private
	###
	_generate: ( cb )=>

		# generate the crate statement and execute it
		statement = @builder.create()

		@sql statement, ( err, result )=>
			@log "warning", "table `#{ @tableName }` generated"
			if err
				cb( err )
				return

			# set the default table infos
			@external = 
				name: @tableName
				rows: 0

			cb( null, @external )
			return
		return

	###
	## _isExistend
	
	`table._isExistend( [cb] )`
	
	Check if this tabel exists within the DB
	
	@param { Function } [cb] Callback method to answer with an error if defined
	
	@return { Boolean } Table exists 
	
	@api private
	###
	_isExistend: ( cb )=>
		if @existend
			true
		else 
			if _.isFunction( cb )
				# table not existend
				@_handleError( cb, "table-not-created", tableName: @tableName )
			false

	###
	## _getOptions
	
	`table._getOptions( [options] )`
	
	Get the default options
	
	@param { Object } [options={}] The argument options to overwrite the defaults
	
	@return { Object } Extended options 
	
	@api private
	###
	_getOptions: ( options = {} )=>
		# set the default options out of the model settings
		_defOpt =
			fields: if @_model_settings.defaultfields? then @_model_settings.defaultfields else null
			forward: if @_model_settings.forward? then @_model_settings.forward else true
			
		_.extend( _defOpt, options or {} )


	###
	## _deFixHash
	
	`table._deFixHash( attrs, cb )`
	
	Convert a hash or hash/range id to a query
	
	@param { String|Number|Array|Object } attrs The id to convert 
	@param { Function } cb Callback method to answer with an error
	
	@return { Object } The generated query 
	
	@api private
	###
	_deFixHash: ( attrs, cb )=>
		
		# dispatch the id
		if _.isString( attrs ) or _.isNumber( attrs ) or _.isArray( attrs )
			_hName = @hashKey
			_attrs = {}
			_attrs[ _hName ] = _.clone( attrs )
		else
			_attrs = _.clone( attrs )
		
		# if it's a range table convert generate a complexer query to get a element by a combined identifier
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

	###
	## _convertValue
	
	`table._convertValue( val, type )`
	
	Convert values to the defined type
	
	@param { Any } val The value to convert 
	@param { String } type The type 
	
	@return { Any } The converted value 
	
	@api private
	###
	_convertValue: ( val, type )=>
		switch type.toUpperCase()
			when "N", "numeric"
				parseFloat( val, 10 )
			when "S", "string"
				val.toString( val ) if val
			else
				val

	###
	## _validateAttributes
	
	`table._validateAttributes( isCreate, attrs, cb )`
	
	remove attributes that are not defined as table column
	
	@param { Boolean } isCreate This is a validation for create call 
	@param { Object } attrs The attributtes to validate
	@param { Function } cb Callback function 
	
	@api private
	###
	_validateAttributes: ( isCreate, attrs, cb )=>
		_omit = []
		for _k, _v of attrs
			attrs[ _k ] = null if not _.isNumber( _v ) and _.isEmpty( _v )

		@log "debug", "_validateAttributes",  attrs, _omit

		cb( null, attrs )
		return

	###
	## _postProcess
	
	`table._postProcess( attrs )`
	
	Remove empty columns to act like dynamo and convert set columns to an array
	
	@param { Object } attrs The element to process 
	
	@return { Object } The processed object 
	
	@api private
	###
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

	###
	## _createId
	
	`table._createId( attributes, cb )`
	
	Generate an new id. it will be a hash or a combination of hash/range and return the changed attributes
	
	@param { Obejct } attributes The attributes to insert 
	@param { Function } cb Callback function 
	
	@api private
	###
	_createId: ( attributes, cb )=>

		# get or generate the hash key
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

	###
	## _createHashKey
	
	`table._createHashKey( attributes, cbH )`
	
	Get or generate a new hash.
	
	@param { Object } attributes The attributes to insert  
	@param { Function } cbH Callback function 
	
	@api private
	###
	_createHashKey: ( attributes, cbH )=>
		# cache the hash configs
		_hName = @hashKey
		_hType = @hashKeyType

		if @_model_settings.fnCreateHash and _.isFunction( @_model_settings.fnCreateHash )
			# if a `fnCreateHash` method is defined in the model settings run it
			@_model_settings.fnCreateHash attributes, ( _hash )=>
				attributes[ _hName ] = @_convertValue( _hash, _hType )
				cbH( attributes )
				return


		else if attributes[ _hName ]?
			# if a hash is define within the attributes check and set it
			attributes[ _hName ] = @_convertValue( attributes[ _hName ], _hType )
			cbH( attributes )

		else
			# create default id as uuid if not defined by attributes
			attributes[ _hName ] = @_convertValue( @_defaultHashKey(), _hType )
			cbH( attributes )

		return
	###
	## _createRangeKey
	
	`table._createRangeKey( attributes, cbR )`
	
	Get or generate a new range.
	
	@param { Object } attributes The attributes to insert  
	@param { Function } cbR Callback function 
	
	@api private
	###
	_createRangeKey: ( attributes, cbR )=>
		# cache the range configs
		_rName = @rangeKey
		_rType = @rangeKeyType
		
		if @_model_settings.fnCreateRange and _.isFunction( @_model_settings.fnCreateRange )
			# if a `fnCreateRange` method is defined in the model settings run it
			@_model_settings.fnCreateRange attributes, ( __range )=>
				attributes[ _rName ] = @_convertValue( __range, _rType )
				cbR( attributes )
				return

		else if attributes[ _rName ]?
			# if a range is define within the attributes check and set it
			attributes[ _rName ] = @_convertValue( attributes[ _rName ], _rType )
			cbR( attributes )

		else
			# create default range as timestamp if not defined by attributes
			attributes[ _rName ] = @_convertValue( @_defaultRangeKey(), _rType )
			cbR( attributes )

		return

	###
	## _defaultHashKey
	
	`table._defaultHashKey()`
	
	Generate a default hash
	
	@return { String } A uuid as defaul hash 
	
	@api private
	###
	_defaultHashKey: =>
		uuid.v1()

	###
	## _defaultRangeKey
	
	`table._defaultRangeKey()`
	
	Generate a default range key
	
	@return { Number } The current timestamp as default range key
	
	@api private
	###
	_defaultRangeKey: =>
		Date.now()

	# # Error message mapping
	ERRORS: =>
		@extend super, 
			"invalid-startat-hash": "The `startAt` has to be equal a queried hash."
			"startat-not-allowed": "`startAt` value is only allowed for range tables"
			"conditional-check-failed": "This is not a valid request. It doesnt match the conditions or you tried to insert a existing hash."
			"table-not-created": "Table '<%= tableName %>' not existend at AWS. please run `Table.generate()` or `Manager.generateAll()` first."
			"invalid-range-call": "If you try to access a hash/range item you have to pass a Array of `[hash,range]` as id."