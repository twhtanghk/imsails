env = require '../../env.coffee'

describe 'message', ->
  describe 'push', ->
    it 'create', ->
      sails.models.roster
        .findOne jid: users[1].jid
        .populateAll()
        .then (roster) ->
          sails.services.gcm
            .push users[1].token, roster, 'testing'
