express = require 'express'
csp = require 'helmet-csp'

module.exports =
	http:
		middleware:
			static: express.static('platforms/browser/www')
			csp: (req, res, next)->
				host = req.headers['x-forwarded-host'] || req.headers['host']
				ret = csp
					directives:
						connectSrc: [ "'self'", "ws://#{host}", "wss://#{host}" ]
						styleSrc: [ "'self'", "'unsafe-inline'" ]
						scriptSrc: [ "'self'", "'unsafe-inline'", "'unsafe-eval'" ]
				ret req, res, next
			order: [
				'cookieParser'
				'session'
				'bodyParser'
				'compress'
				'methodOverride'
				'csp'
				'router'
				'static'
				'www'
				'favicon'
				'404'
				'500'
			]
