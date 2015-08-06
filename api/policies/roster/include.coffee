_ = require 'lodash'

module.exports = (req, res, next) ->
	req.body = _.pick req.body, 'newmsg'
	req.query = _.pick req.query, 'newmsg'
	next()