module.exports =
	models:
		connection: 'mongo'
		migrate:	'alter'
	connections:
		mongo:
			adapter: 'sails-mongo'
			host: 'localhost'
			port: 27017
			user: 'imrw'
			password: 'pass1234'
			database: 'im'