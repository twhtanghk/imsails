env = require '../../env.coffee'

describe 'message', ->
	@timeout env.timeout
	
	tokens = null
	users = env.users
	
	before (done) ->
		env.getTokens()
			.then (res) ->
				tokens = res
				done()
			.catch done
			
	describe 'push', ->
		it 'create', (done) ->
			sails.models.roster
				.findOne jid: users[1].jid
				.populateAll()
				.then (roster) ->
					sails.services.rest()
						.push tokens[1], roster, 'testing'
						.then ->
							done()
				.catch done