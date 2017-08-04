_ = require 'lodash'
req = require 'supertest-as-promised'    
Promise = require 'bluebird'

describe 'GroupController', ->

  group = null

  before ->
    Promise
      .map users, (user) ->
        sails.models.user
          .findOne username: user.id
          .then (imuser) ->
            _.extend user, imuser
            
  describe 'create', ->
    it 'group', ->
      req sails.hooks.http.app
        .post '/api/group'
        .set 'Authorization', "Bearer #{users[0].token}"
        .send
          name: 'group1'
          type: 'Members-Only'
          moderators: [users[0]]
          members: [users[1]]
        .expect 201
        .then (res) ->
          group = res.body
          sails.models.group
            .findOne id: group.id
            .populateAll()
        .then (group) ->
          rosterExist = (group, createdBy) ->
            sails.models.roster
              .findOne 
                group: group.id
                createdBy: createdBy.id
              .then (roster) ->
                if _.isUndefined roster
                  throw new Error "roster not properly created for group #{group.jid}"
          usersRoster = (users) ->
            Promise.all _.map users, (user) ->
              rosterExist group, user

          Promise.all [usersRoster(group.moderator), usersRoster(group.member)] 
      
    it 'add users into group.members', ->
      Promise.map users, (user) ->  
        req sails.hooks.http.app
          .post "/api/group/#{group.id}/members/#{user.id}"
          .set 'Authorization', "Bearer #{users[0].token}"
          .expect 200
            
    it "add user into group.moderators", ->
      req sails.hooks.http.app
        .post "/api/group/#{group.id}/moderators/#{users[1].id}"
        .set 'Authorization', "Bearer #{users[0].token}"
        .expect 200
        
  describe 'read', ->
    it 'group created by me', ->
      req sails.hooks.http.app
        .get '/api/group/me'
        .set 'Authorization', "Bearer #{users[0].token}"
        .expect 200
    
    it 'group by name', ->
      req sails.hooks.http.app
        .get "/api/group/name/#{group.name}"
        .set 'Authorization', "Bearer #{users[0].token}"
        .expect 200
        
  describe 'send message', ->
    it "to group", ->
      req sails.hooks.http.app
        .post '/api/msg'
        .set 'Authorization', "Bearer #{users[0].token}"
        .send
          to: group.jid
          body: "msg from #{users[0].id} to #{group.jid}"
        .expect 201
        .then ->
          sails.models.group
            .findOne name: group.name
            .populateAll()
        .then (group) ->
          Promise.map group.subscribers(), (user) ->
            sails.models.roster
              .findOne
                group: group.id
                createdBy: user.id
              .then (roster) ->
                if _.isUndefined roster
                  throw new Error "roster #{group.name} for #{user.username} not properly created"

  describe 'delete', ->
    it 'user from group.members', ->
      req sails.hooks.http.app
        .del "/api/group/#{group.id}/members/#{users[0].id}"
        .set 'Authorization', "Bearer #{users[0].token}"
        .expect 200

    it "group", ->
      req sails.hooks.http.app
        .del "/api/group/#{group.id}"
        .set 'Authorization', "Bearer #{users[0].token}"
        .expect 200
        .then ->
          sails.models.msg
            .find
              to: group.jid
        .then (msgs) ->
          if msgs.length != 0
            throw new Error "msgs for #{group.name} not completely deleted"
        .then ->
          sails.models.roster
            .find jid: group.jid
        .then (roster) ->
          if roster.length != 0
            throw new Error "roster for #{group.name} not completely deleted"
