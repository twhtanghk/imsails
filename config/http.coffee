express = require 'express'
prefix = (req, res, next) ->
	p = new RegExp('^' + sails.config.path)
	req.url = req.url.replace(p, '')
	next()
		
module.exports = 
	http:
		middleware:
			static: express.static('www')
			prefix: prefix
			order: [
				'startRequestTimer'
				'cookieParser'
				'session'
				'prefix'
				'bodyParser'
				'compress'
				'methodOverride'
				'$custom'
				'router'
				'static'
				'www'
				'favicon'
				'404'
				'500'
			]