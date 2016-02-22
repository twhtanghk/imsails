im = require 'imagemagick-stream'

module.exports =
	thumb: (size = sails.config.file.img.resize) ->
		im().resize(size)