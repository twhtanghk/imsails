csp = require 'helmet-csp'

module.exports =
	http:
		middleware:
			csp: (req, res, next)->
				host = req.headers['x-forwarded-host'] || req.headers['host']
				src = [
					"'self'"
					"filesystem:"
					"data:"
					"http://#{host}"
					"https://#{host}"
					"blob:"
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
				'www'
				'favicon'
				'404'
				'500'
			]
