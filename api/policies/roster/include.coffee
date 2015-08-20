# allow to update field newmsg only
module.exports = (req, res, next) ->
	req.body = _.pick req.body, 'newmsg'
	req.query = _.pick req.query, 'newmsg'
	next()