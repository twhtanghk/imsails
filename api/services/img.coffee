im = require 'imagemagick-stream'

module.exports =
	thumb: (stream) ->
		stream.pipe(im().resize(sails.config.file.img.resize))