module.exports = 
	routes:
		# list all public groups (moderated or unmoderated) 
		'GET /api/group':
			controller:		'GroupController'
			action:			'find'
			sort:			
				name:	'desc'
				
		# list members only groups with current login user as member
		'GET /api/group/membersOnly':
			controller:		'GroupController'
			action:			'membersOnly'
			sort:			
				name:	'desc'
				
		# list groups created by me
		'GET /api/group/me':
			controller:		'GroupController'
			action:			'findByMe'
			sort:
				name:	'desc'
		
		# find group with the specified group name
		'GET /api/group/name/:name':
			controller:		'GroupController'
			action:			'findOneByName'
		
		# get group photo
		'GET /group/photo/:id':
			controller:		'GroupController'
			action:			'getPhoto'
				
		# remove current login user from the specified group (leave group)
		# to be deprecated (use DELETE /api/group/:id/[members|moderators]/me
		'PUT /api/group/:id/exit':
			controller:		'GroupController'
			action:			'exit'
			
		'GET /api/msg':
			controller:		'MsgController'
			action:			'find'
			sort:			
				createdAt:	'desc'
		'POST /api/msg/file':
			controller:		'MsgController'
			action:			'putFile'
		'GET /api/msg/file/:id':
			controller:		'MsgController'
			action:			'getFile'
		'GET /api/msg/file/thumb/:id':
			controller:		'MsgController'
			action:			'getThumb'
		'GET /api/roster':
			controller:		'RosterController'
			action:			'find'
			sort:		
				lastmsgAt:	'desc'
		'GET /api/user':
			controller:		'UserController'
			action:			'find'
			sort:			
				'name.given':	'asc'
				'name.middle':	'asc'
				'name.family':	'asc'
				email:			'asc'
		'GET /user/photo/:id':
			controller:		'UserController'
			action:			'getPhoto'