_ = require 'lodash'

# check if authenticated user is model owner  
module.exports = (req, res, next) ->
	
	Model = ModelService.actionUtil.parseModel(req)
	pk = ModelService.actionUtil.requirePk(req)
	cond = _.extend ModelService.actionUtil.parseCriteria(req), createdBy: req.user
	
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