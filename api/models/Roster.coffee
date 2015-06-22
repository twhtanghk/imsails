 # Roster.coffee
 #
 # @description :: TODO: You might write a short summary of how this model works and what it represents here.
 # @docs        :: http://sailsjs.org/#!documentation/models

module.exports =

	tableName:	'rosters'
	
	schema:		true
	
	attributes:
		user:
			model:		'user'
			required:	true
		name:
			type: 		'string'
		photoUrl:
			type: 		'string'
		groups:
			type: 		'array'
		createdBy:
			model:		'user'