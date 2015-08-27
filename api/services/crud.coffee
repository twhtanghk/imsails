Promise = require 'promise'
actionUtil = require 'sails/lib/hooks/blueprints/actionUtil'

module.exports = 
	create: (req) ->
		Model = actionUtil.parseModel(req)
		data = actionUtil.parseValues(req)
		
		new Promise (fulfill, reject) ->
			Model.create(data)
				.then (newInstance) ->
					if req._sails.hooks.pubsub
						if req.isSocket
							Model.subscribe(req, newInstance);
							Model.introduce(newInstance);
						Model.publishCreate(newInstance, !req.options.mirror && req)
					fulfill(newInstance)
				.catch reject
				
	find: (req) ->
		Model = actionUtil.parseModel req
		cond = actionUtil.parseCriteria req
		count = Model.count()
			.where( cond )
			.toPromise()
		query = Model.find()
			.where( cond )
			.populateAll()
			.limit( actionUtil.parseLimit(req) )
			.skip( actionUtil.parseSkip(req) )
			.sort( actionUtil.parseSort(req) )
			.toPromise()
		
		new Promise (fulfill, reject) ->
			Promise.all([count, query])
				.then (data) ->
					if req._sails.hooks.pubsub and req.isSocket
						Model.subscribe(req, data[1])
						if Model.autoWatch or req.options.autoWatch
							Model.watch(req)
						_.each data[1], (record) ->
							actionUtil.subscribeDeep(req, record)
					fulfill
						count:		data[0]
						results:	data[1]
				.catch reject