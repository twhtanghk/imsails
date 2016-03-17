env = require '../../env.coffee'
require 'shelljs/global'
fs = require 'fs'
path = require 'path'

describe 'message', ->
	@timeout env.timeout
	
	msg = null
				
	before (done) ->
		sails.models.msg
			.findOne file: like: '%png'
			.then (img) ->
				msg = img
				done()
			.catch done
				
	describe 'file', ->
		it 'content', (done) ->
			sails.services.file.content sails.models.msg, msg.id 
				.then (file) ->
					if file.prop.filename != msg.file
						throw 'name mismatch'
					file.stream.pipe fs.createWriteStream "/tmp/test.png"
						.on 'finish', ->
							ret = exec "diff /tmp/test.png test/data/test.png"
							if ret.code != 0
								throw new Error 'file mismatch'
							done()
						.on 'error', done
				.catch done
				
		it 'thumb', (done) ->
			sails.services.file.thumb sails.models.msg, msg.id 
				.then (file) ->
					if file.prop.filename != sails.services.file.thumbName(msg.file)
						throw 'name mismatch'
					file.stream.pipe fs.createWriteStream "/tmp/test.thumb.png"
						.on 'finish', ->
							done()
						.on 'error', done
				.catch done