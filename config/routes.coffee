module.exports = 
	routes:
		'GET /api/group':
			controller:		'GroupController'
			action:			'find'
			sort:			
				name:	'desc'
		'GET /api/group/membersOnly':
			controller:		'GroupController'
			action:			'membersOnly'
			sort:			
				name:	'desc'
		'GET /group/photo/:id':
			controller:		'GroupController'
			action:			'getPhoto'
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
		'GET /api/roster':
			controller:		'RosterController'
			action:			'find'
			sort:			
				updatedAt:	'desc'
				jid:		'asc'
		'GET /api/user':
			controller:		'UserController'
			action:			'find'
			sort:			
				fullname:	'asc'
		'GET /user/photo/:id':
			controller:		'UserController'
			action:			'getPhoto'