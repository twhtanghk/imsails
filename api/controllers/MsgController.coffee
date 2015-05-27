module.exports =
	find:		(req, res) ->
		[fulfill, reject] = ModelService.handler(res)
		ModelService.Msg.find(req, res).then fulfill, reject
	
	create:		(req, res) ->
		[fulfill, reject] = ModelService.handler(res)
		ModelService.Msg.create(req, res).then fulfill, reject