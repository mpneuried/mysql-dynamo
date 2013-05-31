_ = require('lodash')._

module.exports = class MySQLDynamoTable extends require( "./basic" )

	constructor: ( @_model_settings, options )->

		@__defineGetter__ "name", =>
			@_model_settings.name

		@__defineGetter__ "tableName", =>
			@_model_settings.combineTableTo or @_model_settings.name or null

		@__defineGetter__ "isCombinedTable", =>
			@_model_settings.combineTableTo?
		
		@__defineGetter__ "combinedHashDelimiter", =>
			""

		@__defineGetter__ "existend", =>
			@external?

		@__defineGetter__ "hasRange", =>
			if @_model_settings?.rangeKey?.length then true else false

		@__defineGetter__ "hashKey", =>
			@_model_settings?.hashKey or null

		@__defineGetter__ "hashKeyType", =>
			if @isCombinedTable
				"S"
			else
				@_model_settings?.hashKeyType or "S"

		@__defineGetter__ "rangeKey", =>
			@_model_settings?.rangeKey or null

		@__defineGetter__ "rangeKeyType", =>
			if @hasRange
				@_model_settings?.rangeKeyType or "N"
			else
				null

		super( options )
		return

	initialize: =>
		@log "debug", "init table", @tableName, @hashKey, @rangeKey
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

	_generate: =>
		@log "debug", "generate table", @tableConfig

		

		return