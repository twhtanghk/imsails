env = require '../../env.coffee'
req = require 'supertest'		
path = require 'path'
util = require 'util'
_ = require 'lodash'
rest = require '../../../api/services/rest.coffee'
agent = require 'https-proxy-agent'
require 'shelljs/global'
fs = require 'fs'
Promise = require 'promise'

describe 'GroupController', ->
	@timeout env.timeout
	
	users = null
	group = null
	token = null
	
	domain = 'mob.myvnc.com'
	
	before (done) ->
		url = 'https://mob.myvnc.com/org/oauth2/token/'
		scope = [ "https://mob.myvnc.com/org/users", "https://mob.myvnc.com/mobile"]
	
		tasks = [
			sails.models.user.create
				jid:		"user1@#{domain}"
				url:		"user1@#{domain}"
				username:	'user1'
				email:		"user1@#{domain}"
			sails.models.user.create
				jid:		"user2@#{domain}"
				url:		"user2@#{domain}"
				username:	'user2'
				email:		"user2@#{domain}"
			rest().token url, env.client, env.user, scope
		]
		Promise
			.all tasks 
			.then (res) ->
				token = res[2].body.access_token
				users = res.splice 0, 2
				done()
			.catch done	
						
	describe 'create', ->
		it 'group', (done) ->
			req sails.hooks.http.app
				.post '/api/group'
				.set 'Authorization', "Bearer #{token}"
				.send
					jid: 		"group1@domain"
					name:		'group1'
					type:		'Members-Only'
				.expect (res) ->
					group = res.body
				.expect 201
				.end done
				
		it 'add users into group.members', (done) ->
			Promise
				.all _.map users, (user) ->
					new Promise (fulfill, reject) ->
						try
							req sails.hooks.http.app
								.post "/api/group/#{group.id}/members/#{user.id}"
								.set 'Authorization', "Bearer #{token}"
								.expect (res) ->
									console.log res.body
								.expect 200
								.end fulfill
						catch e
							reject e
				.then ->
					done()
				.catch done
		
		it 'add user2 into group.moderators', (done) ->
			req sails.hooks.http.app
				.post "/api/group/#{group.id}/moderators/#{users[1].id}"
				.set 'Authorization', "Bearer #{token}"
				.expect (res) ->
					console.log res.body
				.expect 200
				.end done
				
	describe 'read', ->
		it 'group created by me', (done) ->
			req sails.hooks.http.app
				.get '/api/group/me'
				.set 'Authorization', "Bearer #{token}"
				.expect (res) ->
					console.log res.body
				.expect 200
				.end done
		
		it 'group by name', (done) ->
			req sails.hooks.http.app
				.get '/api/group/name/group1'
				.set 'Authorization', "Bearer #{token}"
				.expect (res) ->
					console.log res.body
				.expect 200
				.end done
				
	describe 'delete', ->
		it 'user1 from group.members', (done) ->
			req sails.hooks.http.app
				.del "/api/group/#{group.id}/members/#{users[0].id}"
				.set 'Authorization', "Bearer #{token}"
				.expect (res) ->
					console.log res.body
				.expect 200
				.end done