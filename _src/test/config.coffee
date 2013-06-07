_envVars = process.env

module.exports  =
	mysql:
		host: if _envVars.MYSQLDYN_TEST_HOST? then _envVars.MYSQLDYN_TEST_HOST else 'localhost'
		user: if _envVars.MYSQLDYN_TEST_USER? then _envVars.MYSQLDYN_TEST_USER else 'root'
		password : if _envVars.MYSQLDYN_TEST_PW? then _envVars.MYSQLDYN_TEST_PW else 'never'
		database: if _envVars.MYSQLDYN_TEST_DB? then _envVars.MYSQLDYN_TEST_DB else "simple-dynamo-offline"
		tablePrefix: "test_"
		#logging: 
		#	severity: "info"

	test:
		singleCreateTableTest: "Employees"

	tables: 
		"Employees":
			name: "employees"
			hashKey:  "id"

			attributes: [
				{ key: "name", type: "string", required: true }
				{ key: "email", type: "string" }
				{ key: "age", type: "number" }
				{ key: "additional", type: "string" }
			]

		"Rooms":
			name: "rooms"
			hashKey:  "id"
			hashKeyType: "S"

			attributes: [
				{ key: "name", type: "string" }
				{ key: "users", type: "array" }
			]

		"Todos":
			name: "todos"
			hashKey:  "id"
			hashKeyType: "S"

			overwriteExistingHash: false

			defaultfields: [ "title", "id" ]

			attributes: [
				{ key: "title", type: "string" }
				{ key: "done", type: "number" }
			]

		"Logs1":
			name: "log1"
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
			name: "log2"
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
