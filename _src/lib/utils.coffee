module.exports =

	# simple serial flow controll
	runSeries: (fns, callback) ->
		return callback()	if fns.length is 0
		completed = 0
		data = []
		iterate = ->
			fns[completed] (results) ->
				data[completed] = results
				if ++completed is fns.length
					callback data	if callback
				else
					iterate()

		iterate()

	# simple parallel flow controll
	runParallel: (fns, callback) ->
		return callback() if fns.length is 0
		started = 0
		completed = 0
		data = []
		iterate = ->
			fns[started] ((i) ->
				(results) ->
					data[i] = results
					if ++completed is fns.length
						callback data if callback
						return
			)(started)
			iterate() unless ++started is fns.length

		iterate()