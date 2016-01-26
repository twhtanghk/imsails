actionUtil = require 'sails/lib/hooks/blueprints/actionUtil'

actionUtil.opts ?= (req) ->
	model:		actionUtil.parseModel req
	where:		actionUtil.parseCriteria req
	limit:		actionUtil.parseLimit req
	skip:		actionUtil.parseSkip req
	sort:		actionUtil.parseSort req
	populate:	req.param 'populate'
	pubsub:
		subscribe:	req._sails.hooks.pubsub and req.isSocket
		watch:		actionUtil.parseModel(req).autoWatch or req.options.autoWatch