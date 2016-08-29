# add criteria to filter group list for current login user  
_ = require 'lodash'

module.exports = (req, res, next) ->
	req.options.where = req.options.where || {}
	_.extend req.options.where, 
		type:	['Unmoderated', 'Moderated']
	next()
