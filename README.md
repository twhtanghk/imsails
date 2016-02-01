# imsails

Instant messaging app to interface server with sailsjs rest or socket.io API


Server API
---------------------------------------------------------
## user

* attributes

	see [api/models/User.coffee](https://github.com/twhtanghk/imsails/blob/master/api/models/User.coffee)
		
* api

	```
	get /api/user - list users for the specified pagination/sorting parameters skip, limit, sort
    get /api/user/:id - read user attributes of the specified id
    get /user/photo/:id - get user photo 
    get /api/user/me - read user attributes of current login user
    put /api/user/me - update user attributes of current login user excluding attribute id, jid, photoUrl 
	```

## group

* attributes
	
	see [api/models/Group.coffee](https://github.com/twhtanghk/imsails/blob/master/api/models/Group.coffee)
	
* api
	```
	post /api/group - create group with the specified attributes excluding id, jid, photoUrl
	post /api/group/:parentid/members/:id - add user with :id into group with :parentid as members
	post /api/group/:parentid/moderators/:id - add user with :id into group with :parentid as moderators
    get /api/group - list all public groups (moderated or unmoderated)
    get /api/group/membersOnly - list private groups (members only) with current login user as member
    get /api/group/me - list groups created by current login user
    get /api/group/name/:name - get group details with specified name created by current login user
    get /api/group/:id - get group details with specified group id
    get /group/photo/:id - get group photo
    put /api/group/:id - update group attributes of the specified id exlcuding id, jid, photoUrl
    del /api/group/:id - delete group of the specified id
    del /api/group/:id/members - remove current login user from  member list of the specified group (leave group)
    del /api/group/:id/moderators - remove current login user from  moderator list of the specified group (leave group)
	```

## roster
   
* attributes

	see [api/models/Roster.coffee](https://github.com/twhtanghk/imsails/blob/master/api/models/Roster.coffee)

* api

	``` 
    post /api/roster - create a roster item with the specified attributes excluding id, jid
    get /api/roster - list all roster items for current login user
    del /api/roster/:id - delete roster item of the specified jid
	```

## msg

* attributes
	
	see [api/models/Msg.coffee](https://github.com/twhtanghk/imsails/blob/master/api/models/Msg.coffee)

* api
	```
    get /api/msg - read message history for the specified chat type (type) and target user or group jid (to) (e.g. {type: 'chat', to: 'user@mob.myvnc.com'} or {type: 'groupchat', to: 'news@muc.mob.myvnc.com'})
    get /api/msg/file/:id - get file attachment for the specified message id
    post /api/msg - send message with the specified attributes
    post /api/msg/file - send file attachment with the specified attributes
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