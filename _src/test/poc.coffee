mysql = require('mysql')
_ = require('lodash')

CONFIG = 
	clearTestTableBefore: false
	cretaeAndFillTestTableBefore: false
	iHashes: 300
	iItems: 1000

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

		it "Get som random Hashes", ( done )->

			DB.query "SELECT _h FROM poc GROUP BY _h LIMIT 10 OFFSET #{randRange( 1,100 )}", ( err, rows )=>
				throw err if err
				hashes = _.pluck( rows, "_h" )
				console.log "10 Random Hashes #{ hashes.join(", ") }"
				done()
				return
			return

		it "Test", ( done )->
			DB.query "SELECT 1 + 1 AS solution", ( err, rows, fields )=>
				if err
					throw err
				console.log rows
				done()
				return

			return