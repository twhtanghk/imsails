_ = require 'lodash'
req = require 'supertest-as-promised'    
Promise = require 'promise'

describe 'UserController', ->
  
  describe 'create', ->
    it "users", ->
      _.map users, (user) ->
        req sails.hooks.http.app
          .get '/api/user'
          .set 'Authorization', "Bearer #{user.token}"
          .expect 200
          .then ->
            sails.models.user.findOne username: user.id
          .then (model) ->
            if _.isUndefined model
              throw new Error "user #{user.id} not properly created"
