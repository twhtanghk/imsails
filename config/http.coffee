express = require 'express'
csp = require 'helmet-csp'

module.exports =
	http:
		middleware:
			static: express.static('platforms/browser/www')
			csp: (req, res, next)->
				host = req.headers['x-forwarded-host'] || req.headers['host']
				src = [
					"'self'"
					"filesystem:"
					"data:"
					"http://#{host}"
					"https://#{host}"
					"https://mob.myvnc.com"
				]
				ret = csp
					directives:
						defaultSrc: src
						connectSrc: [ "ws://#{host}", "wss://#{host}" ].concat src
						styleSrc: [ "'unsafe-inline'" ].concat src
						scriptSrc: [ "'unsafe-inline'", "'unsafe-eval'" ].concat src
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
