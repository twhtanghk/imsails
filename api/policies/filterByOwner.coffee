module.exports = (req, res, next) ->
	req.options.where ?= {}
	req.options.where.createdBy = req.user.id
	next()