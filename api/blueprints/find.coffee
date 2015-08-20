Promise = require 'promise'
actionUtil = require 'sails/lib/hooks/blueprints/actionUtil'

module.exports = (req, res) ->
	model = actionUtil.parseModel req
	cond = actionUtil.parseCriteria req
	count = model.count()
		.where( cond )
		.toPromise()
	query = model.find()
		.where( cond )
		.populateAll()
		.limit( actionUtil.parseLimit(req) )
		.skip( actionUtil.parseSkip(req) )
		.sort( actionUtil.parseSort(req) )
		.toPromise()
	Promise.all([count, query])
		.then (data) ->
			if req._sails.hooks.pubsub and req.isSocket
				model.subscribe(req, data[1])
				if model.autoWatch or req.options.autoWatch
					model.watch(req)
				_.each data[1], (record) ->
					actionUtil.subscribeDeep(req, record)
			res.ok
				count:		data[0]
				results:	data[1]
		.catch res.serverError