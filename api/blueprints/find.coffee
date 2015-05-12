actionUtil = require 'sails/lib/hooks/blueprints/actionUtil'
_ = require 'underscore'
Promise = require 'promise'

###
 * Find Records
 *
 *  get   /:modelIdentity
 *   *    /:modelIdentity/find
 *
 * An API call to find and return model instances from the data adapter
 * using the specified criteria.  If an id was specified, just the instance
 * with that unique id will be returned.
 *
 * Optional:
 * @param {Object} where       - the find criteria (passed directly to the ORM)
 * @param {Integer} limit      - the maximum number of records to send back (useful for pagination)
 * @param {Integer} skip       - the number of records to skip (useful for pagination)
 * @param {String} sort        - the order of returned records, e.g. `name ASC` or `age DESC`
 * @param {String} callback - default jsonp callback param (i.e. the name of the js function returned)
###

module.exports = (req, res) ->
	Model = actionUtil.parseModel(req)

	if actionUtil.parsePk(req)
		return require('sails/lib/hooks/blueprints/actions/findOne')(req,res)

	count = new Promise (fulfill, reject) ->
		Model.count()
			.where( actionUtil.parseCriteria(req) )
			.exec (err, data) ->
				if err?
					reject err
				fulfill data
	query = new Promise (fulfill, reject) ->
		Model.find()
			.where( actionUtil.parseCriteria(req) )
			.limit( actionUtil.parseLimit(req) )
			.skip( actionUtil.parseSkip(req) )
			.sort( actionUtil.parseSort(req) )
			.exec (err, data) ->
				if err?
					reject err
				fulfill data
	Promise.all([count, query])
		.then (data) ->
			ret =
				count:		data[0]
				results:	data[1]
			if req._sails.hooks.pubsub && req.isSocket
				Model.subscribe(req, ret)
			if req.options.autoWatch
				Model.watch(req)
			_.each ret.results, (record) ->
				actionUtil.subscribeDeep(req, record)
			res.ok ret
		.catch res.serverError