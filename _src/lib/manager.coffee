_ = require('lodash')._

mysql = require 'mysql'
Table = require "./table"

module.exports = class MySQLDynamoManager extends require( "./basic" )

	defaults: =>
		@extend super
			# the mysql driver pooling options
			host: 'localhost'
			user: 'root'
			password: 'secret'
			database: "your-database"
			multipleStatements: false
			waitForConnections: true
			connectionLimit: 10
			queueLimit: 0

	constructor: ( options, @tableSettings )->
		super

	initialize: =>
		@pool = mysql.createPool @config
		
		# set the 
		@connected = false
		@fetched = false
		@_dbTables = {}
		@_tables = {}

		@log "debug" , "initialized"
		return

	sql: =>
		[ args..., cb ] = arguments

		@log "debug" , "run query", args
		
		@pool.getConnection ( err, conn )=>
			if err
				cb( err )
				return

			args.push =>
				conn.end()
				cb.apply( @, arguments )
				return
			conn.query.apply( conn, args )
			return
		return

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

	_fetchTables: ( cb )=>
		statement = "SELECT table_name as name, table_rows as rows, index_length FROM information_schema.tables WHERE  table_schema = database()"
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

	_initTables: ( tables = @tableSettings, cb )=>
		if @fetched

			for tableName, table of tables
				tableName = tableName.toLowerCase()
				# destroy existing table
				if @_tables[ tableName ]?
					delete @_tables[ tableName ]
				
				# generate a Table Object for each table-element out of @tableSettings
				_ext = @_dbTables[ table.name ]
				_opt = _.extend {},
					manager: @
					external: _ext
					logging: @config.logging

				@_tables[ tableName ] = new Table( table, _opt )
				@emit( "new-table", tableName, @_tables[ tableName ] )

			@connected = true
			cb( null )

		else
			error = new Error
			error.name = "no-tables-fetched"
			error.message = "Currently not tables fetched. Please run `Manager.connect()` first."
			cb( error )

		return

	list: ( cb )=>
		@_fetchTables ( err )=>
			if err
				cb err
			else
				cb null, Object.keys( @_tables )
			return
		return

	get: ( tableName )=>
		tableName = tableName.toLowerCase()
		if @has( tableName )
			@_tables[ tableName ]
		else
			null

	has: ( tableName )=>
		tableName = tableName.toLowerCase()
		@_tables[ tableName ]?

	_getTablesToGenerate: =>
		_ret = {}
		for _n, tbl of @_tables
			if not _ret[ tbl.tableName ]?
				_ret[ tbl.tableName ] = 
					name: _n
					tableName: tbl.tableName

		_ret

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

	generate: ( tableName, cb )=>
		tbl = @get tableName

		if not tbl
			error = new Error
			error.name = "table-not-found"
			error.message = "Table `#{ tableName }` not found."
			cb( error )
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


	ERRORS: =>
		@extend super, 
			"no-tables-fetched": "Currently not tables fetched. Please run `Manager.connect()` first."