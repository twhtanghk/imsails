['DOMAIN', 'TOKENURL', 'CLIENT_ID', 'CLIENT_SECRET'].map (name) ->
  if not (name of process.env)
    throw new Error "process.env.#{name} not yet defined"

domain = process.env.DOMAIN

module.exports =
	timeout: 4000000
	client: 
		id: process.env.CLIENT_ID
		secret: process.env.CLIENT_SECRET
	users: [
		{ id: 'user1', secret: 'password', jid: "user1@#{domain}" }
		{ id: 'user2', secret: 'password', jid: "user2@#{domain}" }
	]
	group: { name: 'group1' } 
	getTokens: ->
		new Promise (fulfill, reject) ->
			url = process.env.TOKENURL
			scope = process.env.OAUTH2_SCOPE?.split(' ') || [ 'User', 'Mobile' ]
			Promise
				.all [
					sails.services.oauth2.token url, module.exports.client, module.exports.users[0], scope
					sails.services.oauth2.token url, module.exports.client, module.exports.users[1], scope
				] 
				.then (res) ->
					fulfill _.map res, (response) ->
						response.body.access_token
				.catch reject
	getUsers: ->
		sails.models.user
			.find username: _.map module.exports.users, (user) ->
				user.id
	getGroup: ->
		sails.models.group
			.findOne name: module.exports.group.name
