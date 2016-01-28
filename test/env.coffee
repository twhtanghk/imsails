agent = require 'https-proxy-agent'

module.exports =
	timeout: 400000
	client: 
		id:		'client id'
		secret: 'client secret'
	users: [
		{ id: 'user1', secret: 'password' }
		{ id: 'user2', secret: 'password' }
	]