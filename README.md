mysql-dynamo
============

[![Build Status](https://secure.travis-ci.org/mpneuried/mysql-dynamo.png?branch=master)](http://travis-ci.org/mpneuried/mysql-dynamo)
[![Build Status](https://david-dm.org/mpneuried/mysql-dynamo.png)](https://david-dm.org/mpneuried/mysql-dynamo)
[![NPM version](https://badge.fury.io/js/mysql-dynamo.png)](http://badge.fury.io/js/mysql-dynamo)

A solution to use the **[simple-dynamo](http://mpneuried.github.io/simple-dynamo/)** interface with a MySQL database. So you can create a offline version of a AWS-DynamoDB project.

*Written in coffee-script*

**INFO: all examples are written in coffee-script**

# Install

```
  npm install mysql-dynamo
```

# API differences to `simple-dynamo`

Compared to the `simple-dynamo` module you only have to make a few smears.

- **Table-Config** `consistent` not existes and will be ignored
- **Table-Config** `overwriteExistingHash` not exists. It always will NOT overwrite existing hashes
- **Table-Config** `combineTableTo` not exists. Within MySQL there is no need to save tables
- **Table-Attribute-Config** `length` The length of a field has to be defined
- **Table-Attribute-Config** `default` The SQL default of a field could be defined
- **Item-Method-Options** `consistent` not existes and will be ignored
- **Item-Method-Options** `overwriteExistingHash` not exists. It always will NOT overwrite existing hashes

**One big difference between the Dynamo and MySQL version is that dynamo can generate undefined attributes on the fly. Th MySQL version will ignore undefined attributes. So all necessary attributes has to be defined within the table definitions**

# Connection and Table

## Initialize

first you have to define the connection and table attributes and get an instance of the simple-dynamo interface.

`new MySqlDynamo( connectionSettings, tables )`

###connection Settings

****
- **tablePrefix** : *( `String` optional )* Option to prefix all generating tables

**MySQL connection settings** 
- **host** : *( `String` required )* MySQL host
- **user** : *( `String` optional: default = `root` )* MySQL user
- **password** : *( `String` optional: default = `secret` )* MySQL password
- **database** : *( `String` optional: default = `database` )* Database name

###table Definition

An Object of Tables.  
The key you are using will be the key to get the table object.

Every object can have the following keys:

- **name** : *( `String` required )*  
Tablename for MySQL
- **hashKey** : *( `String` required )*  
The hash key name of your ids/hashes
- **hashKeyType** : *( `String` optional: default = `S` )*  
The type of the `hashKey`. Possible values are: `S` = String and `N` = Numeric
- **hashKeyLength** : *( `Number` optional: default = `5` for hashKeyType `N` and `255` for hashKeyType `S` )*  
The table field length
- **rangeKey**: *( String optional )*  
The range key name of your range attribute. If not defined the table will be generated without the range methods
- **rangeKeyType**: *( `String` optional: default = `N` )*  
The type of the `rangeKey`. Possible values are: `S` = String and `N` = Numeric
- **rangeKeyLength** : *( `Number` optional: default = `5` for rangeKeyType `N` and `255` for rangeKeyType `S` )*  
The table field length
- **fnCreateHash**: *( `Function` optional: default = `new UUID` )*  
Method to generate a custom hash key.  
- **defaultfields**: *( `Array` optional )*  
List of fields to return as default. If nothing is defined all fields will be received. You always can overwrite this using `options.fields`.  
**Method Arguments**  
  - **attributes**: The given attributes on create  
  - **cb**: Callback method to pass the custom generates id/hash. `cb( "my-special-hash" )`
- **fnCreateRange**: *( `Function` optional: default = `current Timestamp` )*  
Method to generate a custom range key.  
**Method Arguments**  
  - **attributes**: The given attributes on create  
  - **cb**: Callback method to pass the custom generates id/hash. `cb( "my-special-range" )`
- **attributes**: *( `Array of Objects` required )*  
An array of attribute Objects. Which will be validated  
**Attributes keys**
  - **key**: *( `String` required )*  
  Column/Attribute name/key
  - **type**: *( `String` required )*  
  Datatype. possible values are `string` = String, `number` = Numeric and `array` = Array/Set of **Strings**
  - **required**: *( `Boolean` optional: default = `false` )*  
  Validate the attribute to be required. *( Not implemented yet ! )*
  - **length**: *( `Number` optional: default = `255` )*  
  Lentgh of the MySQL DB Filed. If you combine `type` = `string` with a `length`= `+Infinity` the field will generated as type `TEXT` otherwise as `VARCHAR( length )`. If you define a `number` with a length > 11 a type `BIGINT( length )` will be used. On a length <= 11 a type `INT( length )` will be generated.
  - **default** *( `String` optional: default = `` )*  
  The SQL default value
   
 **Example**

```coffee
# import module
MySQLDynamo = require "mysql-dynamo"

# define connection settings
connectionSettings =
	host: "localhost"
	user: "root"
	password: "root"
	database: "myDB"
	
# define tables
tables = 
	"Users":
		name: "users"
		hashKey: "id"

		attributes: [
			{ key: "name", type: "string", required: true }
			{ key: "email", type: "string" }
		]
		
	"Todos":
		name: "todos"
		hashKey: "id"
		rangeKey: "_t"
		rangeKeyType: "N"
		
		fnCreateHash: ( attributes, cb )=>
			cb( attributes.user_id )
			return
		
		attributes: [
			{ key: "title", type: "string", required: true }
			{ key: "done", type: "number" }
		]

# create instance
sqldManager = new MySQLDynamo( connectionSettings, tables )

# connect
sqldManager.connect ( err )->
	console.log( "mysql-dynamo ready to use" )
```

## First connect to MySQL

The module has to know about the existing SQL tables so you have to read them first.  
**If you do not run `.connect()` the module will throw an error everytime** 

**`Manager.connect( fnCallback )` Arguments** : 

- **fnCallback**: *( `Function` required )*  
Callback method. Single arguments on return is the error object. On success the error is `null`
 
**Example**

```coffee
sqldManager.connect ( err )->
	if err
		console.error( "connect ERROR", err )
	else
		console.log( "mysql-dynamo ready to use" )
```

## Create all tables

to create all missing tables just call `.createAll()`.

This is not necessary if you know the tables has been created in the past.

**`Manager.generateAll( fnCallback )` Arguments** : 

- **fnCallback**: *( `Function` required )*  
Callback method. Single arguments on return is the error object. On success the error is `null`

**Example**

```coffee
sqldManager.generateAll ( err )->
	if err
		console.error( "connect ERROR", err )
	else
		console.log( "mysql-dynamo ready to use" )
```

## Get a table instance

To interact with a table you have to retrieve the table object. It's defined in the table-definitions

**`Manager.get( 'tableName' )` Arguments** : 

- **tableName**: *( `String` required )*  
Method to retrieve the instance of a table object.

**Example**

```coffee
tblTodos = sqldManager.get( 'Todos' )
```

## Loop through all tables

Loop trough all table objects

**`Manager.each( eachFn )` Arguments** : 

- **eachFn**: *( `Function` required )*  
Loop method call for every table object

**Example**

```coffee
Manager.each ( tableKey, tableObj )=>
	console.log( "SQL table name", tableObj.tableName )
	return
```

## Destroy a table

destroy table in MySQL. This drops a table from MySQL will all the data

**`Table.destroy( fnCallback )` Arguments** : 

- **fnCallback**: *( `Function` required )*  
Callback method.  
**Method Arguments**  
  - **err**: Usually `null`. On an error a object with `error` and `msg`

**Example**

```coffee
tblTodos.del ( err )->
	if err
		console.error( "destroy ERROR", err )
	else
		console.log( "table destroyed" )
```

# Item handling 

## Write a new item (INSERT)

Create a new item in a select table. You can also add some attributes not defined in the table-definition, which will be saved, too.

**`Table.set( data, options, fnCallback )` Arguments** : 

- **data**: *( `Object` required )*  
The data to save. You can define the hash and/or range key. If not the module will generate a hash/range automatically.  
*Note:* If the used table uses the combined feature and you define the hash-key it's necessary to add the `name` out of the table-config in front of every hash.
- **options**: *( `Object` optional )*  
  - **fields**: *( `Array` )* An array of fields to receive
- **fnCallback**: *( `Function` required )*  
Callback method.  
**Method Arguments**  
  - **err**: Usually `null`. On an error a object with `error` and `msg`
  - **item**: the save item as simple object

**Example**

```coffee
data = 
	title: "My First Todo"
	done: 0
	aditionalData: "Foo bar"
	
tblTodos.set data, ( err, todo )->
	if err
		console.error( "insert ERROR", err )
	else
		console.log( todo )
```

## Get a item (GET)

Get an existing element by id/hash

**`Table.get( id[, options], fnCallback )` Arguments** : 

- **id**: *( `String|Number|Array` required )*  
The id of an element. If the used table is a range table you have to use an array `[hash,range]` as combined id. Otherwise you will get an error. 
- **options**: *( `Object` optional )*  
  - **fields**: *( `Array` )* An array of fields to receive. If nothing is defined all fields are returned.
- **fnCallback**: *( `Function` required )*  
Callback method.  
**Method Arguments**  
  - **err**: Usually `null`. On an error a object with `error` and `msg`
  - **item**: the database item as simple object. If not found `null`

**Example**

```coffee
tblTodos.get 'myTodoId', ( err, todo )->
	if err
		console.error( "get ERROR", err )
	else
		console.log( todo )
```

```coffee
tblRangeTodos.get [ 'myHash', 'myRange' ], ( err, todo )->
	if err
		console.error( "get ERROR", err )
	else
		console.log( todo )
```

## Get many items (MGET)

Get an many existing elements by id/hash in one request

**`Table.mget( [ id1, id2, .. ], options, fnCallback )` Arguments** : 

- **ids**: *( `Array` required )*  
An array of id of an elements. If the used table is a range table you have to use an array of arrays `[hash,range]` as combined id. Otherwise you will get an error. 
- **options**: *( `Object` optional )*  
  - **fields**: *( `Array` )* An array of fields to receive. If nothing is defined all fields are returned.
- **fnCallback**: *( `Function` required )*  
Callback method.  
**Method Arguments**  
  - **err**: Usually `null`. On an error a object with `error` and `msg`
  - **items**: the database items as a array of simple objects. Only existing items will be received. 

**Example**

```coffee
tblTodos.mget [ 'myTodoIdA', 'myTodoIdB' ], ( err, todos )->
	if err
		console.error( "get ERROR", err )
	else
		console.log( todos )
```

```coffee
tblRangeTodos.mget [ [ 'myHash', 1 ], [ 'myHash', 2 ] ], ( err, todos )->
	if err
		console.error( "get ERROR", err )
	else
		console.log( todos )
```

## Update an item (UPDATE)

update an existing item. If you try to update a not existing item it will be created.
To remove a attribute you have to set the value to `null`

**`Table.set( id, data, options, fnCallback )` Arguments** : 

- **id**: *( `String|Number|Array` required )*  
The id of an element. If the used table is a range table you have to use an array `[hash,range]` as combined id. Otherwise you will get an error. 
- **data**: *( `Object` required )*  
The data to update. You can redefine the range key. If you pass the hash key it will be ignored
- **options**: *( `Object` optional )*  
For update you can define some options.
  - **fields**: *( `Array` )* An array of fields to receive
  - **conditionals** *( `Object` )* A query object to define a conditional. Only `{"==": value}`, `{"==": null}`, and `{"!=": null}` are allowed. How to build? … have a look at [Jed's Predicates ](https://github.com/jed/dynamo/wiki/High-level-API#wiki-predicates)
- **fnCallback**: *( `Function` required )*  
Callback method.  
**Method Arguments**  
  - **err**: Usually `null`. On an error a object with `error` and `msg`
  - **item**: the database item as simple object. If not found `null`

**Example**

```coffee
data = 
	title: "My First Update"
	done: 1
	
tblTodos.set 'myTodoId', data, ( err, todo )->
	if err
		console.error( "update ERROR", err )
	else
		# note. the key 'aditionalData' will be gone
		console.log( todo )
```

## Delete an item (DELETE)

delete an item by id/hash

**`Table.del( id, fnCallback )` Arguments** : 

- **id**: *( `String|Number|Array` required )*  
The id of an element. If the used table is a range table you have to use an array `[hash,range]` as combined id. Otherwise you will get an error. 
- **fnCallback**: *( `Function` required )*  
Callback method.  
**Method Arguments**  
  - **err**: Usually `null`. On an error a object with `error` and `msg`

**Example**

```coffee
tblTodos.del 'myTodoId', ( err )->
	if err
		console.error( "delete ERROR", err )
	else
		console.log( "delete done" )
```

## Query a table (FIND)

run a query on a table. The module automatically trys to do a `Dynamo.db scan` or `Dynamo query`.

**`Table.find( query, startAt, options, fnCallback )` Arguments** : 

- **query**: *( `Object` : default = `{}` all )*  
A query object. How to build … have a look at [Jed's Predicates ](https://github.com/jed/dynamo/wiki/High-level-API#wiki-predicates)
- **startAt**: *( `String|Number|Array` optional )*  
To realize a paging you can define a `startAt`. Usually the last item of a list. If you define `startAt` with the last item of the previous find you get the next collection of items without the given `startAt` item.  
If the used table is a range table you have to use an array `[hash,range]` as combined `startAt`. Otherwise you will get an error. 
- **options**: *( `Object` optional )*  
  - **fields**: *( `Array` )* An array of fields to receive
  - **limit**: *( `Number` )* Define the max. items to return
  - **forward**: *( `Boolean` default = true  )* define the direction `acs` or `desc` for range querys. 
- **fnCallback**: *( `Function` required )*  
Callback method.  
**Method Arguments**  
  - **err**: Usually `null`. On an error a object with `error` and `msg`
  - **items**: an array of objects found
	

**Example**

```coffee
tblTodos.find {}, ( err, items )->
	if err
		console.error( "delete ERROR", err )
	else
		console.log( "all existend items", items )
```
**Advanced Examples**

```coffee
# create a query to read all todos from last hour
_query = 
	id: { "!=": null }
	_t: { "<": ( Date.now() - ( 1000 * 60 * 60 ) ) }

tblTodos.find , ( err, items )->
	if err
		console.error( "delete ERROR", err )
	else
		console.log( "found items", items )
```

```coffee
# read 4 todos from last hour beginning starting with a known id
_query = 
	id: { "!=": null }
	_t: { "<": ( Date.now() - ( 1000 * 60 * 60 ) ) }

_startAt = "myid_todoItem12"

_options = { "limit": 4, "fields": [ "id", "_t", "title" ] }

tblTodos.find _query, _startAt, _options, ( err, items )->
	if err
		console.error( "delete ERROR", err )
	else
		console.log( "4 found items", items )
```

## Numeric functions

If a field is defined as number you can run simple operations like increase and decrese the value.

To do this you can pass the value of a number as

* `"key": { "$add": 1 }` to increase the number by 1
* `"key": { "$rem": 1 }` to decrease the number by 1
* `"key": { "$reset": 1 }` to set the number by 1

## Working with sets

Dynamo has the ability to work with sets. That means you can save a Set of Strings as an Array.  
During an update you have the ability to add or remove a single value out of the set. Or you can reset the whole set.  

But you can only perform one action per key and you only can use the functionality if defined through the table-definition ( `type:"array"` ).

Existing values will be ignored.

The following key variants are available:

- `"key":[ "a", "b", "c" ]'`: Resets the whole value of the key
- `"key":{ "$add": [ "d", "e" ] }`: Add some values to the set
- `"key":{ "$rem": [ "a", "b" ] }`: remove some values
- `"key":{ "$reset": [ "x", "y" ] }`: reset the whole value. Same as `"key":[ "x", "y" ]'`
- `"key":{ "$add": "d"}`: Add a single value to the set
- `"key":{ "$rem": "a" }`: remove a single value
- `"key":{ "$reset": "y" }`: reset the whole set to a single value. Same as `"key":[ "y" ]'`

**Examples**

```coffee
# Source "key: [ "a", "b", "c" ]"

data = 
    key: [ "x", "y", "z" ]

tblSets.set 'mySetsId', data, ( err, setData )->
    # Result "key: [ "x", "y", "z" ]"
    console.log( setData )
```
```
# Source "key: [ "a", "b", "c" ]"

data = 
    key: { "$add": [ "a", "d", "e" ] }

tblSets.set 'mySetsId', data, ( err, setData )->
    # Result "key: [ "a", "b", "c", "d", "e" ]"
    console.log( setData )
```
```
# Source "key: [ "a", "b", "c" ]"

data = 
    key: { "$rem": [ "a", "b", "x" ] }

tblSets.set 'mySetsId', data, ( err, setData )->
    # Result "key: [ "c" ]"
    console.log( setData )
```
```
# Source "key: [ "a", "b", "c" ]"

data = 
    key: { "$reset": [ "x", "y", "z" ] }

tblSets.set 'mySetsId', data, ( err, setData )->
    # Result "key: [ "x", "y", "z" ]"
    console.log( setData )
```

#Events

To provide a API to react on different events you can listen to a bunch of events.

##Manager Events

- `new-table`: Table object initialized and ready to use. This means only the client model is ready. Eventually you have to create the table first.  
**Event Arguments**  
	- **name**: the name og the table, like you would use with `Manager.get()
	- **Table**: the `Table` object
- `table-generated`: Fired after all a new tables has been generated.
**Event Arguments**  
	- **Meta**: the tables meta-data
- `all-tables-generated`: Fired after all tables are generated.  


##Table Events

- `create-status`: fired on table create.  
**Event Arguments**  
	- **status**: describes the state of table creation. Possible values are: `already-active`, `waiting`, `active`
- `get`: fired after a table.get.  
**Event Arguments**  
	- **item**: the item
- `get-empty`: fired after a table.get with an empty result.  
- `mget`: fired after a table.mget.  
**Event Arguments**  
	- **items**: the items
- `mget-empty`: fired after a table.mget with no results.  
- `create`: fired after a item has been created.  
**Event Arguments**  
	- **item**: the created item
- `update`: fired after a item has been updated.  
**Event Arguments**  
	- **item_new**: the item after the update
- `delete`: fired after a item has been deleted.  
**Event Arguments**  
	- **item_old**: the item before the delete
	
## Changelogs

### 0.3.0 `15. April 2014`

- Do a insert during update for a simple set call. This has been done due to compatibility to dynamo db.

### 0.2.7 `18. Okt. 2013`

- Bugfix adding `combineTableTo` fields to tablename if it's defined

### 0.2.6 `18. Okt. 2013`

- Bugfix converting data

### 0.2.5 `14. Okt. 2013`

- Feature: added numeric functions feature

### 0.2.4 `14. Okt. 2013`

- Bugfix: Fixed like search and changed due to mysql alpha release 9

### 0.2.2 `7. June 2013`

- Bugfix: order by field and startAt for reverse order

### 0.2.2 `7. June 2013`

- Updated readme
- generated the code docs

### 0.2.1 `7. June 2013`

- Added missing destroy table
- Print a a warning on table destroy and table create

### 0.2.0 `7. June 2013`

- Added manager/table option `tablePrefix` to prefix the sql table names
- added manager method `.each()`
- Changed tests to drop the tables before test

### 0.1.4 `6. June 2013`

- Print out a warning if attributes are removed by the validation

### 0.1.3 `6. June 2013`

- Fixed package json to use the correct `mysql-node` version if an older version is already used within the project

### 0.1.2 `6. June 2013`

- Added code docs with docker
- Some small code improvements

### 0.1.1 `6. June 2013`

- Added Readme

### 0.1.0 `5. June 2013`

- Initial version

## Todos

- better validation of the given config-data

### Work in progress

`mysql-dynamo` is work in progress. Your ideas, suggestions etc. are very welcome.

## License 

(The MIT License)

Copyright (c) 2010 TCS &lt;dev (at) tcs.de&gt;

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.