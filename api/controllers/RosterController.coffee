 # RosterController
 #
 # @description :: Server-side logic for managing rosters
 # @help        :: See http://links.sailsjs.org/docs/controllers
_ = require 'lodash'
find = require '../blueprints/find'

module.exports =
	find: (req, res) ->
		req.options.where = req.options.where || {}
		_.extend req.options.where, createdBy: req.user.id
		find(req, res)