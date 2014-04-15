_CONFIG = require './config'

_ = require("lodash")._
should = require('should')

MySQLDynamo = require( "../index" )
_utils = require( "../lib/utils" )

testTitle = "mySQL Dynamo"
_basicTable = "Employees"
_overwriteTable = "Todos"
_logTable1 = "Logs1"
_logTable2 = "Logs2"
_setTable = "Rooms"

_DATA = require "./testdata"

dynDB = null
dynDBDummy = null
tableG = null


describe "----- #{ testTitle } TESTS -----", ->
	before ( done )->
		done()
		return

	describe 'Initialization', ->
		it 'init manager', ( done )->
			dynDB = new MySQLDynamo( _CONFIG.mysql, _CONFIG.tables )
			dynDBDummy = new MySQLDynamo( _CONFIG.mysql, _CONFIG.dummyTables )
			done()
			return

		it 'pre connect', ( done )->
			dynDB.fetched.should.be.false
			dynDB.connected.should.be.false
			done()
			return

		it 'init table objects', ( done )->
			dynDB.connect ( err )->
				throw err if err

				tableG = dynDB.get( _basicTable )
				should.exist( tableG )

				done()
				return
			return

		it 'init table objects for dummy', ( done )->
			dynDBDummy.connect ( err )->
				throw err if err
				done()
				return
			return

		it 'post connect', ( done )->
			dynDB.fetched.should.be.true
			done()
			return


	describe "Create tables", ->

		it 'drop all existing test tables', ( done )->

			aFns = []
			dynDB.each ( _k, tbl )=>  
				aFns.push _.bind( ( cba )->
					tbl.destroy ( err )->
						throw err if err
						cba()
						return
				)

			_utils.runParallel aFns, ( err )->
				done()
				return
			return

		it "create a single table", ( done )->
			dynDB.generate _CONFIG.test.singleCreateTableTest, ( err )->
				throw err if err
				done()
				return
			return

		it "create all missing tables", ( done )->
			dynDB.generateAll ( err )->
				throw err if err
				done()
				return
			return

	describe 'Manager Tests', ->
		it "List the existing tables", ( done )->
			dynDB.list ( err, tables )->
				throw err if err

				# create expected list of tables
				tbls = []
				for tbl in Object.keys( _CONFIG.tables )
					tbls.push( tbl.toLowerCase() )
				tables.should.eql( tbls )

				done()
			return

		it "Get a table", ( done )->

			_cnf = _CONFIG.tables[ _CONFIG.test.singleCreateTableTest ]

			_tbl = dynDB.get( _CONFIG.test.singleCreateTableTest )
			_tbl.should.exist
			_tbl?.name?.should.eql( _cnf.name )

			done()
			return

		it "Try to get a not existend table", ( done )->

			_tbl = dynDB.get( "notexistend" )
			should.not.exist( _tbl )

			done()
			return

		it "has for existend table", ( done )->

			_has = dynDB.has( _CONFIG.test.singleCreateTableTest )
			_has.should.be.true

			done()
			return

		it "has for not existend table", ( done )->

			_has = dynDB.has( "notexistend" )
			_has.should.be.false

			done()
			return

		it "Get check `existend` for real table", ( done )->

			_tbl = dynDB.get( _CONFIG.test.singleCreateTableTest )
			_tbl.should.exist
			_tbl.existend.should.be.true
			done()
			return

		it "Get check `existend` for dummy table", ( done )->

			_tbl = dynDBDummy.get( "Dummy" )
			_tbl.should.exist
			_tbl.existend.should.be.false
			done()
			return

		it "generate ( existend ) table", ( done )->

			_has = dynDB.generate _CONFIG.test.singleCreateTableTest, ( err, created )->
				throw err if err 
				created.should.be.false
				done()
			return

		it "List the existing tables", ( done )->
			dynDB.list ( err, tables )->
				throw err if err

				# create expected list of tables
				tbls = []
				for tbl in Object.keys( _CONFIG.tables )
					tbls.push( tbl.toLowerCase() )
				tables.should.eql( tbls )

				done()
			return

	describe "CRUD Tests", ->

		_C = _CONFIG.tables[ _basicTable ]
		_D = _DATA[ _basicTable ]
		_G = {}
		_ItemCount = 0

		it "list existing items", ( done )->
			
			tableG.find ( err, items )->
				throw err if err
				items.should.an.instanceof( Array )
				_ItemCount = items.length
				done()
				return
			return

		it "create an item", ( done )->
			tableG.set _.clone( _D[ "insert1" ] ), ( err, item )->
				throw err if err
				should.exist( item.id )
				should.exist( item.name )
				should.exist( item.email )
				should.exist( item.age )

				item.id.should.equal( _D[ "insert1" ].id )
				item.name.should.equal( _D[ "insert1" ].name )
				item.email.should.equal( _D[ "insert1" ].email )
				item.age.should.equal( _D[ "insert1" ].age )

				_ItemCount++
				_G[ "insert1" ] = item

				done()
				return
			return

		it "try to get the item and check the content", ( done )->
			
			tableG.get _G[ "insert1" ][ _C.hashKey ], ( err, item )->
				throw err if err

				should.exist( item.id )
				should.exist( item.name )
				should.exist( item.email )
				should.exist( item.age )

				item.id.should.equal( _D[ "insert1" ].id )
				item.name.should.equal( _D[ "insert1" ].name )
				item.email.should.equal( _D[ "insert1" ].email )
				item.age.should.equal( _D[ "insert1" ].age )

				done()
				return
			return

		it "create a second item", ( done )->
			
			tableG.set _.clone( _D[ "insert2" ] ), ( err, item )->
				throw err if err

				should.exist( item.id )
				should.exist( item.name )
				should.exist( item.email )
				should.exist( item.age )
				should.exist( item.additional )

				item.name.should.equal( _D[ "insert2" ].name )
				item.email.should.equal( _D[ "insert2" ].email )
				item.age.should.equal( _D[ "insert2" ].age )
				item.additional.should.equal( _D[ "insert2" ].additional )

				_ItemCount++
				_G[ "insert2" ] = item

				done()
				return
			return

		it "create a third item", ( done )->
			
			tableG.set _.clone( _D[ "insert3" ] ), ( err, item )->
				throw err if err

				should.exist( item.id )
				should.exist( item.name )
				should.exist( item.email )
				should.exist( item.age )

				item.name.should.equal( _D[ "insert3" ].name )
				item.email.should.equal( _D[ "insert3" ].email )
				item.age.should.equal( _D[ "insert3" ].age )

				_ItemCount++
				_G[ "insert3" ] = item

				done()
				return
			return

		if _basicTable.slice( 0,2 ) is "C_"
			it "insert a invalid item to combined table", ( done )->
			
				tableG.set _.clone( _D[ "insert4" ] ), ( err, item )->
					should.exist( err )
					err.name.should.equal( "combined-hash-invalid" )

					should.not.exist( item )

					done()
					return
				return

		it "list existing items after insert(s)", ( done )->
			
			tableG.find ( err, items )->
				throw err if err

				items.should.an.instanceof( Array )
				items.length.should.equal( _ItemCount )
				done()
				return
			return

		it "try to get two items at once (mget)", ( done )->
			tableG.mget [ _G[ "insert1" ][ _C.hashKey ], _G[ "insert2" ][ _C.hashKey ] ], ( err, items )->
				throw err if err

				items.should.have.length( 2 )
				aPred = [ _G[ "insert1" ], _G[ "insert2" ] ]
				for item in items
					aPred.should.includeEql( item )

				done()
				return
			return

		it "try to get two items plus a unkown at once (mget)", ( done )->
			tableG.mget [ _G[ "insert1" ][ _C.hashKey ], _G[ "insert2" ][ _C.hashKey ], "xxxxxx" ], ( err, items )->
				throw err if err

				items.should.have.length( 2 )
				aPred = [ _G[ "insert1" ], _G[ "insert2" ] ]
				for item in items
					aPred.should.includeEql( item )

				done()
				return
			return

		it "update first item with empty string attribute", ( done )->
			tableG.set _G[ "insert1" ][ _C.hashKey ], _D[ "update1" ], ( err, item )->
				throw err if err

				should.exist( item.id )
				should.exist( item.name )
				should.exist( item.age )
				should.exist( item.email )
				should.not.exist( item.additional )

				item.id.should.equal( _G[ "insert1" ].id )
				item.name.should.equal( _D[ "insert1" ].name )
				item.email.should.equal( _D[ "insert1" ].email )
				item.age.should.equal( _D[ "insert1" ].age )

				_G[ "insert1" ] = item

				done()
				return
			return

		it "delete the first inserted item", ( done )->
			
			tableG.del _G[ "insert1" ][ _C.hashKey ], ( err )->
				throw err if err
				_ItemCount--
				done()
				return
			return

		it "try to get deleted item", ( done )->
			tableG.get _G[ "insert1" ][ _C.hashKey ], ( err, item )->
				throw err if err

				should.not.exist( item )

				done()
				return
			return

		

		it "update second item", ( done )->
			tableG.set _G[ "insert2" ][ _C.hashKey ], _D[ "update2" ], fields: [ "id", "name", "age" ], ( err, item )->
				throw err if err

				should.exist( item.id )
				should.exist( item.name )
				should.exist( item.age )
				should.not.exist( item.email )
				should.not.exist( item.additional )

				item.id.should.equal( _G[ "insert2" ].id )
				item.name.should.equal( _D[ "update2" ].name )
				item.age.should.equal( _D[ "update2" ].age )

				_G[ "insert2" ] = item

				done()
				return
			return

		it "update third item with successfull conditonal", ( done )->

			_opt = 
				fields: [ "id", "name", "age" ]
				conditionals: 
					"age": { "==": 78 }

			tableG.set _G[ "insert3" ][ _C.hashKey ], _D[ "update3" ], _opt, ( err, item )->
				throw err if err

				should.exist( item.id )
				should.exist( item.name )
				should.exist( item.age )
				should.not.exist( item.email )
				should.not.exist( item.additional )

				item.id.should.equal( _G[ "insert3" ].id )
				item.name.should.equal( _D[ "update3" ].name )
				item.age.should.equal( _D[ "update3" ].age )

				_G[ "insert3" ] = item

				done()
				return
			return

		it "update third item with failing conditonal", ( done )->

			_opt = 
				fields: [ "id", "name", "age" ]
				conditionals: 
					"age": { "==": 123 }

			tableG.set _G[ "insert3" ][ _C.hashKey ], _D[ "update3" ], _opt, ( err, item )->
				should.exist( err )
				err.name.should.equal( "conditional-check-failed" )

				done()
				return
			return

		it "update third item to check numeric functions", ( done )->

			_opt = 
				fields: [ "id", "name", "age" ]

			tableG.set _G[ "insert3" ][ _C.hashKey ], _D[ "update3_2" ], _opt, ( err, item )->
				should.not.exist( err )
				
				should.exist( item.id )
				should.exist( item.name )
				should.exist( item.age )
				item.age.should.equal( _G[ "insert3" ].age + _D[ "update3_2" ].age[ "$add" ] )

				_G[ "insert3" ] = item

				done()
				return
			return

		it "update third item with `number` field = `null`", ( done )->

			_opt = 
				fields: [ "id", "name", "age" ]
			tableG.set _G[ "insert3" ][ _C.hashKey ], _D[ "update3_3" ], _opt, ( err, item )->
				should.not.exist( err )
				should.exist( item.id )
				should.exist( item.name )
				should.not.exist( item.age )

				item.id.should.equal( _G[ "insert3" ].id )
				item.name.should.equal( _G[ "insert3" ].name )

				_G[ "insert3" ] = item

				done()
				return
			return

		it "update not existing item to be inserted", ( done )->
			tableG.set _D[ "update4" ][ _C.hashKey ], _D[ "update4" ], fields: [ "id", "name", "age" ], ( err, item )->
				throw err if err

				should.exist( item.id )
				should.exist( item.name )
				should.exist( item.age )
				should.not.exist( item.email )
				should.not.exist( item.additional )

				item.id.should.equal( _D[ "update4" ].id )
				item.name.should.equal( _D[ "update4" ].name )
				item.age.should.equal( _D[ "update4" ].age )


				_G[ "update4" ] = item
				_ItemCount++

				done()
				return
			return

		it "delete the second inserted item", ( done )->
			
			tableG.del _G[ "insert2" ][ _C.hashKey ], ( err )->
				throw err if err
				_ItemCount--
				done()
				return
			return

		it "delete the third inserted item", ( done )->
			
			tableG.del _G[ "insert3" ][ _C.hashKey ], ( err )->
				throw err if err
				_ItemCount--
				done()
				return
			return

		it "delete the forth inserted item", ( done )->
			
			tableG.del _G[ "update4" ][ _C.hashKey ], ( err )->
				throw err if err
				_ItemCount--
				done()
				return
			return

		it "check item count after update(s) and delete(s)", ( done )->
			
			tableG.find ( err, items )->
				throw err if err

				items.should.an.instanceof( Array )
				items.length.should.equal( _ItemCount )
				done()
				return
			return

		return

	describe "Overwrite Tests", ->

		table = null

		_C = _CONFIG.tables[ _overwriteTable ]
		_D = _DATA[ _overwriteTable ]
		_G = {}
		_ItemCount = 0

		it "get table", ( done )->
			table = dynDB.get( _overwriteTable )
			should.exist( table )
			done()
			return

		it "create item", ( done )->
			
			table.set _.clone( _D[ "insert1" ] ), ( err, item )->
				throw err if err

				should.exist( item.id )
				should.exist( item.title )
				should.not.exist( item.done )

				item.id.should.equal( _D[ "insert1" ].id )
				item.title.should.equal( _D[ "insert1" ].title )
				#item.done.should.equal( _D[ "insert1" ].done )

				_ItemCount++
				_G[ "insert1" ] = item

				done()
				return
			return

		it "try second insert with the same hash", ( done )->
			
			table.set _D[ "insert2" ], ( err, item )->

				should.exist( err )
				err.name.should.equal( "conditional-check-failed" )

				should.not.exist( item )

				done()
				return
			return

		it "list items", ( done )->
			table.find ( err, items )->
				throw err if err
				items.should.an.instanceof( Array )
				items.length.should.equal( _ItemCount )
				done()
				return
			return

		it "delete the first inserted item", ( done )->
			
			table.del _G[ "insert1" ][ _C.hashKey ], ( err )->
				throw err if err
				_ItemCount--
				done()
				return
			return


	describe "Range Tests", ->

		table1 = null
		table2 = null
		_D1 = _DATA[ _logTable1 ]
		_D2 = _DATA[ _logTable2 ]
		_C1 = _CONFIG.tables[ _logTable1 ]
		_C2 = _CONFIG.tables[ _logTable2 ]
		_G1 = []
		_G2 = []
		_ItemCount1 = 0
		_ItemCount2 = 0

		last = null
		pre_last = null
		_reverseFirst = null
		
		it "get table 1", ( done )->
			table1 = dynDB.get( _logTable1 )
			should.exist( table1 )
			done()
			return

		it "get table 2", ( done )->
			table2 = dynDB.get( _logTable2 )
			should.exist( table2 )
			done()
			return

		it "insert #{ _D1.inserts.length } items to range list of table 1", ( done )->
			aFns = []
			for insert in _D1.inserts
				aFns.push _.bind( ( insert, cba )->
					tbl = @
					table1.set _.clone( insert ), ( err, item )->
						throw err if err
						if tbl.isCombinedTable
							item.id.should.equal( tbl.name + tbl.combinedHashDelimiter + insert.user )
						else
							item.id.should.equal( insert.user )
						item.t.should.equal( insert.t )
						item.user.should.equal( insert.user )
						item.title.should.equal( insert.title )
						_ItemCount1++
						_G1.push( item )
						cba( item )

				, table1, insert ) 

			_utils.runParallel aFns, ( err )->
				done()

		it "insert #{ _D2.inserts.length } items to range list of table 2", ( done )->
			aFns = []
			for insert in _D2.inserts
				aFns.push _.bind( ( insert, cba )->
					tbl = @
					table2.set _.clone( insert ), ( err, item )->
						throw err if err
						if tbl.isCombinedTable
							item.id.should.equal( tbl.name + tbl.combinedHashDelimiter + insert.user )
						else
							item.id.should.equal( insert.user)
						item.t.should.equal( insert.t )
						item.user.should.equal( insert.user )
						item.title.should.equal( insert.title )
						_ItemCount2++
						_G2.push( item )
						cba( item )

				, table2, insert ) 

			_utils.runParallel aFns, ( err )->
				done()


		it "try to get two items at once (mget)", ( done )->
			table1.mget [ [ _G1[ 1 ][ _C1.hashKey ],_G1[ 1 ][ _C1.rangeKey ] ] , [ _G1[ 5 ][ _C1.hashKey ],_G1[ 5 ][ _C1.rangeKey ] ] ], ( err, items )->
				throw err if err

				items.should.have.length( 2 )
				aPred = [ _G1[ 1 ], _G1[ 5 ] ]
				for item in items
					aPred.should.includeEql( item )

				done()
				return
			return

		it "try to get two items plus a unkown at once (mget)", ( done )->
			table2.mget [ [ _G2[ 1 ][ _C2.hashKey ],_G2[ 1 ][ _C2.rangeKey ] ] , [ _G2[ 5 ][ _C2.hashKey ],_G2[ 5 ][ _C2.rangeKey ] ], [ _G2[ 3 ][ _C2.hashKey ], 999 ] ], ( err, items )->
				throw err if err

				items.should.have.length( 2 )
				aPred = [ _G2[ 1 ], _G2[ 5 ] ]
				for item in items
					aPred.should.includeEql( item )

				done()
				return
			return

		it "get a range of table 1", ( done )->
			_q = 
				id: { "==": "A" }
				t: { ">=": 5 }
			
			table1.find _q, ( err, items )->
				throw err if err

				items.length.should.equal( 3 )
				done()

		it "get a range of table 2", ( done )->
			_q = 
				id: { "==": "D" }
				t: { ">=": 3 }

			table2.find _q, ( err, items )->
				throw err if err

				items.length.should.equal( 1 )
				done()

		it "get a single item of table 1", ( done )->
			_item = _G1[ 4 ]

			table1.get [ _item.id, _item.t ], ( err, item )->
				throw err if err

				item.should.eql( _item )
				done()

		it "should return only 3 items", (done) ->
			_count = 3
			_q = 
				id: { "==": "A" }
				t: { ">=": 0 }

			_o = 
				limit: _count

			table2.find _q, _o, ( err, items )->
				throw err if err
				_reverseFirst = items[0]
				should.exist items
				items.length.should.equal _count
				last = items[_count - 1]
				pre_last = items[_count - 2]
				done()

		it "should return the next 3 by `startAt`", (done) ->
			_count = 3
			_q = 
				id: { "==": "A" }
				t: { ">=": 0 }
			_o = 
				limit: _count

			_c = [ pre_last.id, pre_last.t ]

			table2.find _q, _c, _o, ( err, items )->
				throw err if err
				predicted_first = items[0]
				predicted_first.should.eql last
				items.length.should.equal _count
				last = items[_count - 1]
				pre_last = items[_count - 2]
				done()

		it "should return the next 3 by reverse `startAt`", (done) ->
			_count = 3
			_q = 
				id: { "==": "A" }
				t: { ">=": 0 }
			_o = 
				limit: _count
				forward: false

			_c = [ pre_last.id, pre_last.t ]
			
			table2.find _q, _c, _o, ( err, items )->
				throw err if err

				predicted_last = _.last( items )
				predicted_last.should.eql _reverseFirst
				items.length.should.equal _count
				done()

		it "delete whole data from table 1", ( done )->
			aFns = []
			for item in _G1
				aFns.push _.bind( ( item, cba )->
					table1.del [ item.id, item.t ], ( err )->
						throw err if err
						_ItemCount1--
						cba()
				, table1, item )

			_utils.runParallel aFns, ( err )->
				done()

		it "delete whole data from table 2", ( done )->
			aFns = []
			for item in _G2
				aFns.push _.bind( ( item, cba )->
					table2.del [ item.id, item.t ], ( err )->
						throw err if err
						_ItemCount2--
						cba()
				, table2, item )

			_utils.runParallel aFns, ( err )->
				done()

		it "check for empty table 1", ( done )->
			_q = {}

			table1.find _q, ( err, items )->
				throw err if err

				items.length.should.equal( _ItemCount1 )
				done()

		it "check for empty table 2", ( done )->
			_q = {}

			table2.find _q, ( err, items )->
				throw err if err

				items.length.should.equal( _ItemCount2 )
				done()
	
	describe "Set Tests", ->		
		

		_C = _CONFIG.tables[ _setTable ]
		_D = _DATA[ _setTable ]
		_G = {}
		_ItemCount = 0
		table = null

		it "get table", ( done )->
			table = dynDB.get( _setTable )
			should.exist( table )
			done()
			return

		it "create the test item", ( done )->
			
			table.set _.clone( _D[ "insert1" ] ), ( err, item )->
				throw err if err

				should.exist( item.id )
				should.exist( item.name )
				should.exist( item.users )

				item.name.should.equal( _D[ "insert1" ].name )
				item.users.should.eql( [ "a" ] )

				_ItemCount++
				_G[ "insert1" ] = item

				done()
				return
			return


		it "test raw reset", ( done )->
			
			table.set _G[ "insert1" ].id, _.clone( _D[ "update1" ] ), ( err, item )->
				throw err if err
				should.exist( item.id )
				should.exist( item.name )
				should.exist( item.users )

				item.name.should.equal( _D[ "insert1" ].name )
				item.users.should.eql( [ "a", "b" ] )

				_G[ "insert1" ] = item

				done()
				return
			return

		it "test $add action", ( done )->
			
			table.set _G[ "insert1" ].id, _.clone( _D[ "update2" ] ), ( err, item )->
				throw err if err

				should.exist( item.id )
				should.exist( item.name )
				should.exist( item.users )

				item.name.should.equal( _D[ "insert1" ].name )
				item.users.should.eql( [ "a", "b", "c" ] )

				_G[ "insert1" ] = item

				done()
				return
			return


		it "test $rem action", ( done )->
			table.set _G[ "insert1" ].id, _.clone( _D[ "update3" ] ), ( err, item )->
				throw err if err

				should.exist( item.id )
				should.exist( item.name )
				should.exist( item.users )

				item.name.should.equal( _D[ "insert1" ].name )
				item.users.should.eql( [ "b", "c" ] )

				_G[ "insert1" ] = item

				done()
				return
			return

		it "test $reset action", ( done )->
			
			table.set _G[ "insert1" ].id, _.clone( _D[ "update4" ] ), ( err, item )->
				throw err if err

				should.exist( item.id )
				should.exist( item.name )
				should.exist( item.users )

				item.name.should.equal( _D[ "insert1" ].name )
				item.users.should.eql( [ "x", "y" ] )

				_G[ "insert1" ] = item

				done()
				return
			return

		it "test $add action with string", ( done )->
			
			table.set _G[ "insert1" ].id, _.clone( _D[ "update5" ] ), ( err, item )->
				throw err if err

				should.exist( item.id )
				should.exist( item.name )
				should.exist( item.users )

				item.name.should.equal( _D[ "insert1" ].name )
				item.users.should.eql( [ "x", "y", "z" ] )

				_G[ "insert1" ] = item

				done()
				return
			return

		it "test $rem action with string", ( done )->
			
			table.set _G[ "insert1" ].id, _.clone( _D[ "update6" ] ), ( err, item )->
				throw err if err

				should.exist( item.id )
				should.exist( item.name )
				should.exist( item.users )

				item.name.should.equal( _D[ "insert1" ].name )
				item.users.should.eql( [ "y", "z" ] )

				_G[ "insert1" ] = item

				done()
				return
			return

		it "test $reset action with string", ( done )->
			
			table.set _G[ "insert1" ].id, _.clone( _D[ "update7" ] ), ( err, item )->
				throw err if err

				should.exist( item.id )
				should.exist( item.name )
				should.exist( item.users )

				item.name.should.equal( _D[ "insert1" ].name )
				item.users.should.eql( [ "y" ] )

				_G[ "insert1" ] = item

				done()
				return
			return

		it "test $add action with empty array", ( done )->
		
			table.set _G[ "insert1" ].id, _.clone( _D[ "update8" ] ), ( err, item )->
				throw err if err

				should.exist( item.id )
				should.exist( item.name )
				should.exist( item.users )

				item.name.should.equal( _D[ "insert1" ].name )
				item.users.should.eql( [ "y" ] )

				_G[ "insert1" ] = item

				done()
				return
			return

		it "test $rem action with empty array", ( done )->
			
			table.set _G[ "insert1" ].id, _.clone( _D[ "update9" ] ), ( err, item )->
				throw err if err

				should.exist( item.id )
				should.exist( item.name )
				should.exist( item.users )

				item.name.should.equal( _D[ "insert1" ].name )
				item.users.should.eql( [ "y" ] )

				_G[ "insert1" ] = item

				done()
				return
			return

		it "update set to null should remove attribute", ( done )->
			
			table.set _G[ "insert1" ].id, _.clone( _D[ "update10" ] ), ( err, item )->
				throw err if err

				should.exist( item.id )
				should.exist( item.name )
				should.not.exist( item.users )

				item.name.should.equal( _D[ "insert1" ].name )

				_G[ "insert1" ] = item

				done()
				return
			return

		it "create the test item2 with empty array as set", ( done )->
		
			table.set _.clone( _D[ "insert2" ] ), ( err, item )->
				throw err if err

				should.exist( item.id )
				should.exist( item.name )
				should.not.exist( item.users )

				item.name.should.equal( _D[ "insert2" ].name )

				_ItemCount++
				_G[ "insert2" ] = item

				done()
				return
			return

		it "create the test item3 with empty array as set", ( done )->
			
			table.set _.clone( _D[ "insert3" ] ), ( err, item )->
				throw err if err

				should.exist( item.id )
				should.exist( item.name )
				should.not.exist( item.users )

				item.name.should.equal( _D[ "insert3" ].name )

				_ItemCount++
				_G[ "insert3" ] = item

				done()
				return
			return

		it "delete test item.", ( done )->
			
			table.del _G[ "insert1" ].id, ( err )->
				throw err if err
				_ItemCount--
				done()
				return
			return

		it "delete test item 2", ( done )->
			
			table.del _G[ "insert2" ].id, ( err )->
				throw err if err
				_ItemCount--
				done()
				return
			return

		it "delete test item 3", ( done )->
		
			table.del _G[ "insert3" ].id, ( err )->
				throw err if err
				_ItemCount--
				done()
				return
			return

	return			