express = require 'express'
			
module.exports = 
	http:
		middleware:
			static: express.static('platforms/browser/www')
			prefix: (req, res, next) ->
				p = new RegExp('^' + sails.config.path)
				req.url = req.url.replace(p, '')
				next()
			resHeader: (req, res, next) ->
				res.set 
					"Content-Security-Policy": "default-src 'self' data:; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; connect-src 'self' ws://localhost:3000; child-src 'self' https://mob.myvnc.com https://*.google.com; object-src 'none'; media-src 'self' data:; img-src 'self' data:"
				next()
			order: [
				'startRequestTimer'
				'cookieParser'
				'session'
				'prefix'
				'resHeader'
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