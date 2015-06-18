actionUtil = require 'sails/lib/hooks/blueprints/actionUtil'
findOne = require 'sails/lib/hooks/blueprints/actions/findOne'

module.exports = (req, res) ->
	if actionUtil.requirePk(req) == 'me'
		req.params['id'] = req.user.id
	findOne req, res