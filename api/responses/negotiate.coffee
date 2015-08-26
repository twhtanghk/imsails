module.exports = (err) ->
	statusCode = err.status || 500
	body = err

	try
		@res.status statusCode
	catch e
		sails.log.error e

	switch
		when statusCode == 403
			return @res.forbidden(body)
		when statusCode == 404
			return @res.notFound(body)
		when statusCode >= 400 and statusCode < 500
			return @res.badRequest(body)
		else
			return @res.serverError(body)