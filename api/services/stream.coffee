stream = require 'stream'

class Partial extends stream.Transform
	constructor: (@first, @last) ->
		@pos = 0
		super()
		
	_transform: (chunk, opts, done) ->
		if @first > @pos + chunk.length
			@pos += chunk.length
		else
			ret = chunk.slice @first, if chunk.length > @last then @last + 1
			@pos += ret.length
			@push ret
		done()

module.exports = Partial: Partial