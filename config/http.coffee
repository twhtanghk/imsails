csp = require 'helmet-csp'
assert = require 'assert'

[
  'DOMAIN'
  'AUTHURL'
].map (name) ->
  assert process.env[name]?, "process.env.#{name} not yet defined"

module.exports =
	http:
		middleware:
			csp: (req, res, next)->
				host = process.env.DOMAIN
				src = [
					"'self'"
					"filesystem:"
					"data:"
					"http://#{host}"
					"https://#{host}"
					"blob:"
					require('url').parse(process.env.AUTHURL).host
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
