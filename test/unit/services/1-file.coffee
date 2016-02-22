env = require '../../env.coffee'
require 'shelljs/global'
fs = require 'fs'
path = require 'path'

describe 'message', ->
	@timeout env.timeout
	
	msg =
		id: '56c6d805d7e0005f8cb1ef00'
		file: 
			filename:	'5425ffd9-b170-45f8-a552-10f65fa84e76/test.png'
			length:		48650
			
	describe 'file', ->
		it 'content', (done) ->
			sails.services.file.content sails.models.msg, msg.id 
				.then (file) ->
					if file.prop.filename != msg.file.filename
						throw 'name mismatch'
					if file.prop.length != msg.file.length
						throw 'size mismatch with #{file.prop.length}'
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
					if file.prop.filename != sails.services.file.thumbName(msg.file.filename)
						throw 'name mismatch'
					file.stream.pipe fs.createWriteStream "/tmp/test.thumb.png"
						.on 'finish', ->
							done()
						.on 'error', done
				.catch done