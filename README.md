# imsails

Instant messaging app to interface server with sailsjs rest or socket.io API


Server API
---------------------------------------------------------
*   user

```
    get /api/user/:jid - read vcard of the specified jid
```

*   roster
   
``` 
    get /api/roster - list all roster items of current login user
    post /api/roster - create a roster item
    put /api/roster/:jid - update a roster item of the specified jid
    del /api/roster/:jid - delete a roster item of the specified jid
```

*   msg

```
    get /api/msg/:jid - read messages exchange with the specified jid
```

Configuration
=============

*   git clone https://github.com/twhtanghk/imsails.git
*   cd imsails
*   npm install && bower install
*   update environment variables in config/env/development.coffee for server
```
port: 3000
connections:
	mongo:
		driver:		'mongodb'
		host:		'localhost'
		port:		27017
		user:		'imrw'
		password:	'password'
		database:	'im'
session:
	host: 		'localhost'
	port: 		27017
	db:			'im'
	username:	'imrw'
	password:	'password'
```

*	update environment variables in www/js/env.cofffee for client
```
path: '/im'		
server:
	app:
		type:		'io'						# for model to interface with server (io or rest)
		url:		''							# for model urlRoot
		urlRoot:	'http://localhost:3000'		# for socket.io to establish connection
```

*	node_modules/.bin/gulp
*	sails lift --dev