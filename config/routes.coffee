module.exports = 
	routes:
		'get /user/photo/:id':
			controller:		'UserController'
			action:			'getPhoto'
		'get /group/membersOnly':
			controller:		'GroupController'
			action:			'membersOnly'
		'get /group/photo/:id':
			controller:		'GroupController'
			action:			'getPhoto'