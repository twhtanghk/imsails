_ = require 'lodash'
actionUtil = require 'sails/lib/hooks/blueprints/actionUtil'

# check if authenticated user is model owner  
module.exports = (req, res, next) ->
	
	model = req.options.model || req.options.controller
	Model = actionUtil.parseModel(req)
	pk = actionUtil.requirePk(req)
	cond = 
		if model == 'user' and (pk == 'me' or pk == req.user.id)
			id:			req.user.id
		else
			id:			pk
			createdBy:	req.user.id
	
	Model.findOne()
		.where( cond )
		.exec (err, data) ->
			if err
				res.serverError err
			else
				if data
					next()
				else
					res.notFound()