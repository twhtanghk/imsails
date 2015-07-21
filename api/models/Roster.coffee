 # Roster.coffee
 #
 # @description :: TODO: You might write a short summary of how this model works and what it represents here.
 # @docs        :: http://sailsjs.org/#!documentation/models

module.exports =

	tableName:	'rosters'
	
	schema:		true
	
	attributes:
		jid:
			type: 		'string'
			required:	true
			unique:		true
		user:
			model:		'user'
		group:
			model:		'group'
		type:
			type:		'string'
			defaultsTo:	'chat'			# 'chat' or 'groupchat'
		createdBy:
			model:		'user'
			required:	true