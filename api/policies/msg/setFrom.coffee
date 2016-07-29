module.exports = (req, res, next) ->
	req.body.from = req.user.jid
	next()
