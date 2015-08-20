module.exports = (req, res, next) ->
	req.body = _.omit req.body, 'id', 'jid', 'updatedAt', 'createdAt', 'createdBy'
	req.query = _.omit req.query, 'id', 'jid', 'updatedAt', 'createdAt', 'createdBy'
	next()