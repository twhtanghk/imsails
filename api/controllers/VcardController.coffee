module.exports =
	find:		(req, res) ->
		[fulfill, reject] = ModelService.handler(res)
		ModelService.Vcard.find(req, res).then fulfill, reject
		
	findOne:	ModelService.notImplemented
	
	create:		ModelService.notImplemented
	
	update:		(req, res) ->
		[fulfill, reject] = ModelService.handler(res)
		ModelService.Vcard.update(req, res).then fulfill, reject
	
	destroy:	ModelService.notImplemented
	
	populate:	ModelService.notImplemented
	
	add:		ModelService.notImplemented
	
	remove:		ModelService.notImplemented