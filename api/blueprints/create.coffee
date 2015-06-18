_ = require 'lodash'
create = require 'sails/lib/hooks/blueprints/actions/create'

module.exports = (req, res) ->
	req.options.values = req.options.values || {}
	_.extend req.options.values, createdBy: req.user
	create(req, res)