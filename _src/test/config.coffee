_envVars = process.env

module.exports  =
	mysql:
		host: _envVars.MYSQLDYN_TEST_HOST or 'localhost'
		user: _envVars.MYSQLDYN_TEST_USER or 'root'
		password : _envVars.MYSQLDYN_TEST_PW or 'never'
		database: _envVars.MYSQLDYN_TEST_DB or "simple-dynamo-offline"
		multipleStatements: true
		logging:
			severity: "warning"

	test:
		deleteTablesOnEnd: true
		singleCreateTableTest: "Employees"

	tables: 
		"Employees":
			name: "test_employees"
			hashKey:  "id"

			attributes: [
				{ key: "name", type: "string", required: true }
				{ key: "email", type: "string" }
				{ key: "age", type: "number" }
				{ key: "additional", type: "string" }
			]

		"Rooms":
			name: "test_rooms"
			hashKey:  "id"
			hashKeyType: "S"

			attributes: [
				{ key: "name", type: "string" }
				{ key: "users", type: "array" }
			]

		"Todos":
			name: "test_todos"
			hashKey:  "id"
			hashKeyType: "S"

			overwriteExistingHash: false

			defaultfields: [ "title", "id" ]

			attributes: [
				{ key: "title", type: "string" }
				{ key: "done", type: "number" }
			]

		"Logs1":
			name: "test_log1"
			hashKey:  "id"
			hashKeyType: "S"

			rangeKey: "t"
			rangeKeyType: "N"

			overwriteExistingHash: true

			fnCreateHash: ( attributes, cb )->
				cb( attributes.user )
				return

			attributes: [
				{ key: "user", type: "string", required: true }
				{ key: "title", type: "string" }
			]

		"Logs2":
			name: "test_log2"
			hashKey:  "id"
			hashKeyType: "S"

			rangeKey: "t"
			rangeKeyType: "N"

			overwriteExistingHash: true

			fnCreateHash: ( attributes, cb )->
				cb( attributes.user )
				return

			attributes: [
				{ key: "user", type: "string", required: true }
				{ key: "title", type: "string" }
			]

	dummyTables: 
		"Dummy":
			name: "dummy"
			hashKey:  "id"

			attributes: [
				{ key: "a", type: "string", required: true }
				{ key: "b", type: "string" }
			]
