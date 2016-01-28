env = require '../../env.coffee'
req = require 'supertest'		
path = require 'path'
util = require 'util'
_ = require 'lodash'
require 'shelljs/global'
fs = require 'fs'
Promise = require 'promise'

describe 'MsgController', ->
	@timeout env.timeout
	
	tokens = null
	msgs = []
	
	domain = 'mob.myvnc.com'
	
	before (done) ->
		url = 'https://mob.myvnc.com/org/oauth2/token/'
		scope = [ "https://mob.myvnc.com/org/users", "https://mob.myvnc.com/mobile"]
	
		tasks = [
			sails.services.rest().token url, env.client, env.users[0], scope
			sails.services.rest().token url, env.client, env.users[1], scope
		]
		Promise
			.all tasks 
			.then (res) ->
				tokens = _.map res, (response) ->
					response.body.access_token
				done()
			.catch done	
						
	describe 'create', ->
		it 'text msg', (done) ->
			req sails.hooks.http.app
				.post '/api/msg'
				.set 'Authorization', "Bearer #{tokens[1]}"
				.send
					to: 		"#{env.users[0].id}@#{domain}"
					body:		"msg from #{env.users[0].id} to #{env.users[1].id}"
				.expect (res) ->
					console.log res.body
					msgs[0] = res.body
				.expect 201
				.end done
		
		it 'image attachement', (done) ->
			req sails.hooks.http.app
				.post '/api/msg/file'
				.set 'Authorization', "Bearer #{tokens[1]}"
				.field 'to', "#{env.users[0].id}@#{domain}"
				.attach 'file', 'test/data/test.png'
				.expect (res) ->
					msgs[1] = res.body
				.expect 201
				.end done
		
		it 'audio attachement', (done) ->
			req sails.hooks.http.app
				.post '/api/msg/file'
				.set 'Authorization', "Bearer #{tokens[1]}"
				.field 'to', "#{env.users[0].id}@#{domain}"
				.attach 'file', 'test/data/test.mp3'
				.expect (res) ->
					msgs[2] = res.body
				.expect 201
				.end done
				
	describe 'read', ->
		fs = require 'fs'
		qs = require 'querystring'
		
		it "list msgs sent to #{env.users[0]}", (done) ->
			param = qs.stringify 
				to: 	"#{env.users[0].id}@#{domain}"
				type:	'chat'
			req sails.hooks.http.app
				.get "/api/msg?#{param}"
				.set 'Authorization', "Bearer #{tokens[1]}"
				.expect (res) ->
					console.log res 
				.expect 200
				.end done
		
		it "thumbnail of the image file", (done) ->
			req sails.hooks.http.app
				.get "/api/msg/file/thumb/#{msgs[1].id}"
				.set 'Authorization', "Bearer #{tokens[1]}"
				.expect 200
				.parse (res, cb) ->
					res.pipe fs.createWriteStream '/tmp/test.thumb.png'
						.on 'finish', cb
						.on 'error', cb
				.end done
				
		it "image file sent", (done) ->
			req sails.hooks.http.app
				.get "/api/msg/file/#{msgs[1].id}"
				.set 'Authorization', "Bearer #{tokens[1]}"
				.expect 200
				.parse (res, cb) ->
					res.pipe fs.createWriteStream '/tmp/test.png'
						.on 'finish', ->
							ret = exec "diff /tmp/test.png test/data/test.png"
							if ret.code != 0
								throw new Error 'file mismatch'
							cb()
						.on 'error', cb
				.end done
					
		it "audio file sent to #{env.users[0]}", (done) ->
			req sails.hooks.http.app
				.get "/api/msg/file/#{msgs[2].id}"
				.set 'Authorization', "Bearer #{tokens[1]}"
				.expect 200
				.parse (res, cb) ->
					res.pipe fs.createWriteStream '/tmp/test.mp3'
						.on 'finish', ->
							ret = exec "diff /tmp/test.mp3 test/data/test.mp3"
							if ret.code != 0
								throw new Error 'file mismatch'
							cb()
						.on 'error', cb
				.end done