uuid = require 'node-uuid'

module.exports =
  file:
    opts:
      adapter: require 'skipper-gridfs'
      uri: 'mongodb://@im_mongo:27017/im'
      bucket: 'fs'
      maxBytes: 10240000        # 10MB
      saveAs: (stream, next) ->
        # convert input wav to mp3 stream
        if stream.headers['content-type'] == 'audio/wave'
          stream = sails.services.audio.mp3(stream)
        next(null, "#{uuid.v4()}/#{stream.filename}")
    img:
      resize: '25%'
