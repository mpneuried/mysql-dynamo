mysql = require 'mysql'
_ = require('lodash')._

module.exports = ( options )->
	return class SQLBuilder extends require( "./basic" )

		defaults: =>
			@extend super,
				fields: "*"
				limit: 1000
				hash:
					key: ""
					type: "S"
					required: true
					length: 5
					default: ""
					isHash: true
				range:
					key: ""
					type: "N"
					required: true
					length: 11
					default: 0
					isRange: true
				attr:
					key: ""
					type: "S"
					required: false
					length: 255

				sqlSetDelimiter: "|"
				standardFilterCombine: "AND"

		constructor: ( @_c = {} )->

			@_c.attrs or= []
			@_c.attrKeys or= []

			super( options )
			return

		initialize: =>
			@define( "table", @getTable, @setTable )

			@define( "hash", @getHash, @setHash )

			@getter( "hashkey", @getHashKey )

			@define( "range", @getRange, @setRange )

			@getter( "rangekey", @getRangeKey )

			@getter( "isRange", @_isRange )

			@define( "attrs", @getAttrs, @setAttrs )

			@getter( "attrKeys", @getAttrKeys )

			@define( "fields", @getFields, @setFields )

			@define( "limit", @getLimit, @setLimit )

			@define( "forward", @getForward, @setForward )

			@getter( "orderby", @getOrderBy )

			@getter( "orderfield", @getOrderField )

			@getter( "where", @getWhere )

			@log "debug", "initialized"

			return

		clone: =>
			@log "info", "run clone", Object.keys( @_c )
			return new SQLBuilder( _.clone( @_c ) )

		insert: ( attributes )=>

			statement = []
			statement.push "INSERT INTO #{ @table }"

			_keys = []
			_vals = []
			for _key, _val of attributes
				_cnf = @_getAttrConfig( _key )
				if _cnf
					switch _cnf.type
						when "string", "number", "S", "N"
							_keys.push( _key )
							_vals.push( mysql.escape( _val ) )
						when "array", "A"
							_keys.push( _key )
							_vals.push( @_generateSetCommand( _key, _val, @config.sqlSetDelimiter ) )
			statement.push( "( #{ _keys.join( ", " )} )" ) 
			statement.push( "VALUES ( #{ _vals.join( ", " ) } )" )
			return _.compact( statement ).join( "\n" )

		update: ( attributes )=>

			statement = []
			statement.push "UPDATE #{ @table }"

			_keys = []
			_vals = []
			for _key, _val of attributes
				_cnf = @_getAttrConfig( _key )
				if _cnf
					switch _cnf.type
						when "string", "number", "S", "N"
							_keys.push( _key )
							_vals.push( mysql.escape( _val ) )
						when "array", "A"
							_keys.push( _key )
							_vals.push( @_generateSetCommand( _key, _val, @config.sqlSetDelimiter ) )
			_sets = []
			for _key, _idx in _keys
				_sets.push( "#{ _key } = #{ _vals[ _idx ] }" ) 
			
			statement.push( "SET #{ _sets.join( ", " ) }" )

			statement.push @where

			return _.compact( statement ).join( "\n" )

		query: ( complex = true )=>

			statement = []
			statement.push "SELECT #{ @fields }"
			statement.push "FROM #{ @table }"

			statement.push @where

			if complex
				statement.push @orderby

				statement.push @limit

			return _.compact( statement ).join( "\n" )

		filter: ( key, pred )=>
			@_c.filters or= []
			@log "warning", "filter", key, pred
			if _.isObject( key )
				for _k, _pred of key
					@filter( _k, _pred )
			else
				_filter = "#{ key } "
				if not pred?
					_filter += "is NULL"
				else if _.isString( pred ) or _.isNumber( pred )
					_filter += "= #{ mysql.escape( pred ) }"
				else
					_operand = Object.keys( pred )[ 0 ]
					_val = pred[ _operand ]
					switch _operand
						when "=="
							_filter += if _val? then "= #{ mysql.escape( _val ) }" else "is NULL"
						when "!="
							_filter += if _val? then "!= #{ mysql.escape( _val ) }" else "is not NULL"
						when ">", "<"
							_filter += "#{ _operand } #{ mysql.escape( _val ) }"
						when ">", "<", "<=", ">="
							if _.isArray( _val )
								_filter += "between #{ mysql.escape( _val[ 0 ] ) } and #{ mysql.escape( _val[ 1 ] ) }"
							else
								_filter += "#{ _operand } #{ mysql.escape( _val ) }"
						when "contains"
							_filter += "like '#{ mysql.escape( "%" + _val + "%" ) }'"
						when "!contains"
							_filter += "not like '#{ mysql.escape( "%" + _val + "%" ) }'"
						when "startsWith"
							_filter += "like '#{ mysql.escape( _val + "%" ) }'"
						when "in"
							if not _.isArray( _val )
								_val = [ _val ]
							_filter += "in ( '#{ mysql.escape( _val ) }')"
				
				if @_c.filters?.length
					_cbn = if @_c._filterCombine then @_c._filterCombine else @config.standardFilterCombine
					@_c.filters.push _cbn

				@_c.filters.push( _filter )

				@_c._filterCombine = null

			@

		or: =>
			if @_c.filters?.length
				@_c._filterCombine = "OR"
			@

		and: =>
			if @_c.filters?.length			
				@_c._filterCombine = "AND"
			@

		filterGroup: ( newGroup = true )=>
			@_c.filters or= []
			_add = 0
			if @_c._filterGroup? and @_c._filterGroup >= 0
				@log "error", "filterGroup A", @_c.filters, @_c._filterGroup
				if @_c._filterGroup is 0
					@_c.filters.unshift( "(" )
				else
					@_c.filters.splice( @_c._filterGroup, 0, "(" )
				@_c.filters.push( ")" )
				_add = 1
				@log "error", "filterGroup B", @_c.filters, @_c._filterGroup
				@_c._filterGroup = null
			if newGroup
				@_c._filterGroup = ( @_c.filters?.length or 0 ) + _add
			@

		create: =>
			statement = []
			statement.push "CREATE TABLE #{ @table } ("

			defs = []

			for attr in @attrs
				defs.push @genRowCreate( attr )

			prim = "\nPRIMARY KEY ("
			prim += " `#{ @hash.key }` "
			prim += ", `#{ @range.key }` " if @isRange
			prim += ")"
			defs.push prim

			statement.push defs.join(", ")
			statement.push "\n) ENGINE=InnoDB DEFAULT CHARSET=utf8;"

			statement.join( " " )
		
		genRowCreate: ( opt )=>

			_opt = @extend( {}, @config.attr, opt )
			stmt = "\n`#{ _opt.key }` "
			isString = false
			isSet = false

			if _opt.type is "A" or _opt.type is "array"
				isSet = true
				stmt += "text"
			else if _opt.type is "S" or _opt.type is "string"
				isString = true
				if _opt.length is +Infinity
					stmt += "text "
				else
					stmt += "varchar(#{_opt.length}) "
			else
				if _opt.length > 11
					stmt += "bigint(#{_opt.length}) "
				else
					stmt += "int(#{_opt.length}) "

			if not isSet and _opt.required
				stmt += "NOT NULL "

			if not isSet and _opt.default?
				if isString
					stmt += "DEFAULT '#{ _opt.default }'"
				else
					stmt += "DEFAULT #{ _opt.default }"

			return stmt

		validateAttributes: ( isCreate, attrs, cb )=>
			attrs = _.pick( attrs, @attrKeys )
			@log "debug", "validateAttributes", attrs
			cb( null, attrs )
			return

	

	# Getter and Setter methods
	
		setTable: ( tbl )=>
			@_c.table = tbl
			return

		getTable: =>
			if @_c.table?
				@_c.table
			else
				@_handleError( null, "no-table" )

		setHash: ( _h )=>
			@_c.hash = {}
			@extend( @_c.hash, @config.hash, _h )
			@_c.attrs.push @_c.hash
			@_c.attrKeys.push @_c.hash.key
			return

		getHash: =>
			if @_c.hash?
				@_c.hash
			else
				@_handleError( null, "no-hash" )

		getHashKey: =>
			@hash.key

		setRange: ( _r )=>
			if _r?
				@_c.isRange = true
				@_c.range = {}
				@extend( @_c.range, @config.range, _r )
				@_c.attrs.push @_c.range
				@_c.attrKeys.push @_c.range.key
			else
				@_c.isRange = false
				_.omit( @_c, "range" )
			return

		getRange: =>
			@_c.range

		getRangeKey: =>
			if @isrange
				@range.key
			else
				null

		_isRange: =>
			if @_c.isRange? then @_c.isRange or false

		setAttrs: ( _attrs )=>
			for attr in _attrs
				if attr.key?
					@_c.attrKeys.push attr.key
					@_c.attrs.push @extend( {}, @config.attr, attr )
			return

		getAttrs: =>
			if @_c.attrs?
				@_c.attrs
			else
				[]

		getAttrKeys: =>
			@_c.attrKeys or []

		setForward: ( _forward = true )=>
			if _forward
				@_c.forward = true
			else
				@_c.forward = false
			return

		getForward: =>
			if @_c.forward?
				@_c.forward
			else
				true

		getOrderBy: =>
			if @forward
				"ORDER BY #{ @orderfield } ASC"
			else
				"ORDER BY #{ @orderfield } DESC"	


		getOrderField: =>
			if @isRange
				@rangekey
			else
				@hashkey

		getWhere: =>
			_filters = @_c.filters or []
			if _filters.length
				
				@filterGroup( false )
				"WHERE #{ _filters.join( "\n" ) }"
			else
				null

		setFields: ( _fields = @config.fields )=>
			if _.isArray( _fields )
				@_c.fields = _fields.join( ", " )
			else
				@_c.fields = _fields
			return

		getFields: =>
			if @_c.fields?
				@_c.fields
			else
				@config.fields

		setLimit: ( _limit = @config.limit )=>
			@_c.limit = _limit
			return

		getLimit: =>
			if @_c.limit?
				"LIMIT #{ @_c.limit }"
			else
				"LIMIT #{ @config.limit }"

	# private methods 
		_getAttrConfig: ( key )=>
			for attr in @attrs
				return attr if attr.key is key
			return null

		_generateSetCommandTmpls:
			add: _.template( 'IF( INSTR( <%= set %>,"<%= val %><%= dlm %>") = 0, "<%= val %><%= dlm %>", "" )' )
			rem: _.template( 'REPLACE( <%= set %>, "<%= dlm %><%= val %><%= dlm %>", "<%= dlm %>")' )
			set: _.template( 'IF( <%= key %> is NULL,"<%= dlm %>", <%= key %>)' )

		_generateSetCommand: ( key, inp, dlm )=>
			if _.isArray( inp )
				dlm + inp.join( dlm ) + dlm
			else if _.isObject( inp )
				if inp[ "$reset" ]
					if _.isArray( inp[ "$reset" ] )
						'"' + dlm + inp[ "$reset" ].join( dlm ) + dlm + '"'
					else
						'"' + dlm + inp[ "$reset" ] + dlm + '"'
				else
					_set = @_generateSetCommandTmpls.set( key:key, dlm:dlm )
					_add = [ _set ]
					added = []
					usedRem = false
					if inp[ "$add" ]?
						
						if _.isArray( inp[ "$add" ] )
							for _inp in _.uniq( inp[ "$add" ] )
								added.push( _inp )
								_add.push( @_generateSetCommandTmpls.add( val:_inp, set:_set, dlm:dlm ) )
						else
							added.push( inp[ "$add" ] )
							_add.push( @_generateSetCommandTmpls.add( val:inp[ "$add" ], set:_set, dlm:dlm ) )
						
						_set = "CONCAT( #{ _add.join( ", " ) } )" if _add.length
					if inp[ "$rem" ]?
						if _.isArray( inp[ "$rem" ] )
							for _inp in _.difference( _.uniq( inp[ "$rem" ] ), added )
								usedRem = true
								_set = @_generateSetCommandTmpls.rem( val:_inp, set:_set, dlm:dlm )
						else
							usedRem = true
							_set = @_generateSetCommandTmpls.rem( val:inp[ "$rem" ], set:_set, dlm:dlm )
					if added.length or usedRem
						_set
					else 
						null
			else if inp?
				 '"' + dlm + inp + dlm + '"'
			else
				null

		ERRORS: =>
			@extend super, 
				"no-tables": "No table defined"
				"no-hash": "No hash defined"
