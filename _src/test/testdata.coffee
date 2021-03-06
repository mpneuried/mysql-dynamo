module.exports = 
	"Employees": 
		"insert1": { id:"1234567890", name: "First employee", email: "first@employee.com", age: 20, additional: "more ... "  }
		"insert2": { name: "Second employee", email: "second@employee.com", age: 30, additional: "more ... " }
		"insert3": { name: "Third employee", email: "third@employee.com", age: 78 }
		"insert4": { id:"9999999", name: "Invalid employee", email: "invalid@employee.com", age: 99 }

		"update1": { name: "First employee", additional: "" }
		"update2": { name: "Second employee Update", email: "second@employee.com", age: 35, additional: null }
		"update3": { name: "Third employee Conditional Update", email: "third@employee.com", age: 35 }
		"update3_2": { age: { "$add": 5 } }
		"update3_3": { name: "Third employee Conditional Update", email: "third@employee.com", age: null }
		"update4": { id:"666", name: "New employee Update", email: "new@employee.com", age: 55 }
	"Todos": 
		"insert1": { id: "123456", title: "First", done: 0 }
		"insert2": { id: "123456", title: "Second", done: 0  }

	"Rooms": 
		"insert1": { name: "First", users: [ "a" ] }
		"insert2": { name: "Second", users: [] }
		"insert3": { name: "Third", users: null }
		"update1": { name: "First", users: [ "a", "b" ] }
		"update2": { name: "First", users: { "$add": [ "b", "c" ] } }
		"update3": { name: "First", users: { "$rem": [ "a" ] } }
		"update4": { name: "First", users: { "$reset": [ "x", "y" ] } }
		"update5": { name: "First", users: { "$add": "z" } }
		"update6": { name: "First", users: { "$rem": "x" } }
		"update7": { name: "First", users: { "$reset": "y" } }
		"update8": { name: "First", users: { "$add": [] } }
		"update9": { name: "First", users: { "$rem": [] } }
		"update10": { name: "First", users: null }

	"Logs1": 
		"inserts": [
			{ t: 1, title: "1: I", user: "A" }
			{ t: 2, title: "1: II", user: "A" }
			{ t: 3, title: "1: III", user: "B" }
			{ t: 4, title: "1: IV", user: "A" }
			{ t: 5, title: "1: V", user: "C" }
			{ t: 6, title: "1: VI", user: "B" }
			{ t: 7, title: "1: VII", user: "A" }
			{ t: 8, title: "1: VIII", user: "C" }
			{ t: 9, title: "1: IX", user: "B" }
			{ t: 10, title: "1: X", user: "A" }
			{ t: 11, title: "1: XI", user: "D" }
			{ t: 12, title: "1: XII", user: "A" }
		]

	"Logs2": 
		"inserts": [
			{ t: 1, title: "2: I", user: "A" }
			{ t: 2, title: "2: II", user: "A" }
			{ t: 3, title: "2: III", user: "B" }
			{ t: 4, title: "2: IV", user: "A" }
			{ t: 5, title: "2: V", user: "C" }
			{ t: 6, title: "2: VI", user: "B" }
			{ t: 7, title: "2: VII", user: "A" }
			{ t: 8, title: "2: VIII", user: "C" }
			{ t: 9, title: "2: IX", user: "B" }
			{ t: 10, title: "2: X", user: "A" }
			{ t: 11, title: "2: XI", user: "D" }
			{ t: 12, title: "2: XII", user: "A" }
		]