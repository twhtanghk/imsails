env = require '../../env.coffee'
req = require 'supertest'		
path = require 'path'
util = require 'util'
_ = require 'lodash'
require 'shelljs/global'
fs = require 'fs'
Promise = require 'promise'

describe 'GroupController', ->
	@timeout env.timeout
	
	tokens = null
	users = null
	group = null
	
	before (done) ->
		env.getTokens()
			.then (res) ->
				tokens = res
				env.getUsers()
					.then (res) ->
						users = res
						done()
			.catch done
						
	describe 'create', ->
		it 'group', (done) ->
			req sails.hooks.http.app
				.post '/api/group'
				.set 'Authorization', "Bearer #{tokens[0]}"
				.send
					jid: 		env.group.jid
					name:		env.group.name
					type:		'Members-Only'
				.expect (res) ->
					group = res.body
				.expect 201
				.end done
			
		_.each users, (user) ->	
			it 'add users into group.members', (done) ->
				req sails.hooks.http.app
					.post "/api/group/#{group.id}/members/#{user.id}"
					.set 'Authorization', "Bearer #{tokens[0]}"
					.expect 200
					.end done
						
		it "add user into group.moderators", (done) ->
			req sails.hooks.http.app
				.post "/api/group/#{group.id}/moderators/#{users[1].id}"
				.set 'Authorization', "Bearer #{tokens[0]}"
				.expect 200
				.end done
				
	describe 'read', ->
		it 'group created by me', (done) ->
			req sails.hooks.http.app
				.get '/api/group/me'
				.set 'Authorization', "Bearer #{tokens[0]}"
				.expect 200
				.end done
		
		it 'group by name', (done) ->
			req sails.hooks.http.app
				.get "/api/group/name/#{group.name}"
				.set 'Authorization', "Bearer #{tokens[0]}"
				.expect 200
				.end done
				
	describe 'delete', ->
		it 'user from group.members', (done) ->
			req sails.hooks.http.app
				.del "/api/group/#{group.id}/members/#{users[0].id}"
				.set 'Authorization', "Bearer #{tokens[0]}"
				.expect 200
				.end done