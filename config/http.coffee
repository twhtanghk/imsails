express = require 'express'
			
module.exports = 
	http:
		middleware:
			static: express.static('platforms/browser/www')
			order: [
				'startRequestTimer'
				'cookieParser'
				'session'
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