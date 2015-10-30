isAuth = require './isAuth.coffee'

module.exports = (req, res, next) ->
	req.headers.Authorization ?= "Bearer #{req.param('access_token')}"
	isAuth(req, res, next)