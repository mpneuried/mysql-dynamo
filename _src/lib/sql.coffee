# import the external modules
mysql = require 'mysql'
_ = require('lodash')._

# # SQLBuilder
# ### extends [Basic](basic.coffee.html)

# return a method to prdefine the options fro all Instances
module.exports = ( options )->
	
	# Helper to generate the sql statements
	return class SQLBuilder extends require( "./basic" )

		# define the defaults
		defaults: =>
			@extend super,
				# **fields** *String* MySQL default fields
				fields: "*"
				# **limit** *Number* MySQL default limit
				limit: 1000
				# **hash** *Object* Default hash config
				hash:
					key: ""
					type: "S"
					required: true
					length: 5
					default: ""
					isHash: true
				# **range** *Object* Default range config
				range:
					key: ""
					type: "N"
					required: true
					length: 11
					default: 0
					isRange: true
				# **attr** *Object* Default attribute config
				attr:
					key: ""
					type: "S"
					required: false
					length: 255
				# **sqlSetDelimiter** *String* Delimiter to seperate the set values within a DB cell 
				sqlSetDelimiter: "|"
				# **standardFilterCombine** *String* Standard where expression
				standardFilterCombine: "AND"

		###	
		## constructor 

		`new SQLBuilder( _c )`
		
		A SQL Builder instance to generate SQL statements

		@param {Object} _c Basic internal config data. Used to clone a Instance
		###
		constructor: ( @_c = {} )->

			# set some internal keys
			@_c.attrs or= []
			@_c.attrKeys or= []
			@_c.attrsArrayKeys or= []

			super( options )
			return

		###
		## initialize
		
		`sql.initialize()`
		
		Initialize the SQLBuilder ánd define the properties

		@api private
		###
		initialize: =>
			@define( "table", @getTable, @setTable )

			@define( "hash", @getHash, @setHash )

			@getter( "hashkey", @getHashKey )

			@define( "range", @getRange, @setRange )

			@getter( "rangekey", @getRangeKey )

			@getter( "isRange", @_isRange )

			@define( "attrs", @getAttrs, @setAttrs )

			@getter( "attrKeys", @getAttrKeys )

			@getter( "attrArrayKeys", @getArrayAttrKeys )

			@define( "fields", @getFields, @setFields )

			@define( "limit", @getLimit, @setLimit )

			@define( "forward", @getForward, @setForward )

			@getter( "orderby", @getOrderBy )

			@getter( "orderfield", @getOrderField )

			@getter( "where", @getWhere )

			@log "debug", "initialized"

			return

		# # Public methods
		
		###
		## clone
		
		`sql.clone()`
		
		Clone the current state of the SQLBuilder
		
		@return { SQLBuilder } The cloned Instance
		
		@api public
		###
		clone: =>
			@log "debug", "run clone", Object.keys( @_c )
			return new SQLBuilder( _.clone( @_c ) )

		###
		## insert
		
		`sql.insert( attributes )`
		
		Create a insert statement
		
		@param { Object } attributes Attributes to save 
		
		@return { String } Insert statement 
		
		@api public
		###
		insert: ( attributes )=>

			attributes = @_validateAttributes( true, attributes )

			statement = []
			statement.push "INSERT INTO #{ @table }"

			[ _keys, _vals ] = @_getSaveVariables( attributes )
			
			statement.push( "( #{ _keys.join( ", " )} )" ) 
			statement.push( "VALUES ( #{ _vals.join( ", " ) } )" )
			return _.compact( statement ).join( "\n" )

		###
		## update
		
		`sql.update( attributes )`
		
		Create a update statement
		
		@param { Object } attributes Attributes to update 
		
		@return { String } update statement 
		
		@api public
		###
		update: ( attributes )=>

			attributes = @_validateAttributes( false, attributes )

			statement = []
			statement.push "UPDATE #{ @table }"

			[ _keys, _vals ] = @_getSaveVariables( attributes )

			_sets = []
			for _key, _idx in _keys
				_sets.push( "#{ _key } = #{ _vals[ _idx ] }" ) 
			
			statement.push( "SET #{ _sets.join( ", " ) }" )

			statement.push @where

			return _.compact( statement ).join( "\n" )

		###
		## select
		
		`sql.select( [complex] )`
		
		Create a select statement
		
		@param { Boolean } complex Create a complex select with order by and select
		
		@return { String } select statement 
		
		@api public
		###
		select: ( complex = true )=>

			statement = []
			statement.push "SELECT #{ @fields }"
			statement.push "FROM #{ @table }"

			statement.push @where

			if complex
				statement.push @orderby

				statement.push @limit

			return _.compact( statement ).join( "\n" )


		###
		## delete
		
		`sql.delete( [complex] )`
		
		Create a delete statement
		
		@return { String } delete statement 
		
		@api public
		###
		del: =>
			statement = []
			statement.push "DELETE"
			statement.push "FROM #{ @table }"

			statement.push @where

			return _.compact( statement ).join( "\n" )

		###
		## filter
		
		`sql.filter( key, pred )`
		
		Define a filter criteria which will be used by the `.getWhere()` method
		
		@param { String|Object } key The filter key or a Object of key and predicate 
		@param { Object|String|Number } pred A prediucate object. For details see [Jed's Predicates ](https://github.com/jed/dynamo/wiki/High-level-API#wiki-predicates)
		
		@return { SQLBuilder } Returns itself for chaining
		
		@api public
		###
		filter: ( key, pred )=>
			# set the filter array if not defined yet
			@_c.filters or= []
			@log "debug", "filter", key, pred

			# run this method recrusive if its defined as a object
			if _.isObject( key )
				for _k, _pred of key
					@filter( _k, _pred )
			else
				# create the SQL where statement
				_filter = "#{ key } "

				if not pred?
					# is null if pred is `null`
					_filter += "is NULL"
				else if _.isString( pred ) or _.isNumber( pred )
					# simple `=` filter
					_filter += "= #{ mysql.escape( pred ) }"
				else
					# complex predicate filter
					_operand = Object.keys( pred )[ 0 ]
					_val = pred[ _operand ]
					switch _operand
						when "=="
							# `column is NULL`
							_filter += if _val? then "= #{ mysql.escape( _val ) }" else "is NULL"
						when "!="
							# `column is not NULL`
							_filter += if _val? then "!= #{ mysql.escape( _val ) }" else "is not NULL"
						when ">", "<", "<=", ">="
							# `column > ?`, `column < ?`, `column >= ?` or `column <= ?` or for an array `column between ?[0] and ?[1]`
							if _.isArray( _val )
								_filter += "between #{ mysql.escape( _val[ 0 ] ) } and #{ mysql.escape( _val[ 1 ] ) }"
							else
								_filter += "#{ _operand } #{ mysql.escape( _val ) }"
						when "contains"
							# `column like "%?%"`
							_filter += "like #{ mysql.escape( "%" + _val + "%" ) }"
						when "!contains"
							# `column not like "%?%"`
							_filter += "not like #{ mysql.escape( "%" + _val + "%" ) }"
						when "startsWith"
							# `column like "?%"`
							_filter += "like #{ mysql.escape( _val + "%" ) }"
						when "in"
							# `column in ( ?[0], ?[1], ... ?[n] )`
							if not _.isArray( _val )
								_val = [ _val ]
							_filter += "in ( '#{ mysql.escape( _val ) }')"
				
				# combine the filters with a `AND` or an `OR`
				if @_c.filters?.length
					_cbn = if @_c._filterCombine then @_c._filterCombine else @config.standardFilterCombine
					@_c.filters.push _cbn

				@_c.filters.push( _filter )

				@_c._filterCombine = null

			@

		###
		## or
		
		`sql.or()`
		
		Combine next filter with an `OR`
		
		@return { SQLBuilder } Returns itself for chaining
		
		@api public
		###
		or: =>
			if @_c.filters?.length
				@_c._filterCombine = "OR"
			@

		###
		## and
		
		`sql.and()`
		
		Combine next filter with an `AND`
		
		@return { SQLBuilder } Returns itself for chaining
		
		@api public
		###
		and: =>
			if @_c.filters?.length			
				@_c._filterCombine = "AND"
			@

		###
		## filterGroup
		
		`sql.filterGroup( [newGroup] )`
		
		Start a filter group by wrapping it with "()". It will be colsed at the end, with the next group or by calling `.filterGroup( false )`
		
		@param { Boolean } [newGroup=true] Start a new group 
		
		@return { SQLBuilder } Returns itself for chaining
		
		@api public
		###
		filterGroup: ( newGroup = true )=>
			@_c.filters or= []
			_add = 0
			if @_c._filterGroup? and @_c._filterGroup >= 0
				@log "debug", "filterGroup A", @_c.filters, @_c._filterGroup
				if @_c._filterGroup is 0
					@_c.filters.unshift( "(" )
				else
					@_c.filters.splice( @_c._filterGroup, 0, "(" )
				@_c.filters.push( ")" )
				_add = 1
				@log "debug", "filterGroup B", @_c.filters, @_c._filterGroup
				@_c._filterGroup = null
			if newGroup
				@_c._filterGroup = ( @_c.filters?.length or 0 ) + _add
			@

		###
		## create
		
		`sql.create( attributes )`
		
		Create a table create statement based upon the define `sql.attrs`
		
		@return { String } Create table statement 
		
		@api public
		###
		create: =>
			statement = []
			statement.push "CREATE TABLE IF NOT EXISTS #{ @table } ("

			defs = []

			for attr in @attrs
				defs.push @_genRowCreate( attr )

			prim = "\nPRIMARY KEY ("
			prim += " `#{ @hash.key }` "
			prim += ", `#{ @range.key }` " if @isRange
			prim += ")"
			defs.push prim

			statement.push defs.join(", ")
			statement.push "\n) ENGINE=InnoDB DEFAULT CHARSET=utf8;"

			statement.join( " " )

		###
		## drop
		
		`sql.drop( attributes )`
		
		Create a table drop statement
		
		@return { String } Drop table statement 
		
		@api public
		###
		drop: =>
			"DROP TABLE IF EXISTS #{ @table }"
		
		
		###
		## setToArray
		
		`sql.setToArray( value )`
		
		Convert a set value to a array
		
		@param { String } value A raw db set value
		
		@return { Array } The converted set as an array 
		
		@api public
		###
		setToArray: ( value )=>
			_lDlm = @config.sqlSetDelimiter.length
			if not value? or value?.length <= _lDlm
				return null
			# remove the first and last delimiter and slipt the set into an array
			value[ _lDlm..-( _lDlm + 1 ) ].split( @config.sqlSetDelimiter )

	# # Getter and Setter methods
		
		###
		## setTable
		
		`sql.setTable( tbl )`
		
		Set the table
		
		@param { String } tbl Table name 
		
		@api private
		###
		setTable: ( tbl )=>
			@_c.table = tbl
			return

		###
		## getTable
		
		`sql.getTable()`
		
		Get the table
		
		@return { String } Table name 
		
		@api private
		###
		getTable: =>
			if @_c.table?
				@_c.table
			else
				@_handleError( null, "no-table" )

		###
		## setHash
		
		`sql.setHash( _h )`
		
		Set the hash config
		
		@param { object } _h Hash configuration
		
		@api private
		###
		setHash: ( _h )=>
			@_c.hash = {}
			@extend( @_c.hash, @config.hash, _h )
			# add the hash to the attributes
			@_c.attrs.push @_c.hash
			@_c.attrKeys.push @_c.hash.key
			return

		###
		## getHash
		
		`sql.getHash()`
		
		Get the hash configuration
		
		@return { Object } Hash configuration 
		
		@api private
		###
		getHash: =>
			if @_c.hash?
				@_c.hash
			else
				@_handleError( null, "no-hash" )

		###
		## getHashKey
		
		`sql.getHashKey()`
		
		Get the key name of the hash
		
		@return { String } Key name of the hash 
		
		@api private
		###
		getHashKey: =>
			@hash.key

		###
		## setRange
		
		`sql.setRange( _r )`
		
		Set the range config
		
		@param { object } _r Hash configuration
		
		@api private
		###
		setRange: ( _r )=>
			if _r?
				@_c.isRange = true
				@_c.range = {}
				@extend( @_c.range, @config.range, _r )
				# add the range to the attributes
				@_c.attrs.push @_c.range
				@_c.attrKeys.push @_c.range.key
			else
				@_c.isRange = false
				_.omit( @_c, "range" )
			return

		###
		## getRange
		
		`sql.getRange()`
		
		Get the range configuration
		
		@return { Object } Range configuration 
		
		@api private
		###
		getRange: =>
			@_c.range

		###
		## getRangeKey
		
		`sql.getRangeKey()`
		
		Get the key name of the range
		
		@return { String } Key name of the range 
		
		@api private
		###
		getRangeKey: =>
			if @isRange
				@range.key
			else
				null

		###
		## _isRange
		
		`sql._isRange()`
		
		Check if this table is a range table
		
		@return { Boolean } Is range table 
		
		@api private
		###
		_isRange: =>
			if @_c.isRange? then @_c.isRange or false

		###
		## setAttrs
		
		`sql.setAttrs( _attrs )`
		
		Set the attribute configuration
		
		@param { String } _attrs Arrtribute configuration 
		
		@api private
		###
		setAttrs: ( _attrs )=>
			_defAttrCnf = @config.attr
			for attr in _attrs
				if attr.key?
					# collect the attribute keys
					@_c.attrKeys.push attr.key
					# set the attribute configuration and extend it with the defauts
					@_c.attrs.push @extend( {}, _defAttrCnf, attr )
					# collect the set type keys
					if attr.type in [ "A", "array" ]
						@_c.attrsArrayKeys.push attr.key
			return

		###
		## getAttrs
		
		`sql.getAttrs()`
		
		Get the current attribute configuration
		
		@return { Object } Attribute configuration 
		
		@api private
		###
		getAttrs: =>
			if @_c.attrs?
				@_c.attrs
			else
				[]

		###
		## getAttrKeys
		
		`sql.getAttrKeys()`
		
		Get the keys of all defined attributes
		
		@return { Array } All defined attributes
		
		@api private
		###
		getAttrKeys: =>
			@_c.attrKeys or []

		###
		## getArrayAttrKeys
		
		`sql.getArrayAttrKeys()`
		
		Get all attribute keys of type `array` or `A`
		
		@return { Array } All defined attributes of type array 
		
		@api private
		###
		getArrayAttrKeys: =>
			@_c.attrsArrayKeys or []

		###
		## setForward
		
		`sql.setForward( [_forward] )`
		
		Set the order direction
		
		@param { Boolean } _forward `true`=`ASC` and `false`=`DESC`
		
		@api private
		###
		setForward: ( _forward = true )=>
			if _forward
				@_c.forward = true
			else
				@_c.forward = false
			return

		###
		## getForward
		
		`sql.getForward()`
		
		Get the order direction
		
		@return { Boolean } Is ordered by `ASC` 
		
		@api private
		###
		getForward: =>
			if @_c.forward?
				@_c.forward
			else
				true

		###
		## getOrderField
		
		`sql.getOrderField()`
		
		Get the defined order by field. Usualy the range key.
		
		@return { String } Name of the column to define the order 
		
		@api private
		###
		getOrderField: =>
			if @isRange
				@rangekey
			else
				@hashkey

		###
		## getOrderBy
		
		`sql.getOrderBy()`
		
		Get the `ORDER BY` sql
		
		@return { String } Order by sql
		
		@api private
		###
		getOrderBy: =>
			if @forward
				"ORDER BY #{ @orderfield } ASC"
			else
				"ORDER BY #{ @orderfield } DESC"	

		###
		## getWhere
		
		`sql.getWhere()`
		
		Construct the `WHERE` sql
		
		@return { String } The sql Where clause
		
		@api private
		###
		getWhere: =>
			_filters = @_c.filters or []
			if _filters.length
				
				@filterGroup( false )
				"WHERE #{ _filters.join( "\n" ) }"
			else
				null

		###
		## setFields
		
		`sql.setFields( [fields] )`
		
		Set the fields to select
		
		@param { Array|String } [fields] The fields to select as sql field list or as an array 
		
		@api private
		###
		setFields: ( _fields = @config.fields )=>
			if _.isArray( _fields )
				@_c.fields = _fields.join( ", " )
			else
				@_c.fields = _fields
			return

		###
		## getFields
		
		`sql.getFields()`
		
		Get the field list
		
		@return { String } Sql field list 
		
		@api private
		###
		getFields: =>
			if @_c.fields?
				@_c.fields
			else
				@config.fields

		###
		## setLimit
		
		`sql.setLimit( [_limit] )`
		
		Set the maximum number of returned values
		
		@param { Number } [_limit] The number of returned elements. `0` for unlimited
		
		@api private
		###
		setLimit: ( _limit = @config.limit )=>
			@_c.limit = _limit
			return


		###
		## getLimit
		
		`sql.getLimit()`
		
		Get the `LIMIT` sql
		
		@return { String } The sql limit clause
		
		@api private
		###
		getLimit: =>
			if @_c.limit?
				if @_c.limit is 0
					null
				else
					"LIMIT #{ @_c.limit }"
			else
				"LIMIT #{ @config.limit }"

		

	# # Private methods 
		
		###
		## _genRowCreate
		
		`sql._genRowCreate( opt )`
		
		Generate the create code for a table column
		
		@param { Object } opt Column config 
		
		@return { String } Sql part for the Create tabel statement 
		
		@api private
		###
		_genRowCreate: ( opt )=>

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


		###
		## _validateAttributes
		
		`sql._validateAttributes( isCreate, attributes )`
		
		Validate the attributes before a update or insert
		
		@param { Boolean } isCreate It is a insert 
		@param { Object } attributes Object of attributes to save 
		
		@return { Object } The cleaned attributes 
		
		@api private
		###
		_validateAttributes: ( isCreate, attrs )=>
			_keys = @attrKeys
			_omited = _.difference( Object.keys( attrs ),_keys )
			attrs = _.pick( attrs, _keys )
			if _omited.length
				@log "warning", "validateAttributes", "You tried to save to attributed not defined in the model config", _omited, attrs
			else
				@log "debug", "validateAttributes", attrs
			return attrs

		###
		## _getAttrConfig
		
		`sql._getAttrConfig( key )`
		
		Get the configuration of a attribute
		
		@param { String } key Attribute/Column/Field name 
		
		@return { Object } Attribute configuration
		
		@api private
		###
		_getAttrConfig: ( key )=>
			for attr in @attrs
				return attr if attr.key is key

		###
		## _getSaveVariables
		
		`sql._getSaveVariables( attributes )`
		
		Create the keys and values for the update and inser statements
		
		@param { Object } attributes Data object to save 
		
		@return { [_keys,_vals] } `_keys`: An array of all keys to save; `_vals`: An array of all escaped values to save
		
		@api private
		###
		_getSaveVariables: ( attributes )=> 
			_keys = []
			_vals = []
			# loop through all attributes
			for _key, _val of attributes
				_cnf = @_getAttrConfig( _key )
				if _cnf
					switch _cnf.type
						when "string", "number", "S", "N"
							# create regular values
							_keys.push( _key )
							_vals.push( mysql.escape( _val ) )
						when "array", "A"
							# create values with the set functions.
							_setval = @_generateSetCommand( _key, _val, @config.sqlSetDelimiter )
							if _setval?
								_keys.push( _key )
								_vals.push( _setval )
							@log "debug", "setCommand", _setval, _val, _key
			return [ _keys, _vals ]
			return null

		# **_generateSetCommandTmpls** *Object* Underscore templates for the set sql commands. Used by the method `_generateSetCommand`
		_generateSetCommandTmpls:
			add: _.template( 'IF( INSTR( <%= set %>,"<%= val %><%= dlm %>") = 0, "<%= val %><%= dlm %>", "" )' )
			rem: _.template( 'REPLACE( <%= set %>, "<%= dlm %><%= val %><%= dlm %>", "<%= dlm %>")' )
			set: _.template( 'IF( <%= key %> is NULL,"<%= dlm %>", <%= key %>)' )

		###
		## _generateSetCommand
		
		`sql._generateSetCommand( key, inp, dlm )`
		
		Generate the sql command to add, reset or remove a elment out of a set string.
		How to handle set within a sql field is described by this [GIST](https://gist.github.com/mpneuried/5704200) 
		
		@param { String } key The field name 
		@param { String|Number|Object } inp the set command as simple string/number or complex set command. More in [API docs](http://mpneuried.github.io/mysql-dynamo/) section " Working with sets"
		@param { String } dlm The delimiter within the field

		@return { String } Return Desc 
		
		@api private
		###
		_generateSetCommand: ( key, inp, dlm )=>
			@log "debug", "_generateSetCommand", key, inp
			
			# set empty
			if not inp?
				mysql.escape( dlm )
			
			# set by array
			else if _.isArray( inp )
				if not inp.length 
					# set empty by empty array
					mysql.escape( dlm )
				else
					# reset by array
					mysql.escape( dlm + inp.join( dlm ) + dlm )

			# set by object
			else if _.isObject( inp )
				if inp[ "$reset" ]
					if _.isArray( inp[ "$reset" ] )
						# reset by $reset with an array
						mysql.escape( dlm + inp[ "$reset" ].join( dlm ) + dlm )
					else
						# reset by $reset with a single value
						mysql.escape( dlm + inp[ "$reset" ] + dlm )
				else
					# run $add or $rem command
					
					# define some vars
					added = []
					usedRem = false

					# convert the key to a expression with the check for an empty field, because a field of type TEXT cannot have a default
					_set = @_generateSetCommandTmpls.set( key:key, dlm:dlm )

					# prefix CONCAT content with the current value
					_add = [ _set ]
					
					# $add command by concat the current value with the new value expressions
					if inp[ "$add" ]?
						# if the content is an array generate multiple add statements
						if _.isArray( inp[ "$add" ] )
							for _inp in _.uniq( inp[ "$add" ] )
								# set added flag to detect any changes
								added.push( _inp )
								_add.push( @_generateSetCommandTmpls.add( val:_inp, set:_set, dlm:dlm ) )
						else
							# set added to detect any changes
							added.push( inp[ "$add" ] )
							_add.push( @_generateSetCommandTmpls.add( val:inp[ "$add" ], set:_set, dlm:dlm ) )
						
						# if any add has been generated overwritethe new set command
						_set = "CONCAT( #{ _add.join( ", " ) } )" if _add.length
					
					# $rem command by nesting replace commands
					if inp[ "$rem" ]?
						# if the content is an array generate multiple rem statements
						if _.isArray( inp[ "$rem" ] )
							for _inp in _.difference( _.uniq( inp[ "$rem" ] ), added )
								# set usedRem to detect any removes
								usedRem = true
								_set = @_generateSetCommandTmpls.rem( val:_inp, set:_set, dlm:dlm )
						else
							# set usedRem to detect any removes
							usedRem = true
							_set = @_generateSetCommandTmpls.rem( val:inp[ "$rem" ], set:_set, dlm:dlm )
					
					# return `null` if nothing has to be changed
					if added.length or usedRem
						_set
					else 
						null
			# set by string or number
			else if inp?
				 mysql.escape( dlm + inp + dlm )

			# noting to set
			else
				null


		# # Error message mapping
		ERRORS: =>
			@extend super, 
				"no-tables": "No table defined"
				"no-hash": "No hash defined"
