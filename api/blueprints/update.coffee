_ = require 'lodash'
actionUtil = require 'sails/lib/hooks/blueprints/actionUtil'
update = require 'sails/lib/hooks/blueprints/actions/update'

module.exports = (req, res) ->
	# remove body.id and query.id where id cannot be updated
	req.body = _.omit req.body, 'id'
	req.query = _.omit req.query, 'id'
	
	# replace id with req.user.id if id == 'me'
	if actionUtil.requirePk(req) == 'me'
		req.params['id'] = req.user.id
	update req, res