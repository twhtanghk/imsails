module.exports = (req, res, next) ->
	req.session.user = req.user.id
	next()