env = require '../../env.coffee'
req = require 'supertest-as-promised'    
path = require 'path'
util = require 'util'
_ = require 'lodash'
require 'shelljs/global'
fs = require 'fs'
Promise = require 'bluebird'

describe 'GroupController', ->
  @timeout env.timeout
  
  tokens = null
  users = null
  group = null
  
  before ->
    env.getTokens()
      .then (res) ->
        tokens = res
        env.getUsers()
      .then (res) ->
        users = res
            
  describe 'create', ->
    it 'group', ->
      req sails.hooks.http.app
        .post '/api/group'
        .set 'Authorization', "Bearer #{tokens[0]}"
        .send
          name: env.group.name
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
      Promise.all _.map users, (user) ->  
        req sails.hooks.http.app
          .post "/api/group/#{group.id}/members/#{user.id}"
          .set 'Authorization', "Bearer #{tokens[0]}"
          .expect 200
            
    it "add user into group.moderators", ->
      req sails.hooks.http.app
        .post "/api/group/#{group.id}/moderators/#{users[1].id}"
        .set 'Authorization', "Bearer #{tokens[0]}"
        .expect 200
        
  describe 'read', ->
    it 'group created by me', ->
      req sails.hooks.http.app
        .get '/api/group/me'
        .set 'Authorization', "Bearer #{tokens[0]}"
        .expect 200
    
    it 'group by name', ->
      req sails.hooks.http.app
        .get "/api/group/name/#{group.name}"
        .set 'Authorization', "Bearer #{tokens[0]}"
        .expect 200
        
  describe 'delete', ->
    it 'user from group.members', ->
      req sails.hooks.http.app
        .del "/api/group/#{group.id}/members/#{users[0].id}"
        .set 'Authorization', "Bearer #{tokens[0]}"
        .expect 200
        .then ->
          sails.models.roster
            .find
              group: group.id
        .then (groups) ->
          if groups.length != 0
            throw new Error "roster for #{group.jid} not completely deleted"
