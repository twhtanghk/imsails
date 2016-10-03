stream = require 'stream'
im = require 'imagemagick-stream'
ffmpeg = require 'fluent-ffmpeg'
uuid = require 'node-uuid'
fs = require 'fs'
frame = require 'videoframe'

module.exports =
	img: (size = sails.config.file.img.resize) ->
		im().resize(size)

	video: (opts = {timestamps: [0], size: '320x240'})->
		frame(opts)
