 # GroupController
 #
 # @description :: Server-side logic for managing groups
 # @help        :: See http://links.sailsjs.org/docs/controllers

module.exports =
	# return full list of members only group
	membersOnly: (req, res) ->
		sails.models.user
			.findOne()
			.populateAll()
			.where(id: req.user.id)
			.then (user) ->
				if not user
					return res.notFound "No Members-Only group found for the authenticated user #{req.user.fullname}"
				res.ok user.membersOnlyGrps()
			.catch res.serverError