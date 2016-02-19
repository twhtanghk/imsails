winston = require 'winston'

module.exports = 
	log:
		level:	'info'
		custom:	new winston.Logger
			transports: [
				new winston.transports.Console timestamp: true
			]