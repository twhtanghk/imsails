path = require 'path'
ffmpeg = require 'fluent-ffmpeg'

module.exports =
	ogg: (wavStream) ->
		out = ffmpeg(wavStream).format('ogg')
		out.filename = "#{path.parse(wavStream.filename).name}.ogg"
		return out
		
	mp3: (wavStream) ->
		out = ffmpeg(wavStream).format('mp3')
		out.filename = "#{path.parse(wavStream.filename).name}.mp3"
		return out	