 # MsgController
 #
 # @description :: Server-side logic for managing msgs
 # @help        :: See http://links.sailsjs.org/docs/controllers
_ = require 'lodash'
create = require '../blueprints/create'
find = require '../blueprints/find'
actionUtil = require 'sails/lib/hooks/blueprints/actionUtil'

module.exports =
	create: (req, res) ->
		req.options.values = req.options.values || {}
		_.extend req.options.values, from: req.user.jid
		create(req, res)
		
	find: (req, res) ->
		to = req.query.to
		from = req.user.jid
		req.options.criteria = req.options.criteria || {}
		req.options.criteria.blacklist = req.options.criteria.blacklist || ['limit', 'skip', 'sort', 'populate', 'to']
		req.options.where = req.options.where || {}
		_.extend req.options.where, 
			or: [
				{
					to:		to
					from:	from
				}
				{
					to:		from
					from:	to
				}
			]
		find(req, res)