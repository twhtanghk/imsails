module.exports = (req, res, next) ->
	req.body = _.omit req.body, 'photoUrl'
	req.query = _.omit req.query, 'photoUrl'
	next()