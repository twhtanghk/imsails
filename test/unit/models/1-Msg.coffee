env = require '../../env.coffee'

describe 'message', ->
  @timeout env.timeout
  
  tokens = null
  users = env.users
  
  before ->
    env.getTokens()
      .then (res) ->
        tokens = res
      
  describe 'push', ->
    it 'create', ->
      sails.models.roster
        .findOne jid: users[1].jid
        .populateAll()
        .then (roster) ->
          sails.services.gcm
            .push tokens[1], roster, 'testing'
