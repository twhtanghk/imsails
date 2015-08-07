Promise = require 'promise'

module.exports =
	# get file content of Model[field] 
	get: (Model, pk, field) ->
		new Promise (fulfill, reject) ->
			Model
				.findOne(pk)
				.then (data) ->
					fulfill data[field]
				.catch reject