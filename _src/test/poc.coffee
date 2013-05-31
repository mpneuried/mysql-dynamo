mysql = require('mysql')
should = require('should')
_ = require('lodash')

CONFIG = 
	clearTestTableBefore: false
	cretaeAndFillTestTableBefore: false
	iHashes: 500
	iItems: 1000
	verbose: false

randomString = ( string_length = 5, specialLevel = 0 ) ->
	chars = "BCDFGHJKLMNPQRSTVWXYZbcdfghjklmnpqrstvwxyz"
	chars += "0123456789" if specialLevel >= 1
	chars += "_-@:." if specialLevel >= 2
	chars += "!§$%&/()=?*_:;,.-#+¬”#£ﬁ^\\˜·¯˙˚«∑€®†Ω¨⁄øπ•‘æœ@∆ºª©ƒ∂‚å–…∞µ~∫√ç≈¥" if specialLevel >= 3

	randomstring = ""
	i = 0
	
	while i < string_length
		rnum = Math.floor(Math.random() * chars.length)
		randomstring += chars.substring(rnum, rnum + 1)
		i++
	randomstring

randRange = ( lowVal, highVal )->
	Math.floor( Math.random()*(highVal-lowVal+1 ))+lowVal

DB = null

describe 'Proof of concept', ->

	before ( done )->

		DB = mysql.createConnection
			host: 'localhost'
			user: 'root'
			password : 'never'
			database: "simple-dynamo-offline"
			multipleStatements: true

		DB.connect()

		done()
		return

	after ( done )->
		done()

		DB.end()
		return

	describe "Fill DB", ->
		# increase the timeout for filling th db with data
		this.timeout( 20 * 60 * 1000 )
		if CONFIG.clearTestTableBefore
			it "delete existing Table", ( done )->

				statment = """
	DROP TABLE IF EXISTS poc;
				"""

				DB.query statment, ( err, rows, fields )=>
					if err
						throw err
					done()
				return

		if CONFIG.cretaeAndFillTestTableBefore
			it "create Table", ( done )->

				statment = """
	CREATE TABLE IF NOT EXISTS poc (
	  _h varchar(5) NOT NULL DEFAULT '',
	  _r int(11) NOT NULL DEFAULT '0',
	  data varchar(255) DEFAULT NULL,
	  PRIMARY KEY (_h,_r)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8;
				"""

				DB.query statment, ( err, rows, fields )=>
					if err
						throw err
					done()
				return

			it "fill Table", ( done )->
				iDone = 0
				iCount = 0
				for iH in [1..CONFIG.iHashes]
					statments = []

					_hash = randomString( 5, 1 )

					for iItem in [1..CONFIG.iItems]

						statments.push "INSERT INTO poc (_h, _r, data) VALUES (#{mysql.escape(_hash)}, #{iItem}, #{ mysql.escape( randomString( randRange( 20,250 ), 3 ) )})"

					DB.query statments.join("; "), ( err, rows, fields )=>
						if err
							throw err
						iDone++
						iCount = iCount + rows.length
						if iDone is CONFIG.iHashes
							console.log "Inserted #{iCount} Rows"
							done()
						return
				return
		

	describe 'TEST', ->

		hashes = []
		ranges = []
		testCount = 2
		
		it "Get the number of elements in the table", ( done )->
			

			DB.query "SELECT TABLE_ROWS as count FROM information_schema.tables WHERE table_schema = database() AND table_name = 'poc'", ( err, rows )=>
				throw err if err
				rows.length.should.equal( 1 )
				#should.exist( rows[ 0 ] )
				#should.exist( rows[ 0 ].count )
				console.log rows[ 0 ].count
				done()
				return
			return
		
		it "Get some random Hashes", ( done )->

			DB.query "SELECT _h FROM poc GROUP BY _h ORDER BY RAND() LIMIT #{testCount}", ( err, rows )=>
				throw err if err
				hashes = _.pluck( rows, "_h" )
				console.log "#{testCount} Random Hashes #{ hashes.join(", ") }" if CONFIG.verbose
				done()
				return
			return

		it "Get som random Range Numbers", ( done )->

			for idx in [1..testCount]
				ranges.push( randRange( 1,1000 ) )
			console.log "#{testCount} Random Ranges #{ ranges.join(", ") }" if CONFIG.verbose
			done()
			return

		it "Performance test a Range query", ( done )->
			statments = []
			for _h, idx in hashes

				statments.push """
					SELECT _h, _r FROM poc
					WHERE _h = "#{_h}"
					AND _r > #{ ranges[ idx ] }
					LIMIT 30
				"""
			console.time( "Duration of #{testCount} range selects with #{testCount} results in one query" )
			DB.query statments.join( ";" ), ( err, results, fields )=>
				console.timeEnd( "Duration of #{testCount} range selects with #{testCount} results in one query" )
				if err
					throw err
				if statments.length is 1
					results = [ results ] 
				for rows, idx in results
					for row in rows
						row._h.should.equal( hashes[ idx ] )

					rows.length.should.be.within( 1, 30 )

				done()
				return

			return