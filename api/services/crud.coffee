_ = require 'lodash'
Promise = require 'bluebird'
actionUtil = require 'sails/lib/hooks/blueprints/actionUtil'

module.exports =
	create: (req) ->
		Model = actionUtil.parseModel(req)
		data = actionUtil.parseValues(req)

		Model.create(data)
			.then (newInstance) ->
				if req._sails.hooks.pubsub
					if req.isSocket
						Model.subscribe(req, newInstance);
						Model.introduce(newInstance);
					Model.publishCreate(newInstance, !req.options.mirror && req)
				Promise.resolve newInstance

	find: (req) ->
		Model = actionUtil.parseModel req
		cond = actionUtil.parseCriteria req
		count = Model.count()
			.where( cond )
			.toPromise()
		query = Model
			.find()
			.where cond
			.limit actionUtil.parseLimit(req)
			.skip actionUtil.parseSkip(req)
			.sort actionUtil.parseSort(req)
		query = actionUtil.populateRequest query, req
			.toPromise()

		Promise.all([count, query])
			.then (data) ->
				if req._sails.hooks.pubsub and req.isSocket
					Model.subscribe(req, data[1])
					if Model.autoWatch or req.options.autoWatch
						Model.watch(req)
					_.each data[1], (record) ->
						actionUtil.subscribeDeep(req, record)
				Promise.resolve
					count:		data[0]
					results:	data[1]

	_findOrCreate: (req, Model, cond, data) ->
		Model.findOrCreate(cond, data)
			.then (newInstance) ->
				if req._sails.hooks.pubsub
					if req.isSocket
						Model.subscribe(req, newInstance)
						Model.introduce(newInstance)
					Model.publishCreate(newInstance, !req.options.mirror && req)
				Promise.resolve newInstance
