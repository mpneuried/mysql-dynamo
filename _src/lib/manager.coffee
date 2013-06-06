# import the external modules
_ = require('lodash')._
mysql = require 'mysql'

# import the internal modules
Table = require "./table"
utils = require( "./utils" )

# # MySQL Dynamo Manager
# ### extends [Basic](basic.coffee.html)

# Manager to organize the tables and connections
module.exports = class MySQLDynamoManager extends require( "./basic" )

	# define the defaults
	defaults: =>
		# extend the parent defaults
		@extend super,
			# the mysql driver pooling options
			
			# **host** *String* MySQL server host
			host: 'localhost'
			# **user** *String* MySQL server user
			user: 'root'
			# **password** *String* MySQL server password
			password: 'secret'
			# **database** *String* MySQL database to work with
			database: "your-database"
			# **waitForConnections** *Boolean* Wait for connections if the poolsize has been reached
			waitForConnections: true
			# **connectionLimit** *Number* MySQL Connection poolsize
			connectionLimit: 10
			# **connectionLimit** *Number* MySQL maximim limit of queued querys if the poolsize has been reached. `0` = no limit
			queueLimit: 0

	###	
	## constructor 

	`new MySQLDynamoManager( options, tableSettings )`
	
	Define the configuration by options and defaults, and save the table settings.

	@param {Object} options Basic config object
	@param {Object} tableSettings Configuration of all tabels. For details see the [API docs](http://mpneuried.github.io/mysql-dynamo/)

	###
	constructor: ( options, @tableSettings )->
		super

	###
	## initialize
	
	`manager.initialize()`
	
	Initialize the MySQL pool

	@api private
	###
	initialize: =>
		# `multipleStatements` is required so overwrite it hard
		@pool = mysql.createPool @extend( {}, @config, { multipleStatements: true } )
		
		# set the internal flags
		@connected = false
		@fetched = false
		@_dbTables = {}
		@_tables = {}

		@log "debug" , "initialized"
		return

	# # Public methods

	###
	## sql
	
	`manager.sql( statement[, args], cb )`
	
	Run a sql query by using a connection from the pool
	
	@param { String|Array } statement A MySQL SQL statement or an array of multiple statements
	@param { Array|Object } [args] Query arguments to auto escape. The arguments will directly passed to the `mysql.query()` method from [node-mysql](https://github.com/felixge/node-mysql#escaping-query-values)
	@param { Function } cb Callback function 
	
	@api public
	###
	sql: =>
		[ args..., cb ] = arguments

		@log "info" , "run query", args

		# if statements is an Array concat them to a multi statement
		if _.isArray( args[ 0 ] )
			args[ 0 ] = args[ 0 ].join( ";\n" )
		
		# get a connection from the pool
		@pool.getConnection ( err, conn )=>
			if err
				cb( err )
				return

			# define the return method to release the connection
			args.push =>
				conn.end()
				cb.apply( @, arguments )
				return
			# run the query with `node-mysql`
			conn.query.apply( conn, args )
			return
		return

	###
	## connect
	
	`manager.connect( cb )`
	
	Connect to the database and check the currently existing tables

	@param { Function } cb Callback function 
	
	@api public
	###
	connect: ( cb )=>
		
		# fetch the existing tables
		@_fetchTables ( err )=>
			if err
				cb err
			else
				# init the defined tables
				@_initTables( null, cb )
			return
		return

	###
	## list
	
	`manager.list( cb )`
	
	List all existing db tables
	
	@param { Function } cb Callback function 
	
	@api public
	###
	list: ( cb )=>
		@_fetchTables ( err )=>
			if err
				cb err
			else
				cb null, Object.keys( @_tables )
			return
		return

	###
	## get
	
	`manager.get( tableName )`
	
	Get a [Table](table.coffee.html) by name
	
	@param { String } tableName Table name to get 
	
	@return { Table } The found [Table](table.coffee.html) object or `null` 
	
	@api public
	###
	get: ( tableName )=>
		tableName = tableName.toLowerCase()
		if @has( tableName )
			@_tables[ tableName ]
		else
			null

	###
	## has
	
	`manager.has( tableName )`
	
	Check for a defined table
	
	@param { String } tableName Table name 
	
	@return { Boolean } Table exists 
	
	@api public
	###
	has: ( tableName )=>
		tableName = tableName.toLowerCase()
		@_tables[ tableName ]?

	###
	## generateAll
	
	`manager.generateAll( cb )`
	
	Generate all not exiting tables in the DB
	
	@param { Function } cb Callback function 
	
	@api public
	###
	generateAll: ( cb )=>
		aCreate = []
		for _n, table of @_getTablesToGenerate()
			aCreate.push _.bind( ( tableName, cba )->
				
				@generate tableName, ( err, generated )=>
					cba( err, generated )
					return
				
				return
				
			, @, table.name )

		utils.runSeries aCreate, ( err, _generated )=>
			if utils.checkArray( err )
				cb err
			else
				@emit( "all-tables-generated" )
				cb null
			return

		return

	###
	## generate
	
	`manager.generate( tableName, cb )`
	
	Generate a single DB table if not existend
	
	@param { String } tableName Table name 
	@param { Function } cb Callback function 
	
	@api public
	###
	generate: ( tableName, cb )=>
		tbl = @get tableName

		if not tbl
			@_handeError( cb, "table-not-found", tableName: tableName )
		else

			tbl.generate ( err, generated )=>
				if err
					cb err
					return 

				@emit( "table-generated", generated )

				cb( null, generated )

				return
			return
		return

	# # Private methods

	###
	## _fetchTables
	
	`manager._fetchTables( cb )`
	
	Fetch the currently existing tables. This is primary done to match the [simple-dynamo API](http://mpneuried.github.io/simple-dynamo/)
	
	@param { Function } cb Callback function 
	
	@api private
	###
	_fetchTables: ( cb )=>
		statement = "SELECT table_name as name, table_rows as rows FROM information_schema.tables WHERE  table_schema = database()"
		# allways fetch tables on a call
		@sql statement, ( err, results )=>
			if err
				cb( err )
			else
				for table in results
					@_dbTables[ table.name ] = table
				@log "debug", "fetched db tables", @_dbTables
				@fetched = true
				cb( null, true )
			return
		return

	###
	## _initTables
	
	`manager._initTables( tables, cb )`
	
	Initialize the [Table](table.coffee.html) objects defined within the table configuration
	
	@param { Object } [tables=@tableSettings] The Table settings. If `null` it uses the configured tables 
	@param { Function } cb Callback function 
	
	@api private
	###
	_initTables: ( tables = @tableSettings, cb )=>
		if @fetched

			# loop through the tables
			for tableName, table of tables
				# convert it to lowercase to handle them not case sensitive
				tableName = tableName.toLowerCase()
				# destroy existing table
				if @_tables[ tableName ]?
					delete @_tables[ tableName ]
				
				# generate a [Table](table.coffee.html) object for each table-element out of @tableSettings
				_ext = @_dbTables[ table.name ]
				_opt = 
					manager: @
					external: _ext
					logging: @config.logging

				@_tables[ tableName ] = new Table( table, _opt )
				@emit( "new-table", tableName, @_tables[ tableName ] )

			@connected = true
			cb( null )

		else
			@_handeError( cb, "no-tables-fetched" )

		return

	###
	## _getTablesToGenerate
	
	`manager._getTablesToGenerate(  )`
	
	Calculate the tables that are defined but currently not exits in the DB
	
	@param { String }  Desc 
	@param { Function }  Callback function 
	
	@return { String } Return Desc 
	
	@api private
	###
	_getTablesToGenerate: =>
		_ret = {}
		for _n, tbl of @_tables
			if not _ret[ tbl.tableName ]?
				_ret[ tbl.tableName ] = 
					name: _n
					tableName: tbl.tableName

		_ret

	# # Error message mapping
	ERRORS: =>
		@extend super, 
			"no-tables-fetched": "Currently not tables fetched. Please run `Manager.connect()` first."
			"table-not-found": "Table `<%= tableName %>` not found."