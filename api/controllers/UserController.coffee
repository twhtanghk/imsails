module.exports =
	find:		(req, res) ->
		[fulfill, reject] = ModelService.handler(res)
		ModelService.User.find(req, res).then fulfill, reject
	
	findOne:	(req, res) ->
		[fulfill, reject] = ModelService.handler(res)
		ModelService.User.findOne(req, res).then fulfill, reject
			
	update:		(req, res) ->
		[fulfill, reject] = ModelService.handler(res)
		ModelService.User.update(req, res).then fulfill, reject